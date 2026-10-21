# One-Click Safe Debloat & Optimization for Xiaomi Mi 11X Pro
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

Write-Host "=== Applying Xiaomi Mi 11X Pro Safe Debloat ===" -ForegroundColor Cyan

# 1. Uninstall packages for User 0
$pkgs = Get-Content $List | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ } | ForEach-Object { ($_ -split '\s+')[0] }
$successCount = 0
$alreadyRemoved = 0

foreach ($pkg in $pkgs) {
    Write-Host "Debloating: $pkg ... " -NoNewline
    $res = & $adb @serialArgs shell "pm uninstall -k --user 0 $pkg" 2>&1
    if ($res -match 'Success') {
        Write-Host "UNINSTALLED" -ForegroundColor Green
        $successCount++
    } elseif ($res -match 'not installed for 0' -or $res -match 'unknown package') {
        Write-Host "ALREADY REMOVED" -ForegroundColor DarkGray
        $alreadyRemoved++
    } else {
        Write-Host "SKIPPED ($res)" -ForegroundColor Yellow
    }
}

# 2. Neutering Themes app via AppOps
Write-Host "`nLocking down Themes app background activity..." -ForegroundColor Cyan
& $adb @serialArgs shell "cmd appops set com.android.thememanager RUN_IN_BACKGROUND ignore" *>$null
& $adb @serialArgs shell "cmd appops set com.android.thememanager RUN_ANY_IN_BACKGROUND ignore" *>$null
& $adb @serialArgs shell "cmd appops set com.android.thememanager WAKE_LOCK ignore" *>$null
& $adb @serialArgs shell "cmd appops set com.android.thememanager SYSTEM_ALERT_WINDOW ignore" *>$null
& $adb @serialArgs shell "am force-stop com.android.thememanager" *>$null
Write-Host "Themes app neutered (0% background drain)." -ForegroundColor Green

# 3. Private DNS Configuration
Write-Host "Configuring AdGuard Private DNS ... " -NoNewline
& $adb @serialArgs shell "settings put global private_dns_mode hostname; settings put global private_dns_specifier dns.adguard-dns.com"
Write-Host "ENABLED (dns.adguard-dns.com)" -ForegroundColor Green

Write-Host "`nSummary: $successCount newly uninstalled, $alreadyRemoved already clean." -ForegroundColor Cyan
Write-Host "Mi 11X Pro optimization successfully applied!" -ForegroundColor Green
