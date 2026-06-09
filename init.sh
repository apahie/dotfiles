#!/bin/bash
set -euo pipefail

# Fish shell
sudo add-apt-repository -y ppa:fish-shell/release-4
sudo apt update
sudo apt install -y fish
chsh -s "$(which fish)" || echo "警告: シェル変更に失敗しました。手動で chsh -s $(which fish) を実行してください"
fish -c 'set -U fish_greeting'

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

# GitHub CLI（mise でグローバル管理。認証は init.sh 後に `gh auth login` で実施）
# setup.sh の git config（gh api user）より前に gh が必要なため、ここで先に入れる。
~/.local/bin/mise use -g gh@latest

# workspace ディレクトリ
mkdir -p $HOME/workspace

# Temporary workspace directory with auto-cleanup (30 days)
mkdir -p $HOME/workspace/tmp
echo "e $HOME/workspace/tmp - - - 30d" | sudo tee /etc/tmpfiles.d/workspace-tmp.conf

echo ""
echo "=========================================="
echo "  init.sh 完了"
echo "=========================================="
echo ""
echo "次のステップ:"
echo "  1. WSL を一度再起動してください"
echo "  2. 再起動後、GitHub CLI で認証してください:"
echo "       gh auth login -s user"
echo "  3. dotfiles をクローンして setup.sh を実行してください:"
echo "       git clone https://github.com/apahie/dotfiles.git ~/workspace/dotfiles"
echo "       ~/workspace/dotfiles/setup.sh"
echo ""
