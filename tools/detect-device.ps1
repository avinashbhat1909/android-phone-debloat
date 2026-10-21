# Smart Device Auto-Detector & Unified Launcher
# Automatically detects connected phone model, matches against device profiles,
# checks bloatware status, and provides one-click actions.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\detect-device.ps1
#   powershell -ExecutionPolicy Bypass -File tools\detect-device.ps1 -DryRun
#   powershell -ExecutionPolicy Bypass -File tools\detect-device.ps1 -Apply
#   powershell -ExecutionPolicy Bypass -File tools\detect-device.ps1 -Backup
param(
    [switch]$Apply,
    [switch]$DryRun,
    [switch]$Backup,
    [switch]$Diag,
    [string]$Serial
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
$adb = Join-Path $repo 'tools\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { $adb = $adbCmd.Source } else { throw "ADB not found." }
}

$serialArgs = @()
if ($Serial) { $serialArgs = @('-s', $Serial) }

& $adb start-server *>$null
$connectedDevices = (& $adb @serialArgs devices) | Where-Object { $_ -match '\tdevice$' }
if (-not $connectedDevices) {
    Write-Host "No authorized Android device detected!" -ForegroundColor Red
    Write-Host "Please connect your phone, enable USB Debugging, and tap 'Allow' on screen." -ForegroundColor Yellow
    exit 1
}

# Collect device properties
$brand   = (& $adb @serialArgs shell getprop ro.product.brand).Trim()
$model   = (& $adb @serialArgs shell getprop ro.product.model).Trim()
$device  = (& $adb @serialArgs shell getprop ro.product.device).Trim()
$soc     = (& $adb @serialArgs shell getprop ro.soc.model).Trim()
$osVer   = (& $adb @serialArgs shell getprop ro.build.version.release).Trim()
$batRaw  = (& $adb @serialArgs shell "dumpsys battery") | Out-String
$batLvl  = if ($batRaw -match 'level:\s*(\d+)') { $matches[1] } else { '100' }
$batHlth = if ($batRaw -match 'health:\s*(\d+)') { $matches[1] } else { '2' }

$healthDesc = switch ($batHlth) {
    '2' { 'Good' }
    '3' { 'Overheat' }
    '4' { 'Dead' }
    '5' { 'Over Voltage' }
    default { 'Normal' }
}

# Auto-match profile directory in devices/
$devicesDir = Join-Path $repo 'devices'
$matchedProfile = $null
$matchedDirName = $null

if ($model -match 'V2561' -or $device -match 'V2561' -or $model -match 'PD2458' -or $device -match 'PD2458') {
    $matchedDirName = 'vivo-x200t'
} elseif ($model -match 'M2012K11I' -or $device -match 'haydn' -or $model -match '11X') {
    $matchedDirName = 'xiaomi-mi-11x-pro'
}

if ($matchedDirName) {
    $profilePath = Join-Path $devicesDir $matchedDirName
    if (Test-Path $profilePath) {
        $matchedProfile = $profilePath
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "           ANDROID PHONE DEBLOATER - AUTO DETECT            " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Brand & Model:   $brand $model ($device)" -ForegroundColor White
Write-Host "  SoC Platform:    $(if ($soc) { $soc } else { 'Standard SoC' })" -ForegroundColor White
Write-Host "  Android Version: Android $osVer" -ForegroundColor White
Write-Host "  Battery Level:   ${batLvl}% (Health: $healthDesc)" -ForegroundColor Green

if ($matchedProfile) {
    Write-Host "  Matched Profile: devices/$matchedDirName" -ForegroundColor Green
    $debloatList = Join-Path $matchedProfile 'debloat.txt'
    
    if (Test-Path $debloatList) {
        $pkgs = Get-Content $debloatList | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ } | ForEach-Object { ($_ -split '\s+')[0] }
        
        # Query currently installed (enabled + disabled) packages - NO -u flag
        $installedRaw = & $adb @serialArgs shell "pm list packages"
        $installedSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($line in $installedRaw) {
            $p = $line -replace '^package:', ''
            if ($p) { [void]$installedSet.Add($p.Trim()) }
        }
        
        # Query disabled packages
        $disabledRaw = & $adb @serialArgs shell "pm list packages -d"
        $disabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($line in $disabledRaw) {
            $p = $line -replace '^package:', ''
            if ($p) { [void]$disabledSet.Add($p.Trim()) }
        }
        
        $activeCount = 0
        $disabledCount = 0
        $cleanCount = 0
        foreach ($pkg in $pkgs) {
            if ($disabledSet.Contains($pkg)) {
                $disabledCount++
            } elseif ($installedSet.Contains($pkg)) {
                $activeCount++
            } else {
                $cleanCount++
            }
        }
        
        Write-Host "  Profile Status:  $($pkgs.Count) packages ($activeCount active, $disabledCount disabled, $cleanCount clean)" -ForegroundColor $(if ($activeCount -gt 0) { 'Yellow' } else { 'Green' })
    }
} else {
    Write-Host "  Matched Profile: (No exact profile matched; you can pass a custom list)" -ForegroundColor Yellow
}
Write-Host "============================================================`n" -ForegroundColor Cyan

# Action Dispatch
if ($Backup) {
    & (Join-Path $PSScriptRoot 'backup-packages.ps1') @serialArgs
    exit 0
}

if ($Diag) {
    & (Join-Path $PSScriptRoot 'phone-diag.ps1') @serialArgs
    exit 0
}

if ($DryRun) {
    if (-not $matchedProfile) { throw "No matched profile to dry run against." }
    & (Join-Path $PSScriptRoot 'phone-disable.ps1') (Join-Path $matchedProfile 'debloat.txt') -DryRun @serialArgs
    exit 0
}

if ($Apply) {
    if (-not $matchedProfile) { throw "No matched profile to apply." }
    $applyScript = Join-Path $matchedProfile 'apply-debloat.ps1'
    if (Test-Path $applyScript) {
        & $applyScript @serialArgs
    } else {
        & (Join-Path $PSScriptRoot 'phone-disable.ps1') (Join-Path $matchedProfile 'debloat.txt') @serialArgs
    }
    exit 0
}

# Interactive Menu if no flags passed
Write-Host "Available Actions:" -ForegroundColor White
Write-Host "  [1] Apply Debloat & Optimization (Recommended)" -ForegroundColor Green
Write-Host "  [2] Dry-Run / Preview (Audit without modifying phone)" -ForegroundColor Yellow
Write-Host "  [3] Pre-Flight Snapshot & Backup" -ForegroundColor Cyan
Write-Host "  [4] Run Battery & Wake Lock Diagnostics" -ForegroundColor Cyan
Write-Host "  [5] Configure AdGuard Private DNS" -ForegroundColor Cyan
Write-Host "  [Q] Quit`n" -ForegroundColor Gray

$choice = Read-Host "Select an option (1-5 or Q)"
switch ($choice) {
    '1' {
        $applyScript = Join-Path $matchedProfile 'apply-debloat.ps1'
        if (Test-Path $applyScript) {
            & $applyScript @serialArgs
        } else {
            & (Join-Path $PSScriptRoot 'phone-disable.ps1') (Join-Path $matchedProfile 'debloat.txt') @serialArgs
        }
    }
    '2' {
        & (Join-Path $PSScriptRoot 'phone-disable.ps1') (Join-Path $matchedProfile 'debloat.txt') -DryRun @serialArgs
    }
    '3' {
        & (Join-Path $PSScriptRoot 'backup-packages.ps1') @serialArgs
    }
    '4' {
        & (Join-Path $PSScriptRoot 'phone-diag.ps1') @serialArgs
    }
    '5' {
        & (Join-Path $PSScriptRoot 'set-dns.ps1') -Provider AdGuard @serialArgs
    }
    default {
        Write-Host "Exited without changes." -ForegroundColor Gray
    }
}
