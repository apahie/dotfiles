#!/bin/bash
# WSL2からWindows Toast通知を送るスクリプト
# 使用方法: notify.sh [メッセージ]

# プロジェクト名とブランチ名を取得
PROJECT=$(basename "$PWD" 2>/dev/null || echo "unknown")
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

# タイトルを構築
if [[ -n "$BRANCH" ]]; then
  TITLE="$PROJECT ($BRANCH)"
else
  TITLE="$PROJECT"
fi

MESSAGE="${1:-タスクが完了しました}"

# 環境変数経由でPowerShellに値を渡す（インジェクション防止）
NOTIFY_TITLE="$TITLE" NOTIFY_MESSAGE="$MESSAGE" powershell.exe -Command '
$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
$textNodes = $template.GetElementsByTagName("text")
$textNodes.Item(0).AppendChild($template.CreateTextNode($env:NOTIFY_TITLE)) > $null
$textNodes.Item(1).AppendChild($template.CreateTextNode($env:NOTIFY_MESSAGE)) > $null

$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
$notification = [Windows.UI.Notifications.ToastNotification]::new($template)
$notifier.Show($notification)
' 2>/dev/null

printf '\a' > /dev/tty

exit 0
