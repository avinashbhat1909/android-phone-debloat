# Private DNS Switcher & Ad/Tracker Sinkhole Tool
# Configures system-wide native Android DNS-over-TLS via ADB (0% battery drain)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\set-dns.ps1 -Provider AdGuard
#   powershell -ExecutionPolicy Bypass -File tools\set-dns.ps1 -Provider Cloudflare
#   powershell -ExecutionPolicy Bypass -File tools\set-dns.ps1 -Provider Quad9
#   powershell -ExecutionPolicy Bypass -File tools\set-dns.ps1 -Provider Off
#   powershell -ExecutionPolicy Bypass -File tools\set-dns.ps1 -Status
param(
    [ValidateSet('AdGuard', 'Cloudflare', 'Quad9', 'Google', 'Off', 'Status')]
    [string]$Provider = 'Status',
    [string]$CustomHostname,
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
$devCheck = (& $adb @serialArgs get-state) 2>$null
if ($devCheck -notmatch 'device') {
    throw "Device not connected or not authorized! Run '& tools\platform-tools\adb.exe devices' to check."
}

$sdkVer = (& $adb @serialArgs shell getprop ro.build.version.sdk).Trim()
if ($sdkVer -and [int]$sdkVer -lt 28) {
    Write-Host "Warning: Native Private DNS (DNS-over-TLS) requires Android 9 (API 28) or newer." -ForegroundColor Yellow
    Write-Host "Your device is running API $sdkVer. Native Private DNS settings are not supported on Android 8 or older." -ForegroundColor Yellow
    Write-Host "Recommendation: Use a local DNS app such as Intra, RethinkDNS, or AdGuard on Android 8 and below." -ForegroundColor Gray
    exit 1
}

$providerMap = @{
    'AdGuard'    = 'dns.adguard-dns.com'
    'Cloudflare' = 'one.one.one.one'
    'Quad9'      = 'dns.quad9.net'
    'Google'     = 'dns.google'
}

if ($CustomHostname) {
    $targetHost = $CustomHostname
    $mode = 'hostname'
} elseif ($Provider -eq 'Off') {
    $targetHost = $null
    $mode = 'off'
} elseif ($Provider -eq 'Status') {
    $currentMode = (& $adb @serialArgs shell "settings get global private_dns_mode").Trim()
    $currentHost = (& $adb @serialArgs shell "settings get global private_dns_specifier").Trim()
    Write-Host "=== Current Private DNS Configuration ===" -ForegroundColor Cyan
    Write-Host "Mode:      $currentMode" -ForegroundColor Green
    Write-Host "Hostname:  $(if ($currentHost) { $currentHost } else { '(None - Unfiltered ISP)' })" -ForegroundColor Green
    exit 0
} else {
    $targetHost = $providerMap[$Provider]
    $mode = 'hostname'
}

Write-Host "=== Configuring Private DNS ($Provider) ===" -ForegroundColor Cyan

if ($mode -eq 'off') {
    & $adb @serialArgs shell "settings put global private_dns_mode off"
    & $adb @serialArgs shell "settings delete global private_dns_specifier" *>$null
    Write-Host "Private DNS turned OFF (Using standard network/ISP DNS)." -ForegroundColor Yellow
} else {
    & $adb @serialArgs shell "settings put global private_dns_mode hostname"
    & $adb @serialArgs shell "settings put global private_dns_specifier $targetHost"
    Write-Host "Private DNS successfully set to: $targetHost" -ForegroundColor Green
    Write-Host "Mode: DNS-over-TLS (Encrypted, 0% battery penalty)" -ForegroundColor Gray
}

# Verify
$verifyMode = (& $adb @serialArgs shell "settings get global private_dns_mode").Trim()
$verifyHost = (& $adb @serialArgs shell "settings get global private_dns_specifier").Trim()
Write-Host "`nVerification from device:" -ForegroundColor Cyan
Write-Host "  private_dns_mode:      $verifyMode" -ForegroundColor Green
Write-Host "  private_dns_specifier: $verifyHost" -ForegroundColor Green
