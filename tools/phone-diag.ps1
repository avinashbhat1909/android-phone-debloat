# Battery & Wake Lock Diagnostics for connected Android phone
param([string]$Serial)

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

$serialArgs = @()
if ($Serial) { $serialArgs = @('-s', $Serial) }

Write-Host "=== Current Battery State ===" -ForegroundColor Cyan
& $adb @serialArgs shell "dumpsys battery"

Write-Host "`n=== Active Wake Locks (Holding CPU Awake) ===" -ForegroundColor Cyan
& $adb @serialArgs shell "dumpsys power | grep -A 15 'Wake Locks:'"

Write-Host "`n=== Estimated Power Use Breakdown ===" -ForegroundColor Cyan
& $adb @serialArgs shell "dumpsys batterystats | grep -A 25 'Estimated power use'"
