# tmux: claudeセッションがなければ作成して入る
if not set -q TMUX
    if not tmux has-session -t claude 2>/dev/null
        exec tmux new-session -s claude
    end
end

~/.local/bin/mise activate fish | source
fzf --fish | source
command -q docker; and docker completion fish | source
command -q helm; and helm completion fish | source
command -q kubectl; and kubectl completion fish | source

# abbreviations
abbr -a kc kubectl

# Windows Terminal でペイン分割・新タブ時にカレントディレクトリを引き継ぐ (OSC 9;9)
# https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
function storePathForWindowsTerminal --on-variable PWD
    if test -n "$WT_SESSION"
        printf "\e]9;9;%s\e\\" (wslpath -w "$PWD")
    end
end

# starship init は常に最後に設定すること
starship init fish | source
