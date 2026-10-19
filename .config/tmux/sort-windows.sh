#!/bin/sh
# tmux-agent-sidebar 関連: ウィンドウをリポジトリ名のアルファベット順に並べ替え、サイドバーの見出し順に合わせる。
# 鍵は git の共通ディレクトリの親（worktree でも親リポジトリ名）、git 管理外ならディレクトリ名。
# 同じ鍵のウィンドウは元の番号順を保つ（安定ソート）ので、サイドバーのグループ内の順とも一致する。
# tmux.conf の after-new-window hook と Claude Code の SessionStart hook（.claude-linux/settings.json）から、
# 対象セッションの ID を引数に呼ばれる。
# hook 内では -t 無しの tmux コマンドが「最近使ったセッション」に解決されるため、常に -t で指定する。
session=$1
active=$(tmux display -p -t "$session" '#{window_id}')
# 番号に穴があると下の番号順の割り当てがずれるので、先に詰める
tmux move-window -r -t "$session"
base=$(tmux show -gv base-index)
# 鍵のパスは、各ウィンドウでサイドバー以外の最初のペインから取る（focus-agent-pane.sh と同じ絞り込み）。
# アクティブペインから取ると、サイドバーにフォーカスを残したウィンドウがサイドバーの cwd（ホーム）を鍵にしてしまう。
# サイドバーだけのウィンドウは一覧から漏れて末尾に回るが、プラグインがすぐ閉じるので扱わない
# 比較はサイドバー側（小文字化したバイト比較）と同じコードポイント順にする。鍵に空白が入っても崩れないよう区切りはタブ
tmux list-panes -s -t "$session" -f '#{!=:#{@pane_role},sidebar}' -F '#{window_id} #{pane_current_path}' | awk '!seen[$1]++' | while read -r id path; do
    common=$(git -C "$path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if [ -n "$common" ]; then key=$(basename "$(dirname "$common")"); else key=$(basename "$path"); fi
    printf '%s\t%s\n' "$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')" "$id"
done | LC_ALL=C sort -s -t "$(printf '\t')" -k1,1 | cut -f2 | awk -v b="$base" '{ print b + NR - 1, $1 }' | while read -r n id; do
    [ "$(tmux display -p -t "$session:$n" '#{window_id}')" = "$id" ] || tmux swap-window -d -s "$id" -t "$session:$n"
done
# swap-window は番号側にフォーカスを残すので、元のウィンドウがずれた時だけ選び直す
# （不要な select-window は after-select-window hook を起こすので避ける）
[ "$(tmux display -p -t "$session" '#{window_id}')" = "$active" ] || tmux select-window -t "$active"
# 見えている現在ウィンドウのサイドバーに再描画の合図（SIGUSR1）を送り、新しい順を即時反映する。
# プラグインが after-select-window hook で移動先に送っているのと同じ処理。合図が無くても 1 秒周期で再読込されるので、
# 他のウィンドウはその周期と移動時の hook に任せる。@sidebar_pid はサイドバー以外のペインでは空で、単語分割で消える
for pid in $(tmux list-panes -t "$active" -F '#{@sidebar_pid}'); do
    kill -USR1 "$pid" 2>/dev/null || true
done
