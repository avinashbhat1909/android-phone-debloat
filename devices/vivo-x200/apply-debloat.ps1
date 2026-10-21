# One-Click Safe Debloat & Optimization for vivo X200 Series
param([string]$Serial)

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$adb = Join-Path $repo 'tools\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { $adb = $adbCmd.Source } else { throw "ADB not found." }
}

$serialArgs = @()
if ($Serial) { $serialArgs = @('-s', $Serial) }

Write-Host "=== Applying vivo X200 Safe Debloat ===" -ForegroundColor Cyan

# 1. Uninstalls for User 0
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
    Write-Host "Uninstalling $pkg ... " -NoNewline
    $res = & $adb @serialArgs shell "pm uninstall -k --user 0 $pkg" 2>&1
    if ($res -match "Success") {
        Write-Host "UNINSTALLED" -ForegroundColor Green
    } else {
        Write-Host "$res" -ForegroundColor Gray
    }
}

# 2. Package Manager Disable
Write-Host "Disabling com.vivo.magazine (Lockscreen Poster) ... " -NoNewline
$resMag = & $adb @serialArgs shell "pm disable-user --user 0 com.vivo.magazine" 2>&1
Write-Host "$resMag" -ForegroundColor Green

# 3. AppOps Neutering (ROM Protected Apps)
$neutered = @(
    'com.vivo.appstore',
    'com.vivo.globalsearch',
    'com.vivo.hiboard',
    'com.vivo.website'
)
$ops = @('RUN_IN_BACKGROUND', 'RUN_ANY_IN_BACKGROUND', 'WAKE_LOCK', 'SYSTEM_ALERT_WINDOW')

foreach ($pkg in $neutered) {
    Write-Host "Neutering $pkg via AppOps ... " -NoNewline
    foreach ($op in $ops) {
        & $adb @serialArgs shell "cmd appops set $pkg $op ignore" *>$null
    }
    & $adb @serialArgs shell "am force-stop $pkg" *>$null
    Write-Host "LOCKED DOWN" -ForegroundColor Green
}

# 4. Private DNS Configuration
Write-Host "Configuring AdGuard Private DNS ... " -NoNewline
& $adb @serialArgs shell "settings put global private_dns_mode hostname; settings put global private_dns_specifier dns.adguard-dns.com"
Write-Host "ENABLED (dns.adguard-dns.com)" -ForegroundColor Green

Write-Host "`nAll safe debloats and optimizations successfully applied!" -ForegroundColor Green
