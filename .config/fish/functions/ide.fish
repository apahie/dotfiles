function ide --description '左で claude、右で nvim を起動 (-w/--worktree で worktree 内に隔離)'
    if not set -q TMUX
        echo "tmux内で実行してください"
        return 1
    end

    argparse 'w/worktree' -- $argv
    or return 1

    set -l work_dir $PWD
    set -l wt_name ""

    if set -q _flag_worktree
        set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
        if test -z "$repo_root"
            echo "--worktree は git リポジトリ内で実行してください"
            return 1
        end

        set wt_name "ide-"(date +%Y%m%d-%H%M%S)
        set work_dir "$repo_root/.worktrees/$wt_name"

        git worktree add -b $wt_name $work_dir
        or return 1
    end

    # 右ペインで nvim を作業ディレクトリで起動、ペインID を保存
    set -l right (tmux split-window -h -d -P -F '#{pane_id}' -c $work_dir 'nvim .')
    # 現在ペイン(左)で claude を作業ディレクトリで起動 (ブロッキング)
    pushd $work_dir
    claude
    popd
    # claude が exit したら右ペインも閉じる
    tmux kill-pane -t $right 2>/dev/null

    # worktree モードなら削除を試行 (未コミットがあれば残す)
    if test -n "$wt_name"
        if git worktree remove $work_dir 2>/dev/null
            echo "worktree を削除しました: $wt_name"
        else
            echo "worktree に未コミット変更があるため残しました: $work_dir"
        end
    end
end
