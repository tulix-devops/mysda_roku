<#
.SYNOPSIS
  Packages mySDAtv and sideloads it onto the dev Roku.

.DESCRIPTION
  Ported from wpa_live_roku/tools/deploy.ps1 (2026-10-06), without the App
  API key step - mySDAtv has no keyed API.

  No Node, no roku-deploy, no npm. The device's own dev web server does the
  whole job over HTTP and `curl` is the only tool needed
  (knowledge/dev-roku/node-free-deploy-and-capture-harness).

  1. THE ZIP IS BUILT ENTRY BY ENTRY, forcing '/' separators. Compress-Archive
     writes '\' and the device then rejects the package with a misleading
     "directory does not exist" error
     (knowledge/dev-roku/sideload-zip-needs-forward-slash-entries).

  2. THE FILE LIST IS EXPLICIT. .git, out/, docs/, tools/ and .env never ship
     (knowledge/dev-roku/scope-the-channel-package-explicitly). $Include is
     the whole contract for what ships.

.PARAMETER Verify
  Print the built zip's top-level entries before installing.
#>
[CmdletBinding()]
param(
    [string]$Target,
    [string]$Password,
    [switch]$Verify,
    [switch]$PackageOnly
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '_curlauth.ps1')
$root = Split-Path $PSScriptRoot -Parent

# -- credentials, from .env unless passed in ------------------------------
if (-not $Target -or -not $Password) {
    $envFile = Join-Path $root '.env'
    if (-not (Test-Path $envFile)) {
        throw "No .env at $envFile and no -Target/-Password given. .env needs ROKU_DEV_TARGET and ROKU_DEV_PASSWORD."
    }
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([A-Z_]+)\s*=\s*(.+?)\s*$') {
            if ($Matches[1] -eq 'ROKU_DEV_TARGET'   -and -not $Target)   { $Target   = $Matches[2] }
            if ($Matches[1] -eq 'ROKU_DEV_PASSWORD' -and -not $Password) { $Password = $Matches[2] }
        }
    }
}
if (-not $Target)   { throw 'ROKU_DEV_TARGET is not set.' }
if (-not $Password) { throw 'ROKU_DEV_PASSWORD is not set.' }

# -- what ships -----------------------------------------------------------
# Explicit path+filter pairs: PowerShell has no `**` wildcard, so a glob
# string silently matches one directory level only. Filters are
# case-insensitive on Windows (donation.PNG is caught by *.png).
$Include = @(
    @{ Path = 'manifest';   Filter = 'manifest'; Recurse = $false },
    @{ Path = 'source';     Filter = '*.brs';    Recurse = $true  },
    @{ Path = 'components'; Filter = '*.brs';    Recurse = $true  },
    @{ Path = 'components'; Filter = '*.xml';    Recurse = $true  },
    @{ Path = 'images';     Filter = '*.png';    Recurse = $true  },
    @{ Path = 'images';     Filter = '*.jpg';    Recurse = $true  },
    @{ Path = 'images';     Filter = '*.ttf';    Recurse = $true  }
)

$outDir = Join-Path $root 'out'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$zipPath = Join-Path $outDir 'mysdatv.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$files = New-Object System.Collections.Generic.List[string]
foreach ($spec in $Include) {
    $base = Join-Path $root $spec.Path
    if ($spec.Filter -eq 'manifest') {
        if (Test-Path $base) { $files.Add((Get-Item $base).FullName) }
        continue
    }
    if (-not (Test-Path $base)) { Write-Warning "include path missing: $($spec.Path)"; continue }
    $found = Get-ChildItem -Path $base -Filter $spec.Filter -File -Recurse:$spec.Recurse
    foreach ($f in $found) {
        if (-not $files.Contains($f.FullName)) { $files.Add($f.FullName) }
    }
}
if ($files.Count -eq 0) { throw "Nothing matched the include list under $root." }

foreach ($required in @('manifest', 'source/main.brs', 'components/sc/ScScene.xml', 'source/ScTheme.brs')) {
    $abs = Join-Path $root ($required -replace '/', '\')
    if (-not (Test-Path $abs)) { Write-Warning "expected file missing: $required"; continue }
    if (-not ($files -contains (Get-Item $abs).FullName)) {
        throw "Required file not in package: $required"
    }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($f in $files) {
        $rel = $f.Substring($root.Length + 1).Replace('\', '/')
        $entry = $zip.CreateEntry($rel)
        $es = $entry.Open()
        $fs = [System.IO.File]::OpenRead($f)
        $fs.CopyTo($es)
        $fs.Close(); $es.Close()
    }
} finally { $zip.Dispose() }

$size = (Get-Item $zipPath).Length
Write-Host ("packaged {0} files, {1:N0} bytes -> {2}" -f $files.Count, $size, $zipPath)

$z = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $bad = $z.Entries | Where-Object {
        $_.FullName -match '(^|/)\.git|node_modules|\.env$|\.env\.|(^|/)docs/|(^|/)out/|(^|/)tools/|(^|/)\.vscode/'
    }
    if ($bad) { throw "Package contains files that must not ship: $($bad.FullName -join ', ')" }
    $backslash = $z.Entries | Where-Object { $_.FullName -match '\\' }
    if ($backslash) { throw "Package has backslash entry names - the device will reject it." }
    if ($Verify) {
        Write-Host 'top-level entries:'
        $z.Entries | ForEach-Object { ($_.FullName -split '/')[0] } | Group-Object |
            ForEach-Object { "  {0,-12} {1}" -f $_.Name, $_.Count }
    }
} finally { $z.Dispose() }

if ($PackageOnly) { Write-Host 'package-only: not installing.'; exit 0 }

# -- install --------------------------------------------------------------
# The debug console is opened BEFORE the POST: the per-line compile errors go
# to telnet 8085 and nowhere else.
Write-Host "installing to $Target ..."

$console = $null; $reader = $null
try {
    $console = New-Object System.Net.Sockets.TcpClient
    $console.Connect($Target, 8085)
    $reader = New-Object System.IO.StreamReader($console.GetStream())
} catch {
    Write-Warning "could not open the debug console on 8085: $($_.Exception.Message)"
}

$authFile = New-CurlAuthFile -Password $Password
try {
    $response = & curl.exe -s --digest --config $authFile `
        -F 'mysubmit=Replace' -F "archive=@$zipPath" -F 'passwd=' `
        "http://$Target/plugin_install"
} finally {
    Remove-CurlAuthFile $authFile
}

$consoleLines = New-Object System.Collections.Generic.List[string]
if ($reader) {
    $stream = $console.GetStream()
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt 6) {
        if ($stream.DataAvailable) {
            $line = $reader.ReadLine()
            if ($null -ne $line) { $consoleLines.Add($line) }
        } else { Start-Sleep -Milliseconds 100 }
    }
    $console.Close()
}

# Success is matched FIRST, on the device's own phrases: its page renders
# every status line in red, success included.
if ($response -match 'Install Success|Identical to previous version') {
    Write-Host 'installed.' -ForegroundColor Green
    exit 0
}

if ($response -match 'Install Failure|Compile Failure|Failed to open') {
    $detail = [regex]::Matches($response, '<font color="red">(.*?)</font>') |
              ForEach-Object { $_.Groups[1].Value.Trim() } |
              Where-Object { $_ }
    Write-Host 'INSTALL FAILED' -ForegroundColor Red
    if ($detail) { $detail | ForEach-Object { Write-Host "  $_" -ForegroundColor Red } }
    else { Write-Host $response }
    $errors = $consoleLines | Where-Object {
        $_ -match 'compile error|Syntax Error|ERROR compiling|Found \d+ compile|unknown type|Error found at line|BS\d{4}'
    }
    if ($errors) {
        Write-Host ''
        Write-Host 'from the debug console (8085):' -ForegroundColor Red
        $errors | Select-Object -Unique | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    }
    exit 1
}

Write-Host 'Unrecognised response from the device - check it before trusting this:' -ForegroundColor Yellow
Write-Host $response
