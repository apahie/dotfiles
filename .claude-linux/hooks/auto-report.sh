#!/bin/bash
# Claude Code セッションの要約を、vault のセッションごとのノートに記録する。
#
# 呼ばれ方:
# - SessionEnd フックから引数なしで呼ばれる。stdin は SessionEnd フックの JSON ペイロード
#     { "session_id": "...", "transcript_path": "...", "cwd": "...", "reason": "..." }
#   前回の要約から増えた transcript を claude -p で要約し、ノートに [自動] の節として追記する
# - auto-report.sh --note <セッション ID>
#   手動の /report スキルから呼ばれ、そのセッションのノートのパスと transcript の行数を出力する
# - auto-report.sh --worker ...
#   フック自身がバックグラウンドで起動し直す内部用のモード（要約の生成、書き込み、コミット）
#
# ノート: ~/workspace/${VAULT_NAME:-my-vault}/daily/YYYY/MM/DD/sessions/HHMM-<題>.md
# - 日付と時刻はセッションの開始時刻。題は Claude Code が付けるセッションの要約で、無ければリポジトリ名
# - 同じセッションのノートは frontmatter の session_id で探す。--resume で再開したセッションは
#   同じ ID と transcript を引き継ぐので、同じノートに追記される
# - frontmatter の reported_lines に要約済みの transcript の行数を残し、次回は増えた分だけを要約する
#
# ログ: ~/.claude/logs/auto-report.log
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

VAULT_NAME="${VAULT_NAME:-my-vault}"
VAULT_ROOT="$HOME/workspace/$VAULT_NAME"

# 増えた分が 50 行未満なら要約しない。実質的な作業をしていない可能性が高い（疎通テスト・誤起動など）。
# メタ要約ループ（auto-report 自身の claude -p が要約される）も防ぐ。
MIN_LINES=50
# 長すぎる transcript は "Prompt is too long" で失敗するので、
# 増えた分の末尾の最大 N 行に絞る（最近のやり取りほど要約に効く）。
MAX_LINES=200

# ★ プロンプトを編集して要約の質を調整できます
PROMPT='以下は Claude Code セッションの transcript (JSONL) です。
セッションのノートに記録する要約を、日本語の箇条書き 3〜7 点で作成してください。

方針:
- 何を**決めたか**・何を**作ったか**・何を**学んだか** を中心に
- 技術的詳細は最小限（コミット履歴や diff で分かることは書かない）
- 未来の自分が「あの日何やったっけ」と1秒で思い出せる粒度
- 関連ノートがあれば [[ファイル名]] でリンク

出力形式:
- "- " で始まる箇条書きのみ
- ヘッダー（## ...）や前置きは含めない
'

# ファイル名に使えるよう、スペースと、ファイル名や Obsidian のリンクで問題になる記号を - にし、40 文字で切る
slugify() {
  printf '%s' "$1" | LC_ALL=C.UTF-8 sed -E 's,[][[:space:]/\\:*?"<>|#^]+,-,g; s,^-+,,; s,^(.{40}).*,\1,; s,-+$,,'
}

# セッションのノートを決め、NOTE（パス）、PREV（要約済みの行数）、REPO、TITLE（新規のときだけ）に入れる
# $1: セッション ID  $2: transcript のパス  $3: セッションの作業ディレクトリ
resolve_note() {
  local sid=$1 transcript=$2 cwd=$3 repo_dir start epoch slug
  # worktree の中でも親リポジトリ名にする
  repo_dir=${cwd%%/.claude/worktrees/*}
  REPO=$(basename "$(git -C "$repo_dir" rev-parse --show-toplevel 2>/dev/null || echo "$repo_dir")")
  REPO=${REPO:-unknown}
  PREV=0
  TITLE=""
  NOTE=$(grep -rlF --include='*.md' "session_id: $sid" "$VAULT_ROOT/daily" 2>/dev/null | head -n 1)
  if [[ -n $NOTE ]]; then
    PREV=$(sed -n 's/^reported_lines: //p' "$NOTE" | head -n 1)
    [[ $PREV =~ ^[0-9]+$ ]] || PREV=0
    return 0
  fi
  # 新しいノート。開始時刻は transcript の最初の timestamp（UTC）をローカル時刻に直したもの
  start=$(grep -m1 -o '"timestamp":"[^"]*"' "$transcript" | cut -d'"' -f4)
  epoch=$(date -d "${start:-now}" +%s 2>/dev/null || date +%s)
  TITLE=$(tac "$transcript" | grep -m1 '"type":"ai-title"' | jq -r '.aiTitle // empty' 2>/dev/null)
  TITLE=${TITLE:-$REPO}
  slug=$(slugify "$TITLE")
  NOTE="$VAULT_ROOT/daily/$(date -d "@$epoch" +%Y/%m/%d)/sessions/$(date -d "@$epoch" +%H%M)-${slug:-$REPO}.md"
  # 同じ時刻・同じ題の別セッションのノートがあれば、セッション ID の先頭を付けて分ける
  if [[ -e $NOTE ]]; then
    NOTE="${NOTE%.md}-${sid:0:8}.md"
  fi
}

# バックグラウンドで要約を作り、ノートに追記してコミットする
# $1: 要約する部分の一時ファイル  $2: ノート  $3: セッション ID  $4: リポジトリ名  $5: 題
# $6: 要約済みとして記録する行数  $7: 節の見出しにする日時
worker() {
  local part=$1 note=$2 sid=$3 repo=$4 title=$5 lines=$6 stamp=$7 summary
  summary=$(claude -p "$PROMPT" < "$part" 2>>"$LOG")
  rm -f "$part"
  if [[ -z $summary ]]; then
    log "background: summary empty/failed"
    return 0
  fi

  if [[ -f $note ]]; then
    # 要約済みの行数を進める（frontmatter の最初の reported_lines だけを書き換える）
    sed -i "0,/^reported_lines: /s/^reported_lines: .*/reported_lines: $lines/" "$note"
  else
    mkdir -p "$(dirname "$note")"
    printf -- '---\nsession_id: %s\nrepo: %s\nreported_lines: %s\n---\n\n# %s\n' \
      "$sid" "$repo" "$lines" "$title" > "$note"
  fi
  printf '\n## %s [自動]\n\n%s\n' "$stamp" "$summary" >> "$note"
  log "background: wrote $note"

  # vault が git リポジトリなら、書いたノートをコミットして push する。
  # 失敗してもセッションには影響しないので、結果はログに残すだけにする。
  if git -C "$VAULT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$VAULT_ROOT" add "$note"
    if git -C "$VAULT_ROOT" commit -q -m 'daily: Claude Code セッション要約を自動記録 [自動]'; then
      # push 失敗が続くとローカルにコミットが溜まり分岐が育つため、push 前に
      # リモートの先行コミットを取り込む。競合したら abort して手動解消に委ねる
      # （push は失敗としてログに残る）。
      if ! git -C "$VAULT_ROOT" pull -q --rebase --autostash >>"$LOG" 2>&1; then
        git -C "$VAULT_ROOT" rebase --abort >>"$LOG" 2>&1
        log "background: pull --rebase failed, aborted $note"
      fi
      if git -C "$VAULT_ROOT" push -q >>"$LOG" 2>&1; then
        log "background: committed & pushed $note"
      else
        log "background: committed but push failed $note"
      fi
    else
      log "background: nothing to commit $note"
    fi
  fi
}

case ${1:-} in
  --worker)
    shift
    worker "$@"
    exit 0
    ;;
  --note)
    # 手動の /report 用。カレントディレクトリをセッションの作業ディレクトリとして扱う
    sid=${2:-}
    transcript=$(ls "$HOME"/.claude/projects/*/"$sid".jsonl 2>/dev/null | head -n 1)
    if [[ -z $sid || -z $transcript ]]; then
      echo "error: セッション '$sid' の transcript が見つかりません"
      exit 0
    fi
    resolve_note "$sid" "$transcript" "$PWD"
    if [[ -f $NOTE ]]; then state=既存; else state=新規; fi
    echo "note: $NOTE ($state)"
    echo "repo: $REPO"
    if [[ -n $TITLE ]]; then echo "title: $TITLE"; fi
    echo "transcript_lines: $(wc -l < "$transcript")"
    exit 0
    ;;
esac

log "=== fired ==="

# --- 1. stdin からセッションの情報を取得 ------------------------------------
INPUT=$(cat)
log "stdin: $(echo "$INPUT" | head -c 200)"
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
SID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"' 2>/dev/null)

if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" || -z "$SID" ]]; then
  log "transcript not found: '$TRANSCRIPT' (session=$SID, reason=$REASON)"
  exit 0
fi

# --- 2. ノートを決め、前回から増えた分が短ければスキップ -------------------
LINES=$(wc -l < "$TRANSCRIPT")
resolve_note "$SID" "$TRANSCRIPT" "$CWD"
NEW=$(( LINES - PREV ))
if (( NEW < MIN_LINES )); then
  log "session too short ($NEW new of $LINES lines), skipping (reason=$REASON)"
  exit 0
fi

# --- 3. claude -p で要約生成（バックグラウンド実行）-------------------------
# SessionEnd フックは ~60秒で kill されるので、長時間かかる claude -p は
# このスクリプトを --worker で起動し直して detach し、fire-and-forget で実行する。
PART=$(mktemp)
tail -n "$(( NEW < MAX_LINES ? NEW : MAX_LINES ))" "$TRANSCRIPT" > "$PART"

log "spawning background summarizer (note=$NOTE, new_lines=$NEW of $LINES, using_last=$MAX_LINES)"

nohup bash "$0" --worker "$PART" "$NOTE" "$SID" "$REPO" "$TITLE" "$LINES" "$(date '+%Y-%m-%d %H:%M')" \
  </dev/null >/dev/null 2>&1 &
disown

log "hook returning immediately, summarizer PID=$!"
exit 0
