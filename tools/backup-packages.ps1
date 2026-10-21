# Pre-Flight Backup & Snapshot Tool for Android Debloating
# Inspired by Universal Android Debloater (UAD-ng) Snapshots
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\backup-packages.ps1
#   powershell -ExecutionPolicy Bypass -File tools\backup-packages.ps1 -Serial <device-id>
param(
    [string]$Serial,
    [string]$OutputDir
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
$devCheck = (& $adb @serialArgs get-state) 2>$null
if ($devCheck -notmatch 'device') {
    throw "Device not connected or not authorized! Run '& tools\platform-tools\adb.exe devices' to check."
}

# Fetch Device Identity
$brand = (& $adb @serialArgs shell getprop ro.product.brand).Trim()
$model = (& $adb @serialArgs shell getprop ro.product.model).Trim()
$osVer = (& $adb @serialArgs shell getprop ro.build.version.release).Trim()
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$sanitizedModel = ($model -replace '[^a-zA-Z0-9_\-]', '_').ToLower()

if (-not $OutputDir) {
    $backupRoot = Join-Path $repo 'backup'
    $OutputDir = Join-Path $backupRoot "${sanitizedModel}_${timestamp}"
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "=== Taking Pre-Flight Device Snapshot ===" -ForegroundColor Cyan
Write-Host "Device: $brand $model (Android $osVer)" -ForegroundColor Green
Write-Host "Destination: $OutputDir`n" -ForegroundColor Gray

# 1. Dump all installed packages with APK paths
Write-Host "Saving all installed packages with APK paths... " -NoNewline
$allPkgs = & $adb @serialArgs shell "pm list packages -f -u"
$allPkgsPath = Join-Path $OutputDir "packages_all.txt"
$allPkgs | Out-File -FilePath $allPkgsPath -Encoding utf8
Write-Host "OK ($(($allPkgs | Measure-Object).Count) packages)" -ForegroundColor Green

# 2. Dump disabled packages
Write-Host "Saving currently disabled packages... " -NoNewline
$disabledPkgs = & $adb @serialArgs shell "pm list packages -d"
$disabledPkgsPath = Join-Path $OutputDir "packages_disabled.txt"
$disabledPkgs | Out-File -FilePath $disabledPkgsPath -Encoding utf8
Write-Host "OK ($(($disabledPkgs | Measure-Object).Count) disabled)" -ForegroundColor Green

# 3. Dump active user profiles
Write-Host "Saving multi-user profiles... " -NoNewline
$users = & $adb @serialArgs shell "pm list users"
$usersPath = Join-Path $OutputDir "users.txt"
$users | Out-File -FilePath $usersPath -Encoding utf8
Write-Host "OK" -ForegroundColor Green

# 4. Dump system props & battery state
Write-Host "Saving device metadata & battery status... " -NoNewline
$props = & $adb @serialArgs shell "getprop"
$props | Out-File -FilePath (Join-Path $OutputDir "getprop.txt") -Encoding utf8
$battery = & $adb @serialArgs shell "dumpsys battery"
$battery | Out-File -FilePath (Join-Path $OutputDir "battery.txt") -Encoding utf8
Write-Host "OK" -ForegroundColor Green

# 5. Generate a 1-click restore script inside the backup folder
$restoreScriptPath = Join-Path $OutputDir "restore-snapshot.ps1"
$restoreScriptContent = @"
# 1-Click Restore Script for Snapshot Taken on $(Get-Date)
param([string]`$Serial)

`$adb = '$adb'
`$serialArgs = @()
if (`$Serial) { `$serialArgs = @('-s', `$Serial) }

Write-Host "=== Restoring Snapshot to $model ===" -ForegroundColor Cyan
`$packagesFile = Join-Path `$PSScriptRoot 'packages_all.txt'
if (-not (Test-Path `$packagesFile)) { throw "Snapshot file not found: `$packagesFile" }

`$lines = Get-Content `$packagesFile
`$restored = 0
foreach (`$line in `$lines) {
    if (`$line -match 'package:(.*?)=([a-zA-Z0-9_\.]+)') {
        `$pkg = `$matches[2]
        `$res = & `$adb @serialArgs shell "cmd package install-existing `$pkg" 2>&1
        if (`$res -match 'installed for user') {
            Write-Host "Restored: `$pkg" -ForegroundColor Green
            `$restored++
        }
    }
}
Write-Host "`nRestore complete. `$restored packages re-installed." -ForegroundColor Cyan
"@

$restoreScriptContent | Out-File -FilePath $restoreScriptPath -Encoding utf8

Write-Host "`nSnapshot successfully created at: $OutputDir" -ForegroundColor Green
Write-Host "To restore this exact state anytime, run: powershell -ExecutionPolicy Bypass -File `"$restoreScriptPath`"" -ForegroundColor Yellow
