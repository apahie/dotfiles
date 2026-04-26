# dotfiles

## 自動リサーチ（last30days × Routines）

[`mvanhorn/last30days-skill`](https://github.com/mvanhorn/last30days-skill) を Claude Code の Routines（クラウド側スケジューラ）から深夜帯に自動実行し、結果を my-vault に commit & push する仕組み。

- **インストール**: `setup.sh` でマーケットプレイス追加 + プラグインインストールを自動化
- **スケジューラ**: claude.ai/code/routines で 3 つの Routine を手動設定（dotfiles 管理外）
- **出力先**: `my-vault/daily/YYYY/MM/DD/morning-brief-<topic>.md`

### Routines の設定手順

[claude.ai/code/routines](https://claude.ai/code/routines) で **3 つの Routine** を作成する。共通設定にトピックと時刻だけ差し替えてコピー複製する。

#### 共通設定

| 項目 | 値 |
|---|---|
| Repository | `apahie/my-vault` |
| Allow unrestricted branch pushes | **ON**（main へ直接 push する） |
| Trigger | Schedule（cron） |
| Environment | 不要（Reddit / HN / Polymarket / Web search はゼロ設定） |

#### Routine 一覧

| 名前 | Schedule (Asia/Tokyo) | トピック | 出力ファイル名 |
|---|---|---|---|
| morning-brief-ai-coding-tools | `0 3 * * *` | `AI coding tools` | `morning-brief-ai-coding-tools.md` |
| morning-brief-claude-code | `0 4 * * *` | `Claude Code` | `morning-brief-claude-code.md` |
| morning-brief-ai-agents | `0 5 * * *` | `AI agents` | `morning-brief-ai-agents.md` |

#### Prompt テンプレート

各 Routine の prompt に以下を貼り、`<TOPIC>` と `<FILENAME>` を上表の値に差し替える。

```
/last30days "<TOPIC>" を実行し、結果を以下のファイルに保存してください:

  daily/{今日のYYYY}/{MM}/{DD}/<FILENAME>

保存後の手順:
1. git pull --rebase origin main
2. git add daily/
3. git commit -m "daily: <FILENAME> を追加"
4. git push origin main
```

### 動作確認

- 各 Routine 作成後に **Run now** で初回実行
- GitHub 上で `daily/YYYY/MM/DD/morning-brief-*.md` が生成され commit されていれば成功
- ローカルで `git pull` して Obsidian から参照できる

### 既知のリスク

- Routines クラウド環境でローカルインストール済みのスキルが使えない場合、prompt 冒頭に `claude plugin install last30days@last30days-skill` を入れるか、`my-vault/.claude/skills/last30days/` を vault に commit して同梱する方針に切り替える
- 03:00〜05:00 に手動 commit/push があると non-fast-forward。`git pull --rebase` を prompt に必ず入れている前提