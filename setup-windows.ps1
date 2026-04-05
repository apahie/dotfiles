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
    "Amazon.Kindle",
    "Valve.Steam",
    "7zip.7zip",
    "WinMerge.WinMerge",
    "astral-sh.uv",
    "Anthropic.ClaudeCode"
)

foreach ($pkg in $packages) {
    Write-Host "Installing: $pkg" -ForegroundColor Cyan
    $wingetArgs = @("install", "-e", "--id", $pkg, "--accept-source-agreements", "--accept-package-agreements")
    if ($pkg -eq "Microsoft.VisualStudioCode") {
        $wingetArgs += "--custom", "/VERYSILENT /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath"
    }
    & winget @wingetArgs
    # 0: success, -1978335189: already up to date
    $wingetOk = @(0, -1978335189)
    if ($LASTEXITCODE -notin $wingetOk) { $failures += $pkg }
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

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Host "Setup completed with $($failures.Count) error(s):" -ForegroundColor Yellow
    foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Yellow }
} else {
    Write-Host "Setup completed" -ForegroundColor Green
}
# WSL
Write-Host "Installing: WSL" -ForegroundColor Cyan
wsl --install

Read-Host "Press Enter to close"
