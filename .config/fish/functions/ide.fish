function ide --description '左で claude、右で nvim を起動 (claude 終了時に nvim も自動 close)'
    if not set -q TMUX
        echo "tmux内で実行してください"
        return 1
    end
    # 右ペインを作って nvim 起動、ペインID を保存
    set -l right (tmux split-window -h -d -P -F '#{pane_id}' -c $PWD 'nvim .')
    # 現在ペイン(左)で claude を起動 (ブロッキング)
    claude
    # claude が exit したら右ペインも閉じる
    tmux kill-pane -t $right 2>/dev/null
end
