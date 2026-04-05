#!/bin/bash
set -euo pipefail

# Fish shell
sudo add-apt-repository -y ppa:fish-shell/release-4
sudo apt update
sudo apt install -y fish
chsh -s $(which fish)
set -U fish_greeting

mkdir -p ~/.config/fish/functions
cat > ~/.config/fish/functions/run-bash.fish << 'EOF'
function run-bash
    if test (count $argv) -gt 0
        bash -c "$argv"
    else
        powershell.exe -command Get-Clipboard | tr -d '\r' | bash
    end
end
EOF

# mise
curl https://mise.run | sh
echo '~/.local/bin/mise activate fish | source' >> ~/.config/fish/config.fish

# Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# GitHub CLI
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

# Temporary workspace directory with auto-cleanup (30 days)
mkdir -p $HOME/workspace/tmp
echo "e $HOME/workspace/tmp - - - 30d" | sudo tee /etc/tmpfiles.d/workspace-tmp.conf
