# mise は tmux より先に activate する（tmux が mise 管理版で起動するように）
~/.local/bin/mise activate fish | source

# tmux: claude セッションに入る（なければ作る。残っていれば attach する）
# WSL 初回起動時は systemd の準備完了を待ってから tmux を起動する。
# VM が止まって systemd の起動が終わらないことがあるので、待ちは 60 秒で打ち切る
if not set -q TMUX; and status is-interactive
    timeout 60 systemctl is-system-running --wait >/dev/null 2>&1
    exec tmux new-session -A -s claude
end

fzf --fish | source
command -q docker; and docker completion fish | source
command -q helm; and helm completion fish | source
command -q kubectl; and kubectl completion fish | source

# abbreviations
abbr -a kc kubectl
abbr -a gw 'git worktree'
abbr -a cr claude-resume

# Windows Terminal でペイン分割・新タブ時にカレントディレクトリを引き継ぐ (OSC 9;9)
# https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
function storePathForWindowsTerminal --on-variable PWD
    if test -n "$WT_SESSION"
        printf "\e]9;9;%s\e\\" (wslpath -w "$PWD")
    end
end

# starship init は常に最後に設定すること
starship init fish | source
