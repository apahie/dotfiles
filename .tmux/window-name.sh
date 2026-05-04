#!/bin/sh
cd "$1" 2>/dev/null || exit

# worktree 内でも main repo のディレクトリ名を表示するため --git-common-dir を使う
branch=$(git branch --show-current 2>/dev/null)
common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)

if [ -n "$common_dir" ]; then
    repo=$(basename "$(dirname "$common_dir")")
else
    repo=$(basename "$1")
fi

if [ -n "$branch" ]; then
    echo "${repo}(${branch})"
else
    echo "$repo"
fi
