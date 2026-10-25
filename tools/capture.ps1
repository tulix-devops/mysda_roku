<#
.SYNOPSIS
  Drives the dev Roku over ECP and captures screenshots.

.EXAMPLE
  ./tools/capture.ps1 -Name 01-home
  ./tools/capture.ps1 -Keys Down,Down,Right -Name 02-live -Relaunch

.DESCRIPTION
  Input is ECP on port 8060; screenshots are the dev web server's
  /plugin_inspect then /pkgs/dev.jpg. Three things this wraps up so they are
  not re-learned each time:

  * A TINY dev.jpg MEANS THE CHANNEL IS NOT FOREGROUND, not that the API
    failed. /pkgs/dev.jpg answers HTTP 200 with a 35-byte "Error 404: Not
    Found" body whenever the dev channel is not the active app - saved under a
    .jpg name by a naive curl -o. Nothing about the exchange signals failure.
    This script fails loudly on anything under 1 KB.

  * /launch/dev ON AN ALREADY-RUNNING CHANNEL DOES NOT RESTART IT. It
    re-signals the running process, keeping whatever screen, focus and partial
    state it already had - so a scripted walk that relaunches between captures
    silently accumulates state from every screen it visited. -Relaunch sends
    Home FIRST, which is the only sequence that reliably lands on a known
    first screen.

  * A FOCUSED ON-SCREEN KEYBOARD SWALLOWS ECP KEYPRESSES AS TYPED TEXT. Once
    the Search screen holds focus, Up/Down/Left/Right/Select are taps on the
    keyboard grid, not focus movement. Drive through Search with -Lit, or send
    Back first to drop keyboard focus.

  All of the above from knowledge/dev-roku/node-free-deploy-and-capture-harness
  and verify-on-device-not-in-the-compiler.
#>
[CmdletBinding()]
param(
    [string[]]$Keys = @(),
    [string]$Lit,
    [string]$Name = 'capture',
    [string]$OutDir,
    [switch]$Relaunch,
    [double]$Settle = 1.2,
    [double]$KeyDelay = 0.35,
    [switch]$NoShot
)

$ErrorActionPreference = 'Stop'
# `powershell -File capture.ps1 -Keys Down,Select` hands the script ONE string,
# "Down,Select" - -File does not parse a comma list into an array - and the
# device silently ignores a key by that name. Split it here, so the list form
# works however the script was started.
$Keys = @($Keys | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
. (Join-Path $PSScriptRoot '_curlauth.ps1')
$root = Split-Path $PSScriptRoot -Parent
if (-not $OutDir) { $OutDir = Join-Path $root 'docs\team\tasks\2026-10-06-wpalive-design-port\screenshots' }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$Target = $null; $Password = $null
Get-Content (Join-Path $root '.env') | ForEach-Object {
    if ($_ -match '^\s*([A-Z_]+)\s*=\s*(.+?)\s*$') {
        if ($Matches[1] -eq 'ROKU_DEV_TARGET')   { $Target   = $Matches[2] }
        if ($Matches[1] -eq 'ROKU_DEV_PASSWORD') { $Password = $Matches[2] }
    }
}
if (-not $Target)   { throw 'ROKU_DEV_TARGET is not set in .env.' }
if (-not $Password) { throw 'ROKU_DEV_PASSWORD is not set in .env.' }

# Credential in a short-lived owner-only file, never on the command line -
# see tools/_curlauth.ps1.

# -X POST rather than `-d ''`: PowerShell DROPS an empty-string argument when
# calling a native executable, so `-d ''` reaches curl as a bare `-d` and curl
# then eats the URL as its data payload - failing with "no URL specified" while
# the surrounding script carries on and captures a screenshot of whatever was
# already on screen.
function Send-Key([string]$k) {
    & curl.exe -s -X POST "http://${Target}:8060/keypress/$k" | Out-Null
    Start-Sleep -Seconds $KeyDelay
}

if ($Relaunch) {
    # Home FIRST. See the header: /launch/dev alone does not reset anything.
    Send-Key 'Home'
    Start-Sleep -Seconds 2
    & curl.exe -s -X POST "http://${Target}:8060/launch/dev" | Out-Null
    Start-Sleep -Seconds 6
}

foreach ($k in $Keys) { Send-Key $k }

if ($Lit) {
    foreach ($ch in $Lit.ToCharArray()) {
        $enc = [System.Uri]::EscapeDataString([string]$ch)
        & curl.exe -s -X POST "http://${Target}:8060/keypress/Lit_$enc" | Out-Null
        Start-Sleep -Milliseconds 400
    }
}

if ($NoShot) { Write-Host 'keys sent, no capture requested.'; exit 0 }

Start-Sleep -Seconds $Settle

$dest = Join-Path $OutDir "$Name.jpg"
$authFile = New-CurlAuthFile -Password $Password
try {
    # Two steps: trigger the capture, then fetch it.
    & curl.exe -s --digest --config $authFile -F 'mysubmit=Screenshot' `
        "http://$Target/plugin_inspect" | Out-Null
    Start-Sleep -Milliseconds 600
    & curl.exe -s --digest --config $authFile -o $dest "http://$Target/pkgs/dev.jpg"
} finally {
    Remove-CurlAuthFile $authFile
}

if (-not (Test-Path $dest)) { throw "No file was written to $dest." }
$size = (Get-Item $dest).Length
if ($size -lt 1024) {
    $body = Get-Content $dest -Raw
    Remove-Item $dest -Force
    throw "Capture is $size bytes - the channel is not the foreground app. Device said: $body"
}
Write-Host ("captured {0} ({1:N0} bytes)" -f $dest, $size)
