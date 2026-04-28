# CLAUDE.md

## プロジェクト概要

dotfiles管理リポジトリ。`setup.sh` で環境構築を一括実行する。

## 基本方針

- **シンプルな構成・処理を優先する。** 過度な抽象化やカスタム関数を避け、最小限の実装で済ませる。
- 変更を加える前に、各設定が何をするか説明してから適用する。
- 設定の追加提案は控えめに。ユーザーが聞いたときだけ提案する。

## コーディングスタイル

- setup.sh はべき等性（何度実行しても安全）を保つ。
- シンボリックリンクはファイル単位よりディレクトリ単位を優先する。
- 改行コードは LF に統一する（Windows用 .ps1 ファイルを除く）。

## コミット

- コミットメッセージは日本語で記述する。
- 変更単位は小さく、こまめにコミットする。
- 変更を反映するたびにコミットしてよい（指示不要）。コミット後はpushしてよい。

## CLAUDE.md の運用

- 作業中に判明したルールや方針は、必要に応じてこのファイルに自動反映する。

## 技術スタック

- シェル: fish
- ツール管理: mise
- プロンプト: starship（config.fish で常に最後に設定）
- エディタ: neovim
- AI: Claude Code

## 運用方針 (single repo / overlay base)

このリポジトリは **単体で完結し、独立して動く** dotfiles。
職場用 dotfiles ([nagano-hirofumi-16/dotfiles](https://github.com/nagano-hirofumi-16/dotfiles)) からは submodule として参照されるが、依存は **一方向** （こちらから職場側を意識しない）。

### 設計原則

- どんな環境でも `bash setup.sh` 一発で動作することを最優先。
- 職場固有の値（Oracle, OCI, work-vault 等）は持たない。
- 可変な部分は **環境変数で上書き可能** にする（overlay 側からの拡張ポイント）。
  - 例: `auto-report.sh` の `VAULT_NAME=${VAULT_NAME:-my-vault}`

### overlay 拡張ポイント（変更時は work overlay 側に影響することを意識する）

- `~/.apm/apm.yml` は overlay 側が yq でマージし実体ファイル化することがある。
- fish の `conf.d/` と `fish_function_path` は overlay 側から追加される。
- Claude Code の `settings.local.json` は overlay 側で merge される。
- `~/.claude/agents/`, `~/.claude/skills/` は overlay 側が同名衝突しない範囲で追加する。
- mise の `MISE_ENV` で `config.<env>.toml` が overlay 側から merge 読み込みされる。
