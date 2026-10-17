#!/bin/sh
# tmux-agent-sidebar 関連: ウィンドウをリポジトリ名のアルファベット順に並べ替え、サイドバーの見出し順に合わせる。
# 鍵は git の共通ディレクトリの親（worktree でも親リポジトリ名）、git 管理外ならディレクトリ名。
# 同じ鍵のウィンドウは元の番号順を保つ（安定ソート）ので、サイドバーのグループ内の順とも一致する。
# tmux.conf の after-new-window hook から呼ばれる。
active=$(tmux display -p '#{window_id}')
tmux list-windows -F '#{window_id} #{pane_current_path}' | while read -r id path; do
    common=$(git -C "$path" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if [ -n "$common" ]; then key=$(basename "$(dirname "$common")"); else key=$(basename "$path"); fi
    printf '%s\t%s\n' "$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')" "$id"
done | sort -s -k1,1 | cut -f2 | awk '{ print NR, $1 }' | while read -r n id; do
    [ "$(tmux display -p -t ":$n" '#{window_id}')" = "$id" ] || tmux swap-window -d -s "$id" -t ":$n"
done
# swap-window は番号側にフォーカスを残すので、元のウィンドウがずれた時だけ選び直す
# （不要な select-window は after-select-window hook を起こすので避ける）
[ "$(tmux display -p '#{window_id}')" = "$active" ] || tmux select-window -t "$active"
