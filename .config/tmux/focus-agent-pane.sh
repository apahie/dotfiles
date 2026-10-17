#!/bin/sh
# tmux-agent-sidebar 関連: ウィンドウを移ったあと、サイドバー以外の最初のペインにフォーカスを置く。
# prefix+数字 で移動しても、サイドバーの Enter で飛んだ時と同じくエージェント側に着地させる。
# tmux.conf の after-select-window hook から、移動先のウィンドウ ID を引数に呼ばれる。
# 着地したペインがサイドバーの時だけ動かす。それ以外は tmux が覚えている最後のペインとズーム状態を尊重する
[ "$(tmux display -p -t "$1" '#{@pane_role}')" = sidebar ] || exit 0
pane=$(tmux list-panes -t "$1" -f '#{!=:#{@pane_role},sidebar}' -F '#{pane_id}' | head -n 1)
[ -n "$pane" ] && tmux select-pane -t "$pane"
exit 0
