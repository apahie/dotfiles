#!/bin/sh
# tmux-agent-sidebar 関連: ウィンドウを移ったあと、サイドバー以外の最初のペインにフォーカスを置く。
# prefix+数字 で移動しても、サイドバーの Enter で飛んだ時と同じくエージェント側に着地させる。
# tmux.conf の after-select-window hook から、移動先のウィンドウ ID を引数に呼ばれる。
pane=$(tmux list-panes -t "$1" -f '#{!=:#{@pane_role},sidebar}' -F '#{pane_id}' | head -n 1)
[ -n "$pane" ] && tmux select-pane -t "$pane"
exit 0
