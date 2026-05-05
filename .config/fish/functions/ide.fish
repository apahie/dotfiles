function ide --description '開発環境起動 (-w/--worktree[=<name>] で worktree 隔離)'
    if not set -q TMUX
        echo "tmux内で実行してください"
        return 1
    end

    argparse 'w/worktree=?' -- $argv
    or return 1

    set -l work_dir $PWD

    if set -q _flag_worktree
        set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
        if test -z "$repo_root"
            echo "--worktree は git リポジトリ内で実行してください"
            return 1
        end

        # 値指定があればそれを worktree 名にし、なければ ide-DATE
        set -l wt_name $_flag_worktree
        if test -z "$wt_name"
            set wt_name "ide-"(date +%Y%m%d-%H%M%S)
        end
        set work_dir "$repo_root/.worktrees/$wt_name"

        git worktree add -b $wt_name $work_dir
        or return 1
    end

    # 下 pane: terminal (window を上下分割、下 25%)
    set -l term_pane (tmux split-window -v -d -p 25 -P -F '#{pane_id}' -c $work_dir)
    tmux select-pane -t $term_pane -T terminal

    # 上 pane の右側: nvim (左右 50/50)
    set -l nvim_pane (tmux split-window -h -d -P -F '#{pane_id}' -c $work_dir 'nvim .')
    tmux select-pane -t $nvim_pane -T nvim

    # 左 pane (現 pane): claude
    # 注意: fish は関数内フォアグラウンドコマンドが SIGTSTP で停止しても
    #       関数を suspend せず次行に進む。よって claude の直後に
    #       破壊的処理 (kill-pane, worktree remove) を書いてはいけない。
    tmux select-pane -T claude
    pushd $work_dir
    claude
    popd
end
