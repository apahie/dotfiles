~/.local/bin/mise activate fish | source
fzf --fish | source
docker completion fish | source
helm completion fish | source
kubectl completion fish | source

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
