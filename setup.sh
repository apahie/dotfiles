#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# apt パッケージ
echo "apt パッケージをインストール中..."
sudo apt install -y \
  tig \
  tree \
  fonts-noto-cjk # Playwright の headless Chromium で日本語表示に必要

# Claude Code pptx スキル（document-skills:pptx）の依存パッケージ
# libreoffice-impress: PPTX→PDF 変換（soffice）
# poppler-utils: PDF→JPEG 変換（pdftoppm）
# fonts-noto-color-emoji: 絵文字レンダリング
echo "Claude Code pptx スキルの依存パッケージをインストール中..."
sudo apt install -y \
  libreoffice-impress \
  poppler-utils \
  fonts-noto-color-emoji

# Docker Engine（miseではシステムデーモンを管理できないためaptでインストール）
if ! command -v docker &>/dev/null; then
  echo "Docker Engine をインストール中..."
  sudo apt install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<SOURCES
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
SOURCES
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
  echo "Docker インストール完了（グループ反映には再ログインが必要です）"
fi

# git config
if gh auth status &>/dev/null; then
  git config --global user.name "$(gh api user -q .login)"
  git config --global user.email "$(gh api user/emails -q '.[] | select(.primary) | .email')"
else
  echo "警告: gh が未認証のため git config user.name/email をスキップします"
fi
git config --global init.defaultBranch main
git config --global core.quotepath false

# シンボリックリンクを作成する関数
link_file() {
  local src="$1"
  local dest="$2"

  # 親ディレクトリがなければ作成
  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ]; then
    echo "既にシンボリックリンクです: $dest -> $(readlink "$dest")"
    if [ "$(readlink "$dest")" = "$src" ]; then
      echo "  スキップ（同じリンク先）"
      return
    fi
    echo "  リンク先を更新します"
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "バックアップ: $dest -> ${dest}.bak"
    mv "$dest" "${dest}.bak"
  fi

  ln -s "$src" "$dest"
  echo "リンク作成: $dest -> $src"
}

# tmux
link_file "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$SCRIPT_DIR/.tmux" "$HOME/.tmux"

# mise
link_file "$SCRIPT_DIR/.config/mise/config.toml" "$HOME/.config/mise/config.toml"

# starship
link_file "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"


# fish
link_file "$SCRIPT_DIR/.config/fish/config.fish" "$HOME/.config/fish/config.fish"
link_file "$SCRIPT_DIR/.config/fish/functions" "$HOME/.config/fish/functions"

# Claude Code - settings
link_file "$SCRIPT_DIR/.claude-linux/settings.json" "$HOME/.claude/settings.json"
link_file "$SCRIPT_DIR/.claude-linux/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Claude Code - plugins（claude-plugins-official）
PLUGINS=(
  agent-sdk-dev              # Agent SDKアプリの開発支援
  claude-code-setup          # コードベースに最適なClaude Code設定を推奨
  claude-md-management       # CLAUDE.mdの品質監査・改善
  code-review                # 5観点の並列PRレビュー（信頼度スコア付き）
  code-simplifier            # コードの簡素化・リファクタリング
  commit-commands            # コミット・プッシュ・PR作成の自動化
  explanatory-output-style   # 実装理由の教育的解説を追加
  feature-dev                # 探索→設計→レビューの構造化された機能開発
  hookify                    # 会話パターンからフックを自動生成
  learning-output-style      # ユーザーにコード貢献を求める学習モード
  playground                 # インタラクティブHTMLプレイグラウンド作成
  pr-review-toolkit          # 6種の専門エージェントによるPRレビュー
  ralph-loop                 # タスク完了まで同じプロンプトを繰り返し実行
  plugin-dev                 # プラグイン・スキル開発ツールキット
  security-guidance          # 編集時にセキュリティ問題を警告
  # LSP（Language Server Protocol）
  gopls-lsp                  # Go
  jdtls-lsp                  # Java
  lua-lsp                    # Lua
  pyright-lsp                # Python
  rust-analyzer-lsp          # Rust
  typescript-lsp             # TypeScript/JavaScript
)
echo ""
echo "Claude Code plugins をインストール中..."
for plugin in "${PLUGINS[@]}"; do
  claude plugin install "$plugin@claude-plugins-official" 2>/dev/null || true
done

# Claude Code - plugins（anthropic-agent-skills）
# マーケットプレイスを追加してからインストール
claude plugin marketplace add https://github.com/anthropics/skills 2>/dev/null || true
AGENT_SKILLS_PLUGINS=(
  document-skills            # ドキュメント処理（Excel, Word, PowerPoint, PDF）
)
for plugin in "${AGENT_SKILLS_PLUGINS[@]}"; do
  claude plugin install "$plugin@anthropic-agent-skills" 2>/dev/null || true
done

# Claude Code - skills, hooks（ディレクトリ単位）
link_file "$SCRIPT_DIR/.claude-linux/skills" "$HOME/.claude/skills"
link_file "$SCRIPT_DIR/.claude-linux/hooks" "$HOME/.claude/hooks"

# my-vault
if [ ! -d "$HOME/workspace/my-vault" ]; then
  echo "my-vault をクローン中..."
  git clone https://github.com/apahie/my-vault.git "$HOME/workspace/my-vault"
else
  echo "my-vault は既に存在します: $HOME/workspace/my-vault"
fi

# mise trust & install
echo ""
echo "mise trust & install を実行中..."
mise trust "$SCRIPT_DIR/.config/mise/config.toml"
mise install

# アップデート（スキルのインストールを含む）
echo ""
echo "アップデートを実行中..."
mise run update

# git config（delta）
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global merge.conflictstyle diff3

echo ""
echo "セットアップ完了"
echo ""
echo "次のコマンドで fish を再初期化してください:"
echo "  exec fish"
