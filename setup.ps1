# エクスプローラでファイル拡張子を表示する設定
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

winget install -e --id Mozilla.Firefox
winget install -e --id Google.Chrome
winget install -e --id Google.GoogleDrive
winget install -e --id Valve.Steam
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Microsoft.PowerToys
winget install -e --id Microsoft.WindowsTerminal
winget install -e --id Git.Git
winget install -e --id GitHub.cli
winget install -e --id Amazon.Kindle
winget install -e --id Obsidian.Obsidian

wsl --install