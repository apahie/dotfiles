#!/bin/sh
cd "$1" 2>/dev/null || exit
repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "$1")")
branch=$(git branch --show-current 2>/dev/null)
if [ -n "$branch" ]; then
    echo "${repo}(${branch})"
else
    echo "$repo"
fi
