# Restores previously debloated packages on connected Xiaomi HyperOS / MIUI phone
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\phone-restore.ps1 examples\xiaomi-mi-11x-pro\debloat-safe.txt
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$List,
    [string]$Serial
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
$adb = Join-Path $repo 'tools\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) {
        $adb = $adbCmd.Source
    } else {
        throw "ADB not found. Please install ADB (e.g. 'winget install Google.PlatformTools' or 'brew install android-platform-tools') or download Google Platform-Tools."
    }
}

$List = (Resolve-Path $List).Path
if (-not (Test-Path $List)) {
    throw "List file not found: $List"
}

$serialArgs = @()
if ($Serial) {
    $serialArgs = @('-s', $Serial)
}

& $adb start-server *>$null
$devCheck = (& $adb @serialArgs get-state) 2>$null
if ($devCheck -notmatch 'device') {
    throw "Device not connected or not authorized! Run '& tools\platform-tools\adb.exe devices' to check status."
}

$pkgs = Get-Content $List | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ } | ForEach-Object { ($_ -split '\s+')[0] }

Write-Host "Restoring packages from: $List" -ForegroundColor Yellow
$successCount = 0

foreach ($pkg in $pkgs) {
    Write-Host "Restoring: $pkg ... " -NoNewline
    # Method 1: install-existing (for user 0 uninstalls)
    $res = & $adb @serialArgs shell cmd package install-existing $pkg 2>&1
    if ($res -match 'installed for user: 0') {
        Write-Host "RESTORED (Reinstalled for User 0)" -ForegroundColor Green
        $successCount++
        continue
    }

    # Method 2: pm enable (for frozen packages)
    $res2 = & $adb @serialArgs shell pm enable $pkg 2>&1
    if ($res2 -match 'enabled' -or $res2 -match 'Package .* new state: default') {
        Write-Host "ENABLED" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "SKIPPED/NOT PRESENT" -ForegroundColor Gray
    }
}

Write-Host "`nSummary: $successCount packages restored." -ForegroundColor Cyan
