#!/bin/bash
# SessionEnd フックから呼ばれ、Claude Code セッションの要約を
# 日次ノート vault に自動追記する。
#
# stdin: SessionEnd フックの JSON ペイロード
#   { "session_id": "...", "transcript_path": "...", "cwd": "...", "reason": "..." }
#
# 出力先: ~/workspace/${VAULT_NAME:-my-vault}/daily/YYYY/MM/DD/YYYY-MM-DD.md
# ログ:   ~/.claude/logs/auto-report.log
#
# 環境変数:
# - VAULT_NAME: 出力先 vault のディレクトリ名（デフォルト: my-vault）
#   overlay 側で上書きする想定（例: VAULT_NAME=work-vault）
#
# 設計方針:
# - フックは常に exit 0 で終わる（セッション終了をブロックしない）
# - エラーは LOG に書いて静かに終わる
# - 自動生成は [自動] マーカーを付けて手動 /report と区別する

set -u

LOG="$HOME/.claude/logs/auto-report.log"
mkdir -p "$(dirname "$LOG")"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

log "=== fired ==="

# --- 1. stdin から transcript_path を取得 -----------------------------------
INPUT=$(cat)
log "stdin: $(echo "$INPUT" | head -c 200)"
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"' 2>/dev/null)

if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
  log "transcript not found: '$TRANSCRIPT' (reason=$REASON)"
  exit 0
fi

# --- 2. 短すぎるセッションはスキップ ----------------------------------------
# 50行未満は実質的な作業をしていない可能性が高い（疎通テスト・誤起動など）。
# メタ要約ループ（auto-report自身を呼ぶテストセッションが要約される）も防ぐ。
LINES=$(wc -l < "$TRANSCRIPT")
if (( LINES < 50 )); then
  log "session too short ($LINES lines), skipping (reason=$REASON)"
  exit 0
fi

# --- 3. 出力先の準備 ---------------------------------------------------------
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
VAULT_NAME="${VAULT_NAME:-my-vault}"
VAULT_DIR="$HOME/workspace/$VAULT_NAME/daily/$(date +%Y/%m/%d)"
NOTE="$VAULT_DIR/$DATE.md"
mkdir -p "$VAULT_DIR"

if [[ ! -f "$NOTE" ]]; then
  cat > "$NOTE" <<EOF
# $DATE

## やったこと

## メモ・気づき

## リンク

EOF
  log "created new note: $NOTE"
fi

# --- 4. claude -p で要約生成（バックグラウンド実行）-------------------------
# SessionEnd フックは ~60秒で kill されるので、長時間かかる claude -p は
# detach して fire-and-forget で実行する。結果はノートに直接追記される。
#
# ★ プロンプトを編集して要約の質を調整できます
PROMPT='以下は Claude Code セッションの transcript (JSONL) です。
日次ノートに記録する要約を、日本語の箇条書き 3〜7 点で作成してください。

方針:
- 何を**決めたか**・何を**作ったか**・何を**学んだか** を中心に
- 技術的詳細は最小限（コミット履歴や diff で分かることは書かない）
- 未来の自分が「あの日何やったっけ」と1秒で思い出せる粒度
- 関連ノートがあれば [[ファイル名]] でリンク

出力形式:
- "- " で始まる箇条書きのみ
- ヘッダー（## ...）や前置きは含めない
'

# 長すぎるtranscriptは "Prompt is too long" で失敗するので、
# 末尾の最大N行に絞る（最近のやり取りほど要約に効く）。
MAX_LINES=200
TRUNCATED_TRANSCRIPT=$(mktemp)
tail -n "$MAX_LINES" "$TRANSCRIPT" > "$TRUNCATED_TRANSCRIPT"

log "spawning background summarizer (transcript_lines=$LINES, using_last=$MAX_LINES)"

nohup bash -c "
  SUMMARY=\$(claude -p \"\$0\" < \"\$1\" 2>>\"\$2\")
  rm -f \"\$1\"  # truncated tempfile cleanup
  if [[ -z \"\$SUMMARY\" ]]; then
    echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] background: summary empty/failed\" >> \"\$2\"
    exit 0
  fi
  {
    echo ''
    echo '---'
    echo ''
    echo \"## Claude Code セッション（\$3）[自動]\"
    echo ''
    echo \"\$SUMMARY\"
  } >> \"\$4\"
  echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] background: appended to \$4\" >> \"\$2\"
" "$PROMPT" "$TRUNCATED_TRANSCRIPT" "$LOG" "$TIME" "$NOTE" </dev/null >/dev/null 2>&1 &
disown

log "hook returning immediately, summarizer PID=$!"
exit 0
