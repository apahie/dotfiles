# 最近の Claude Code セッションを fzf で選んで再開する
#
# 使い方:
#   claude-resume          # 一覧から選択 → 該当 cwd へ cd して --resume
#   claude-resume -m       # Tab で複数選択 → 最初の 1 件は現在のウィンドウ、
#                            残りは新規 tmux ウィンドウで一括再開
#                            (PC 再起動後に前日のセッション群をまとめて開き直す用途)
#   claude-resume <args>   # 追加引数はそのまま claude に渡る (例: --model opus)
#
# 表示:
#   一覧は 日時 / プロジェクト名 / 最初のプロンプト の 3 列。
#   preview に cwd・ブランチと、最初 / 直近のプロンプトを出す。
#   プロジェクト名は worktree を親ディレクトリに畳んでから .git を上へ探して決め、
#   git 管理外のディレクトリでは cwd の名前をそのまま使う。
#
# 仕組み:
#   ~/.claude/projects/*/*.jsonl を mtime 降順で拾い、各ファイルから
#   cwd / gitBranch / sessionId と最初のプロンプトを抽出する。
#   削除済み worktree (cwd が消えたもの) は自動で除外する。
#   session-report などプラグインが prompt を queue 投入したセッション
#   ("type":"queue-operation" で始まるもの) も除外する。
#   表示は 50 件までなので、そろった時点で走査を打ち切る。
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

    # transcript から「自分が入力したプロンプト」だけを取り出す jq プログラム。
    # ツール結果・システム挿入・/clear などのコマンド行は落とす。
    # 巨大なメッセージに gsub を当てると遅いので、先に .[0:2000] で切る。
    # preview は sh から実行されるため、環境変数として渡して一覧と共用する。
    set -lx claude_resume_jq '
        select(.type == "user" and (.isMeta != true) and (.isSidechain != true))
        | ((.message.content // "")
           | if type == "string" then .
             else (map(select(.type == "text") | .text // "") | join(" ")) end)
        | select(contains("<system-reminder>") or contains("<local-command-stdout>")
                 or contains("idle_notification") or startswith("[Request interrupted")
                 or startswith("Caveat:") | not)
        | .[0:2000]
        | select(test("<command-name>/(clear|resume|compact|exit|cost|status|model)") | not)
        | gsub("<command-message>[^<]*</command-message>"; "")
        | gsub("<[^>]*>"; " ")
        | gsub("[[:space:]]+"; " ")
        | ltrimstr(" ") | rtrimstr(" ")
        | select(length > 0)
        | .[0:400]
    '

    # mtime\t日時\tパス を新しい順に取得する。
    # レポート / 消滅 cwd のフィルタで多くが落ちるため多めに拾う。
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

        # worktree は親プロジェクトに畳み、git 管理下ならリポジトリ名を採る。
        # 見つからなければ cwd のディレクトリ名のまま。
        set -l project (path basename $cwd)
        set -l dir (string replace -r '/\.claude/worktrees/[^/]+$' '' -- $cwd)
        while test "$dir" != /; and test "$dir" != "$HOME"
            if test -e "$dir/.git"
                set project (path basename $dir)
                break
            end
            set dir (path dirname $dir)
        end

        set -l prompt (head -n 60 $file | jq -rc "$claude_resume_jq" 2>/dev/null | head -1)

        set -a rows (printf '%s\t%-24.24s\t%s\t%s\t%s\t%s' \
            $ago $project "$prompt" $cwd $branch $file)

        # 表示するぶんがそろったら走査を打ち切る
        if test (count $rows) -ge 50
            break
        end
    end

    if test (count $rows) -eq 0
        echo "復元可能なセッション (cwd 現存) がありません" >&2
        return 1
    end

    # {3} 最初のプロンプト / {4} cwd / {5} ブランチ / {6} transcript のパス。
    # --with-nth で列を隠しても {n} は元の行を指すので、隠し列を preview で使える。
    # 直近のプロンプトは tac で末尾から遡る。head -1 でパイプが閉じるため、
    # 大きい transcript でも見つかった時点で読むのをやめる。
    set -l preview '
        printf "cwd    : %s\n" {4}
        printf "branch : %s\n" {5}
        printf "\n--- 最初 ---\n%s\n" {3}
        printf "\n--- 直近 ---\n"
        tac {6} | jq -rc "$claude_resume_jq" 2>/dev/null | head -1
    '

    set -l fzf_opts --reverse --height 70% --prompt 'resume> ' \
        --delimiter \t --with-nth 1,2,3 \
        --preview-window 'right,50%,wrap' --preview $preview
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
            set -l sid (path basename $fields[6] | string replace '.jsonl' '')
            set -l win (tmux new-window -d -P -c $fields[4])
            tmux send-keys -t $win "claude --resume $sid $argv" Enter
            echo "→ $fields[4]  (session: "(string sub -l 8 -- $sid)") を $win で再開"
        end
        set picked $picked[1]
    end

    set -l fields (string split \t -- $picked)
    set -l cwd $fields[4]
    set -l sid (path basename $fields[6] | string replace '.jsonl' '')

    echo "→ $cwd  (session: "(string sub -l 8 -- $sid)")"
    cd $cwd; or return 1
    claude --resume $sid $argv
end
