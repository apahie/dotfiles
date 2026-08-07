#!/bin/sh
# tmux の automatic-rename-format から呼ばれ、ウィンドウ名を出力する。
# $1: pane_current_path  $2: pane_pid
path="$1"

# Claude Code 実行中は、そのセッションの要約（Claude Code が生成する ai-title）を表示する
claude_pid=$(pgrep -x -P "$2" claude 2>/dev/null | head -n 1)
if [ -n "$claude_pid" ]; then
    session_id=$(jq -r '.sessionId // empty' "$HOME/.claude/sessions/$claude_pid.json" 2>/dev/null)
    if [ -n "$session_id" ]; then
        # worktree へ移動したセッションは cwd とトランスクリプトの置き場が一致しないため glob で探す
        set -- "$HOME"/.claude/projects/*/"$session_id".jsonl
        if [ -f "$1" ]; then
            title=$(tac "$1" | grep -m1 '"type":"ai-title"' | jq -r '.aiTitle // empty')
            if [ -n "$title" ]; then
                echo "$title"
                exit
            fi
        fi
    fi
fi

cd "$path" 2>/dev/null || exit

# worktree 内でも main repo のディレクトリ名を表示するため --git-common-dir を使う
branch=$(git branch --show-current 2>/dev/null)
common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)

if [ -n "$common_dir" ]; then
    repo=$(basename "$(dirname "$common_dir")")
else
    repo=$(basename "$path")
fi

if [ -n "$branch" ]; then
    echo "${repo}(${branch})"
else
    echo "$repo"
fi
