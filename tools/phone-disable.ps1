# Debloats connected Xiaomi HyperOS / MIUI phone via modern ADB
# Uses 'pm uninstall -k --user 0' (HyperOS standard) or 'pm disable-user --user 0' (MIUI)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\phone-disable.ps1 examples\xiaomi-mi-11x-pro\debloat-safe.txt
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
    throw "Device not connected or not authorized! Run '& tools\platform-tools\adb.exe devices' to check."
}

$model = (& $adb @serialArgs shell getprop ro.product.model).Trim()
$osVer = (& $adb @serialArgs shell getprop ro.build.version.release).Trim()
$hyperVer = (& $adb @serialArgs shell getprop ro.miui.ui.version.name).Trim()
Write-Host "Connected Device: $model (Android $osVer / HyperOS $hyperVer)" -ForegroundColor Green

# Packages to NEVER disable under any circumstance on a phone
$blacklisted = @(
    'com.miui.securitycenter',
    'com.miui.securityadd',
    'com.miui.securitycore',
    'com.miui.home',
    'com.android.systemui',
    'com.android.settings',
    'com.android.phone',
    'com.google.android.dialer',
    'com.google.android.apps.messaging',
    'com.android.providers.telephony'
)

$pkgs = Get-Content $List | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ } | ForEach-Object { ($_ -split '\s+')[0] }

Write-Host "Processing package list: $List" -ForegroundColor Yellow
$successCount = 0
$failCount = 0
$skippedCount = 0

foreach ($pkg in $pkgs) {
    if ($blacklisted -contains $pkg) {
        Write-Warning "BLOCKED: $pkg is essential to avoid bootloops!"
        continue
    }

    Write-Host "Debloating: $pkg ... " -NoNewline
    # Attempt HyperOS uninstall for user 0 (keeps apk on system partition, reversible)
    $res = & $adb @serialArgs shell pm uninstall -k --user 0 $pkg 2>&1
    if ($res -match 'Success') {
        Write-Host "UNINSTALLED (User 0)" -ForegroundColor Green
        $successCount++
    } elseif ($res -match 'not installed for 0' -or $res -match 'Unknown package') {
        Write-Host "NOT PRESENT (Skipped)" -ForegroundColor Gray
        $skippedCount++
    } else {
        # Fallback to disable-user if uninstall reported failure
        $res2 = & $adb @serialArgs shell pm disable-user --user 0 $pkg 2>&1
        if ($res2 -match 'disabled') {
            Write-Host "DISABLED" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "FAILED ($res)" -ForegroundColor Red
            $failCount++
        }
    }
}

Write-Host "`nSummary: $successCount removed, $skippedCount not installed, $failCount failed." -ForegroundColor Cyan
Write-Host "To restore all packages anytime, run: powershell -ExecutionPolicy Bypass -File tools\phone-restore.ps1 $List" -ForegroundColor Yellow
