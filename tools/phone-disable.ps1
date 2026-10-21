# Universal Android Phone Debloater via Modern ADB
# Uses 'pm uninstall -k --user 0' (Reversible, keeps apk on read-only system partition)
# Fallback to 'pm disable-user --user 0' if uninstall is restricted by OEM ROM
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\phone-disable.ps1 devices\vivo-x200t\debloat.txt
#   powershell -ExecutionPolicy Bypass -File tools\phone-disable.ps1 devices\vivo-x200t\debloat.txt -DryRun
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$List,
    [switch]$DryRun,
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
        throw "ADB not found. Please install ADB or download Google Platform-Tools."
    }
}

$List = (Resolve-Path $List).Path
if (-not (Test-Path $List)) {
    throw "List file not found: $List"
}

$serialArgs = @()
if ($Serial) { $serialArgs = @('-s', $Serial) }

& $adb start-server *>$null
$devCheck = (& $adb @serialArgs get-state) 2>$null
if ($devCheck -notmatch 'device') {
    throw "Device not connected or not authorized! Run '& tools\platform-tools\adb.exe devices' to check."
}

$brand = (& $adb @serialArgs shell getprop ro.product.brand).Trim()
$model = (& $adb @serialArgs shell getprop ro.product.model).Trim()
$osVer = (& $adb @serialArgs shell getprop ro.build.version.release).Trim()
Write-Host "Connected Device: $brand $model (Android $osVer)" -ForegroundColor Green

if ($DryRun) {
    Write-Host "MODE: DRY-RUN / PREVIEW ONLY (No packages will be modified)`n" -ForegroundColor Yellow
}

# Essential load-bearing packages to NEVER disable on any device
$blacklisted = @(
    'com.miui.securitycenter',
    'com.miui.securityadd',
    'com.miui.securitycore',
    'com.miui.home',
    'com.vivo.daemonService',
    'com.vivo.fingerprint',
    'com.android.systemui',
    'com.android.settings',
    'com.android.phone',
    'com.google.android.dialer',
    'com.google.android.apps.messaging',
    'com.android.providers.telephony'
)

$pkgs = Get-Content $List | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ } | ForEach-Object { ($_ -split '\s+')[0] }

# Fetch installed packages cache for fast scanning
$installedRaw = & $adb @serialArgs shell "pm list packages"
$installedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($line in $installedRaw) {
    $p = $line -replace '^package:', ''
    if ($p) { [void]$installedSet.Add($p.Trim()) }
}

Write-Host "Processing package list: $List" -ForegroundColor Cyan
$successCount = 0
$failCount = 0
$skippedCount = 0
$wouldRemoveCount = 0

foreach ($pkg in $pkgs) {
    if ($blacklisted -contains $pkg) {
        Write-Warning "BLOCKED: $pkg is essential to prevent bootloops!"
        continue
    }

    $isInstalled = $installedSet.Contains($pkg)

    if ($DryRun) {
        if ($isInstalled) {
            Write-Host "[WOULD UNINSTALL] " -ForegroundColor Yellow -NoNewline
            Write-Host "$pkg " -ForegroundColor White -NoNewline
            Write-Host "(Installed on device)" -ForegroundColor Gray
            $wouldRemoveCount++
        } else {
            Write-Host "[ALREADY CLEAN]   " -ForegroundColor DarkGray -NoNewline
            Write-Host "$pkg " -ForegroundColor DarkGray -NoNewline
            Write-Host "(Not present)" -ForegroundColor DarkGray
            $skippedCount++
        }
        continue
    }

    # Normal Execution Mode
    Write-Host "Debloating: $pkg ... " -NoNewline
    $res = & $adb @serialArgs shell pm uninstall -k --user 0 $pkg 2>&1
    if ($res -match 'Success') {
        Write-Host "UNINSTALLED (User 0)" -ForegroundColor Green
        $successCount++
    } elseif ($res -match 'not installed for 0' -or $res -match 'Unknown package') {
        Write-Host "NOT PRESENT (Skipped)" -ForegroundColor Gray
        $skippedCount++
    } else {
        # Fallback to disable-user if uninstall was restricted by OEM ROM
        $res2 = & $adb @serialArgs shell pm disable-user --user 0 $pkg 2>&1
        if ($res2 -match 'disabled' -or $res2 -match 'Package .* new state: disabled-user') {
            Write-Host "DISABLED" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "FAILED ($res)" -ForegroundColor Red
            $failCount++
        }
    }
}

if ($DryRun) {
    Write-Host "`nDry-Run Summary: $wouldRemoveCount packages would be removed, $skippedCount already clean." -ForegroundColor Cyan
    Write-Host "To apply these changes for real, re-run without -DryRun" -ForegroundColor Yellow
} else {
    Write-Host "`nSummary: $successCount removed/disabled, $skippedCount not installed, $failCount failed." -ForegroundColor Cyan
    Write-Host "To restore all packages anytime, run: powershell -ExecutionPolicy Bypass -File tools\phone-restore.ps1 $List" -ForegroundColor Yellow
}
