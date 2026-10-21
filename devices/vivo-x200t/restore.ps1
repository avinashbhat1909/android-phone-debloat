# One-Click Restore Script for vivo X200T
param([string]$Serial)

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$adb = Join-Path $repo 'tools\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { $adb = $adbCmd.Source } else { throw "ADB not found." }
}

$serialArgs = @()
if ($Serial) { $serialArgs = @('-s', $Serial) }

Write-Host "=== Restoring vivo X200T Debloated Packages ===" -ForegroundColor Cyan

# 1. Restore uninstalled packages
$uninstalls = @(
    'com.vivo.browser',
    'com.android.browser',
    'com.vivo.hybrid',
    'com.vivo.nps',
    'com.android.bbklog',
    'com.facebook.services',
    'com.facebook.system',
    'com.facebook.appmanager',
    'com.google.android.apps.wellbeing',
    'com.google.android.feedback',
    'com.vivo.unionpay'
)

foreach ($pkg in $uninstalls) {
    Write-Host "Restoring $pkg ... " -NoNewline
    $res = & $adb @serialArgs shell "cmd package install-existing $pkg" 2>&1
    Write-Host "$res" -ForegroundColor Green
}

# 2. Re-enable com.vivo.magazine
Write-Host "Re-enabling com.vivo.magazine ... " -NoNewline
$resMag = & $adb @serialArgs shell "pm enable com.vivo.magazine" 2>&1
Write-Host "$resMag" -ForegroundColor Green

# 3. Restore AppOps
$neutered = @(
    'com.vivo.appstore',
    'com.vivo.globalsearch',
    'com.vivo.hiboard',
    'com.vivo.website'
)
$ops = @('RUN_IN_BACKGROUND', 'RUN_ANY_IN_BACKGROUND', 'WAKE_LOCK', 'SYSTEM_ALERT_WINDOW')

foreach ($pkg in $neutered) {
    Write-Host "Restoring AppOps for $pkg ... " -NoNewline
    foreach ($op in $ops) {
        & $adb @serialArgs shell "cmd appops set $pkg $op default" *>$null
    }
    Write-Host "RESTORED" -ForegroundColor Green
}

Write-Host "`nAll packages and AppOps permissions restored successfully!" -ForegroundColor Green
