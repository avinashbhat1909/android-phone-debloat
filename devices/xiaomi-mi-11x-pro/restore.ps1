# One-Click Restore Script for Xiaomi Mi 11X Pro
param([string]$Serial)

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$adb = Join-Path $repo 'tools\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { $adb = $adbCmd.Source } else { throw "ADB not found." }
}

$List = Join-Path $PSScriptRoot 'debloat.txt'
if (-not (Test-Path $List)) {
    throw "Debloat list not found: $List"
}

$serialArgs = @()
if ($Serial) { $serialArgs = @('-s', $Serial) }

Write-Host "=== Restoring Xiaomi Mi 11X Pro Packages ===" -ForegroundColor Cyan

# 1. Restore packages
$pkgs = Get-Content $List | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ } | ForEach-Object { ($_ -split '\s+')[0] }
$successCount = 0

foreach ($pkg in $pkgs) {
    Write-Host "Restoring: $pkg ... " -NoNewline
    $res = & $adb @serialArgs shell "cmd package install-existing $pkg" 2>&1
    if ($res -match 'installed for user: 0') {
        Write-Host "RESTORED" -ForegroundColor Green
        $successCount++
    } else {
        $res2 = & $adb @serialArgs shell "pm enable $pkg" 2>&1
        if ($res2 -match 'enabled' -or $res2 -match 'Package .* new state: default') {
            Write-Host "ENABLED" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "NOT PRESENT" -ForegroundColor Gray
        }
    }
}

# 2. Restore Themes app AppOps
Write-Host "`nRestoring Themes app AppOps permissions..." -ForegroundColor Cyan
& $adb @serialArgs shell "cmd appops set com.android.thememanager RUN_IN_BACKGROUND default" *>$null
& $adb @serialArgs shell "cmd appops set com.android.thememanager RUN_ANY_IN_BACKGROUND default" *>$null
& $adb @serialArgs shell "cmd appops set com.android.thememanager WAKE_LOCK default" *>$null
& $adb @serialArgs shell "cmd appops set com.android.thememanager SYSTEM_ALERT_WINDOW default" *>$null
Write-Host "Themes app permissions restored." -ForegroundColor Green

Write-Host "`nSummary: $successCount packages restored." -ForegroundColor Cyan
