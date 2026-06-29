# Usage: powershell -ExecutionPolicy Bypass -File setup-windows.ps1

# Re-launch as administrator if not already elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$failures = @()

$packages = @(
    "Microsoft.PowerShell",
    "Microsoft.PowerToys",
    "Microsoft.WindowsTerminal",
    "Microsoft.VisualStudioCode",
    "Git.Git",
    "GitHub.cli",
    "Mozilla.Firefox",
    "Google.Chrome",
    "Google.GoogleDrive",
    "Obsidian.Obsidian",
    "9P8JQ0JJSTLL",  # Amazon Kindle (MS Store版)
    "Valve.Steam",
    "7zip.7zip",
    "WinMerge.WinMerge",
    "astral-sh.uv",
    "jqlang.jq",
    "MikeFarah.yq",
    "Anthropic.Claude"
)

foreach ($pkg in $packages) {
    Write-Host "Installing: $pkg ... " -ForegroundColor Cyan -NoNewline
    $wingetArgs = @("install", "-e", "--id", $pkg, "--accept-source-agreements", "--accept-package-agreements")
    if ($pkg -eq "Microsoft.VisualStudioCode") {
        $wingetArgs += "--custom", "/VERYSILENT /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath"
    }
    if ($pkg -eq "9P8JQ0JJSTLL") {
        $wingetArgs += "--source", "msstore"
    }
    $output = & winget @wingetArgs 2>&1
    switch ($LASTEXITCODE) {
        0           { Write-Host "done" -ForegroundColor Green }
        -1978335189 { Write-Host "up to date" -ForegroundColor Yellow }  # アップグレード対象なし
        default {
            Write-Host "failed (exit $LASTEXITCODE)" -ForegroundColor Red
            $output | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
            $failures += $pkg
        }
    }
}

# Claude Code（公式 native installer。バックグラウンドで自動更新される）
$claudeExe = Join-Path $env:USERPROFILE ".local\bin\claude.exe"
if (Test-Path $claudeExe) {
    Write-Host "Already exists: Claude Code" -ForegroundColor Yellow
} else {
    Write-Host "Installing: Claude Code" -ForegroundColor Cyan
    try {
        Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
        if (-not (Test-Path $claudeExe)) { throw "claude.exe が見つかりません" }
        Write-Host "Installed: $claudeExe" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install Claude Code: $_" -ForegroundColor Red
        $failures += "Claude Code"
    }
}

# zenhan（IME全角/半角切替ツール）
$binDir = Join-Path $HOME "bin"
$zenhanPath = Join-Path $binDir "zenhan.exe"
if (-not (Test-Path $zenhanPath)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    $zenhanUrl = "https://github.com/iuchim/zenhan/releases/download/v0.0.1/zenhan.zip"
    $zenhanZip = Join-Path $env:TEMP "zenhan.zip"
    Write-Host "Downloading: zenhan.exe" -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $zenhanUrl -OutFile $zenhanZip -UseBasicParsing
        $extract = Join-Path $env:TEMP "zenhan"
        Expand-Archive -Path $zenhanZip -DestinationPath $extract -Force
        Copy-Item (Join-Path $extract "zenhan\bin64\zenhan.exe") $zenhanPath
        # ファイルが正常にコピーされたか検証
        if (-not (Test-Path $zenhanPath)) { throw "zenhan.exe のコピーに失敗しました" }
        Write-Host "Installed: $zenhanPath" -ForegroundColor Green
    } catch {
        Remove-Item -Path $zenhanPath -Force -ErrorAction SilentlyContinue
        Write-Host "Failed to install zenhan.exe: $_" -ForegroundColor Red
        $failures += "zenhan"
    } finally {
        Remove-Item -Path $zenhanZip, (Join-Path $env:TEMP "zenhan") -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "Already exists: $zenhanPath" -ForegroundColor Yellow
}

# PATH に追加（claude.exe は .local\bin、zenhan.exe 等は %USERPROFILE%\bin）
$claudeBinDir = Join-Path $env:USERPROFILE ".local\bin"
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
foreach ($dir in @($claudeBinDir, $binDir)) {
    if ($userPath -notlike "*$dir*") {
        $userPath = "$userPath;$dir"
        [Environment]::SetEnvironmentVariable("PATH", $userPath, "User")
        Write-Host "Added to PATH: $dir" -ForegroundColor Green
    }
}

# Symlink PowerShell profile
$profileSource = Join-Path $PSScriptRoot "Documents\PowerShell\Profile.ps1"
$profileTarget = Join-Path $HOME "Documents\PowerShell\Profile.ps1"
New-Item -ItemType Directory -Path (Split-Path $profileTarget) -Force | Out-Null
New-Item -ItemType SymbolicLink -Path $profileTarget -Target $profileSource -Force | Out-Null
Write-Host "Linked: $profileSource -> $profileTarget" -ForegroundColor Green

# Symlink Claude Code config
$claudeDir = Join-Path $HOME ".claude"
New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
$claudeLinks = @{
    (Join-Path $PSScriptRoot ".claude-windows\settings.json") = (Join-Path $claudeDir "settings.json")
    (Join-Path $PSScriptRoot ".claude-windows\CLAUDE.md")     = (Join-Path $claudeDir "CLAUDE.md")
    (Join-Path $PSScriptRoot ".claude-windows\skills")        = (Join-Path $claudeDir "skills")
}
foreach ($entry in $claudeLinks.GetEnumerator()) {
    New-Item -ItemType SymbolicLink -Path $entry.Value -Target $entry.Key -Force | Out-Null
    Write-Host "Linked: $($entry.Key) -> $($entry.Value)" -ForegroundColor Green
}

# WSL
Write-Host "Installing: WSL" -ForegroundColor Cyan
$wslList = wsl --list --quiet 2>$null
$wslInstalled = $wslList -match '\S'
if ($wslInstalled) {
    Write-Host "WSL distro already registered, skipping" -ForegroundColor Yellow
} else {
    wsl --install
}

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Host "Setup completed with $($failures.Count) error(s):" -ForegroundColor Yellow
    foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Yellow }
} else {
    Write-Host "Setup completed" -ForegroundColor Green
}

Read-Host "Press Enter to close"
