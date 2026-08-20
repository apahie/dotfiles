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
#   ブランチは cwd から git に直接聞く。transcript の gitBranch は worktree の中でも
#   共有チェックアウト側のブランチが記録されるため使わない。
#   プロジェクト名末尾の * は worktree が削除済みの (再作成して再開する) セッション。
#
# 仕組み:
#   ~/.claude/projects/*/*.jsonl を mtime 降順で拾い、各ファイルから
#   cwd / sessionId と最初のプロンプトを抽出する。
#   session-report などプラグインが prompt を queue 投入したセッション
#   ("type":"queue-operation" で始まるもの) は除外する。
#   削除済み worktree のセッションも一覧に残す。--resume は cwd に依存せず
#   セッションを解決するため、親リポで claude -w を付けて再開すればよい。
#   worktree の作成は claude -w に任せる。手で git worktree add すると Claude Code
#   管理外 (lock なし) の worktree になるため、元の名前を -w に渡すだけにする。
#   -w は worktree-<名> を親リポの HEAD から作るので、当時の作業内容までは戻らない。
#   worktree の削除でブランチも消えるため実害は出ないが、同名ブランチが残っていた
#   場合は -w がそれを HEAD へ reset してしまうので、名前をずらして避ける。
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
    # 走査は 50 行そろった時点で打ち切るので、ここで件数は絞らない。
    set -l recent (
        find "$projects" -maxdepth 2 -name '*.jsonl' -type f \
            -printf '%T@\t%TY-%Tm-%Td %TH:%TM\t%p\n' 2>/dev/null \
        | sort -rn
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

        # session-report 等プラグインが prompt を queue 投入したセッションは除外。
        # 判定は 1 行目だけにする。claude -w で始めたセッションは worktree-state の
        # 次に enqueue が来るため、head -3 で見ると worktree セッションまで落ちる。
        if head -1 $file | grep -q '"type":"queue-operation"'
            continue
        end

        set -l cwd (grep -m1 -o '"cwd":"[^"]*"' $file \
            | string replace -r '"cwd":"(.*)"' '$1')
        test -n "$cwd"; or continue

        # worktree は親プロジェクトに畳み、git 管理下ならリポジトリ名を採る。
        # 見つからなければ cwd のディレクトリ名のまま。
        set -l project (path basename $cwd)
        set -l repo
        set -l dir (string replace -r '/\.claude/worktrees/[^/]+$' '' -- $cwd)
        while test "$dir" != /; and test "$dir" != "$HOME"
            if test -e "$dir/.git"
                set project (path basename $dir)
                set repo $dir
                break
            end
            set dir (path dirname $dir)
        end

        # cwd が消えていても、それが親リポ直下の worktree なら再作成して再開できる。
        # それ以外 (リポジトリごと消えた等) は復元手段がないので落とす。
        set -l state live
        if not test -d "$cwd"
            test "$repo" = (string replace -r '/\.claude/worktrees/[^/]+$' '' -- $cwd)
            or continue
            set state gone
            set project "$project*"
        end

        set -l prompt (head -n 60 $file | jq -rc "$claude_resume_jq" 2>/dev/null | head -1)

        set -a rows (printf '%s\t%-24.24s\t%s\t%s\t%s\t%s' \
            $ago "$project" "$prompt" $cwd $file $state)

        # 表示するぶんがそろったら走査を打ち切る
        if test (count $rows) -ge 50
            break
        end
    end

    if test (count $rows) -eq 0
        echo "再開できるセッションがありません" >&2
        return 1
    end

    # {3} 最初のプロンプト / {4} cwd / {5} transcript のパス。
    # --with-nth で列を隠しても {n} は元の行を指すので、隠し列を preview で使える。
    # ブランチは transcript の gitBranch を使わない。worktree の中で動いていても
    # 共有チェックアウト側のブランチが記録されるため、cwd から git に直接聞く。
    # 直近のプロンプトは tac で末尾から遡る。head -1 でパイプが閉じるため、
    # 大きい transcript でも見つかった時点で読むのをやめる。
    set -l preview '
        printf "cwd    : %s\n" {4}
        if [ -d {4} ]; then
            branch=$(git -C {4} branch --show-current 2>/dev/null)
            if [ -z "$branch" ]; then
                head=$(git -C {4} rev-parse --short HEAD 2>/dev/null)
                if [ -n "$head" ]; then branch="(detached $head)"; else branch="-"; fi
            fi
            printf "branch : %s\n" "$branch"
        else
            printf "branch : worktree 削除済み → claude -w %s で作り直して再開\n" "$(basename {4})"
        fi
        printf "\n--- 最初 ---\n%s\n" {3}
        printf "\n--- 直近 ---\n"
        tac {5} | jq -rc "$claude_resume_jq" 2>/dev/null | head -1
    '

    # preview は既定で $SHELL に渡される。fish に渡すと sh 構文が通らないうえ
    # config.fish の読み込みで毎回 2 秒以上待たされるため、sh を明示する。
    set -l fzf_opts --reverse --height 70% --prompt 'resume> ' \
        --delimiter \t --with-nth 1,2,3 --with-shell 'sh -c' \
        --preview-window 'right,50%,wrap' --preview $preview
    if set -q _flag_multi
        # --prompt は後勝ちで上書きされる
        set -a fzf_opts --multi --prompt 'resume (Tab で複数選択)> '
    end
    set -l picked (printf '%s\n' $rows | fzf $fzf_opts)
    test -n "$picked"; or return 0

    # 選んだ行を 日時 / 起動ディレクトリ / transcript / claude への追加引数 に畳む。
    # worktree が生きている行はそのディレクトリで、削除済みの行は親リポで claude -w
    # を付けて再開する。worktree を作るのは claude 側で、こちらは git を触らない。
    set -l targets
    for line in $picked
        set -l fields (string split \t -- $line)
        set -l dir $fields[4]
        set -l extra
        if test "$fields[6]" = gone
            set dir (string replace -r '/\.claude/worktrees/[^/]+$' '' -- $fields[4])
            # -w は同名ブランチを HEAD へ reset するので、残っている名前は避ける
            set -l name (path basename $fields[4])
            while git -C $dir rev-parse --verify --quiet refs/heads/worktree-$name >/dev/null
                set name $name-resume
            end
            set extra "-w $name"
        end
        set -a targets (printf '%s\t%s\t%s\t%s' $fields[1] $dir $fields[5] "$extra")
    end

    # -m 指定時は 2 件目以降をバックグラウンドの新規ウィンドウで再開し、
    # 最初の 1 件は下の単一選択処理に流して現在のウィンドウで開く
    if set -q _flag_multi
        # 一覧の下 (古い方) から開く。Tab の選択順に依存しないよう日時列の昇順に揃える
        set targets (printf '%s\n' $targets | sort)
        for line in $targets[2..]
            set -l fields (string split \t -- $line)
            set -l sid (path basename $fields[3] | string replace '.jsonl' '')
            set -l extra (string split -n ' ' -- $fields[4])
            set -l win (tmux new-window -d -P -c $fields[2])
            tmux send-keys -t $win "claude --resume $sid $extra $argv" Enter
            echo "→ $fields[2] $extra (session: "(string sub -l 8 -- $sid)") を $win で再開"
        end
        set targets $targets[1]
    end

    set -l fields (string split \t -- $targets)
    set -l dir $fields[2]
    set -l sid (path basename $fields[3] | string replace '.jsonl' '')
    set -l extra (string split -n ' ' -- $fields[4])

    echo "→ $dir $extra (session: "(string sub -l 8 -- $sid)")"
    cd $dir; or return 1
    claude --resume $sid $extra $argv
end
