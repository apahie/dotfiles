# 最近の Claude Code セッションを fzf で選んで再開する
#
# 使い方:
#   claude-resume          # 一覧から選択 → 該当 cwd へ cd して --resume
#   claude-resume -m       # Tab で複数選択 → 最初の 1 件は現在のウィンドウ、
#                            残りは新規 tmux ウィンドウで一括再開
#                            (PC 再起動後に前日のセッション群をまとめて開き直す用途)
#   claude-resume <args>   # 追加引数はそのまま claude に渡る (例: --model opus)
#
# 仕組み:
#   ~/.claude/projects/*/*.jsonl を mtime 降順で拾い、各ファイルから
#   cwd / gitBranch / sessionId を抽出。レポート / 消滅 cwd を除外した後の
#   最新 50 件を fzf に渡し、選んだセッションへ cd → claude --resume <sid>。
#   削除済み worktree (cwd が消えたもの) は自動で除外する。
#   session-report などプラグインが prompt を queue 投入したセッション
#   ("type":"queue-operation" で始まるもの) も除外する。
#   mtime = JSONL 最終 record の timestamp ＝ 最後に触った時刻。

function claude-resume --description '最近の Claude Code セッションを fzf で選んで再開'
    # -m 以外のオプションは claude への渡し引数として argv に残す
    argparse --ignore-unknown m/multi -- $argv
    or return

    if set -q _flag_multi; and not set -q TMUX
        echo "-m (一括再開) は tmux 内でのみ使えます" >&2
        return 1
    end

    set -l projects "$HOME/.claude/projects"
    if not test -d "$projects"
        echo "Claude Code のセッションがまだありません" >&2
        return 1
    end

    # mtime\t日時\tパス を新しい順に取得する。
    # レポート / 消滅 cwd のフィルタで多くが落ちるため多めに拾い、
    # 表示件数の cap はフィルタを通した後にかける。
    set -l recent (
        find "$projects" -maxdepth 2 -name '*.jsonl' -type f \
            -printf '%T@\t%TY-%Tm-%Td %TH:%TM\t%p\n' 2>/dev/null \
        | sort -rn | head -400
    )
    if test (count $recent) -eq 0
        echo "セッションがありません" >&2
        return 1
    end

    set -l rows
    for line in $recent
        set -l parts (string split \t -- $line)
        set -l ago $parts[2]
        set -l file $parts[3]

        # session-report 等プラグインが prompt を queue 投入したセッションは除外
        if head -3 $file | grep -q '"type":"queue-operation"'
            continue
        end

        set -l cwd (grep -m1 -o '"cwd":"[^"]*"' $file \
            | string replace -r '"cwd":"(.*)"' '$1')
        test -n "$cwd"; or continue
        test -d "$cwd"; or continue   # 削除済み worktree は除外

        set -l branch (grep -m1 -o '"gitBranch":"[^"]*"' $file \
            | string replace -r '"gitBranch":"(.*)"' '$1')
        test -z "$branch"; and set branch '-'

        set -l sid (path basename $file | string replace '.jsonl' '')

        set -a rows (printf '%s\t%s\t%s\t%s' $ago $cwd $branch $sid)
    end

    # フィルタを通過した実セッションのうち、最新 50 件だけを表示する。
    if test (count $rows) -gt 50
        set rows $rows[1..50]
    end

    if test (count $rows) -eq 0
        echo "復元可能なセッション (cwd 現存) がありません" >&2
        return 1
    end

    set -l fzf_opts --reverse --height 50% --prompt 'resume> ' --delimiter \t --with-nth 1,2,3
    if set -q _flag_multi
        # --prompt は後勝ちで上書きされる
        set -a fzf_opts --multi --prompt 'resume (Tab で複数選択)> '
    end
    set -l picked (printf '%s\n' $rows | fzf $fzf_opts)
    test -n "$picked"; or return 0

    # -m 指定時は 2 件目以降をバックグラウンドの新規ウィンドウで再開し、
    # 最初の 1 件は下の単一選択処理に流して現在のウィンドウで開く
    if set -q _flag_multi
        # 一覧の下 (古い方) から開く。Tab の選択順に依存しないよう日時列の昇順に揃える
        set picked (printf '%s\n' $picked | sort)
        for line in $picked[2..]
            set -l fields (string split \t -- $line)
            set -l win (tmux new-window -d -P -c $fields[2])
            tmux send-keys -t $win "claude --resume $fields[4] $argv" Enter
            echo "→ $fields[2]  (session: "(string sub -l 8 -- $fields[4])") を $win で再開"
        end
        set picked $picked[1]
    end

    set -l fields (string split \t -- $picked)
    set -l cwd $fields[2]
    set -l sid $fields[4]

    echo "→ $cwd  (session: "(string sub -l 8 -- $sid)")"
    cd $cwd; or return 1
    claude --resume $sid $argv
end
