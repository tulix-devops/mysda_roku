<#
.SYNOPSIS
  Generates source/ScBrand.brs: each channel's brand hue, sampled from its
  own logo, and whether the logo sits on white - so a logo card can be a
  gradient in the channel's colour with the logo on it (owner, 2026-10-28:
  "design the cards with the colour on a background, as we have on other
  Roku apps" - the WPALive / GreaterLove tone cards).

.DESCRIPTION
  Reads the three catalogue lists the channel shows (api/content/8, 9, 10),
  downloads every logo, and finds:
  * its dominant SATURATED hue: pixels that are near-white (most logos sit on
    white), near-black or grey are ignored; the rest vote into 24 hue bins
    weighted by saturation; the winning bin's circular mean (with its two
    neighbours) is the hue. Too little colour gives -1, and the card falls
    back to the hashed tone (ScToneFor in source/ScUi.brs).
  * whether its own background is white (its outer ring of pixels): such a
    logo sits on the card's white plate seamlessly; any other is drawn edge
    to edge, or the plate shows as a white rim round it (owner, 2026-10-28).

  Keyed by catalogue id. Re-run when channels or logos change.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web.Extensions
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root 'source\ScBrand.brs'
$api = 'https://sda.wchupload.tulix.net/api/content'
# The logo host answers 403 to a bare client (data-brief); send a Roku UA.
$ua = 'Roku/DVP-15.3 (mySDAtv build tool)'
$tmp = Join-Path ([IO.Path]::GetTempPath()) 'sc-brand'
if (-not (Test-Path $tmp)) { New-Item -ItemType Directory -Path $tmp | Out-Null }

function Get-Thumb([string]$path) {
    $src = [System.Drawing.Bitmap]::FromFile($path)
    $bmp = New-Object System.Drawing.Bitmap 56, 40
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.DrawImage($src, 0, 0, 56, 40)
    $g.Dispose(); $src.Dispose()
    return $bmp
}

function Get-BrandHue($bmp) {
    $bins = New-Object double[] 24
    $sx = New-Object double[] 24
    $sy = New-Object double[] 24
    $total = 0.0
    for ($y = 0; $y -lt 40; $y++) {
        for ($x = 0; $x -lt 56; $x++) {
            $c = $bmp.GetPixel($x, $y)
            if ($c.A -lt 128) { continue }
            $l = $c.GetBrightness(); $s = $c.GetSaturation()
            if ($l -gt 0.88 -or $l -lt 0.12 -or $s -lt 0.30) { continue }
            $h = $c.GetHue()
            $bin = [int][math]::Floor($h / 15.0) % 24
            $bins[$bin] += $s
            $rad = $h * [math]::PI / 180.0
            $sx[$bin] += [math]::Cos($rad) * $s
            $sy[$bin] += [math]::Sin($rad) * $s
            $total += $s
        }
    }
    # Too little colour to call it a brand colour.
    if ($total -lt 0.02 * 56 * 40) { return -1 }
    $best = 0
    for ($i = 1; $i -lt 24; $i++) { if ($bins[$i] -gt $bins[$best]) { $best = $i } }
    $cx = 0.0; $cy = 0.0
    foreach ($j in @((($best + 23) % 24), $best, (($best + 1) % 24))) { $cx += $sx[$j]; $cy += $sy[$j] }
    $deg = [math]::Atan2($cy, $cx) * 180.0 / [math]::PI
    if ($deg -lt 0) { $deg += 360 }
    return [int][math]::Round($deg) % 360
}

function Test-WhiteBg($bmp) {
    $n = 0; $white = 0
    for ($y = 0; $y -lt 40; $y++) {
        for ($x = 0; $x -lt 56; $x++) {
            if ($x -gt 1 -and $x -lt 54 -and $y -gt 1 -and $y -lt 38) { continue }
            $c = $bmp.GetPixel($x, $y)
            $n++
            if ($c.A -lt 128 -or ($c.GetBrightness() -gt 0.92 -and $c.GetSaturation() -lt 0.15)) { $white++ }
        }
    }
    return ($white / $n) -gt 0.85
}

$rows = @()
foreach ($list in @(8, 9, 10)) {
    # Invoke-RestMethod drops the API's 206 answers on PowerShell 5.1, and
    # ConvertFrom-Json rejects its empty "" key (attributes): the .NET
    # serializer takes both.
    $resp = Invoke-WebRequest -Uri "$api/$list/list?limit=200" -Headers @{ Accept = 'application/json' } -UseBasicParsing
    $body = [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $ser.MaxJsonLength = 16777216
    $json = $ser.DeserializeObject($body)
    foreach ($d in $json['data']) {
        $id = [string]$d['id']
        $title = ([string]$d['title']).Trim()
        $logo = [string]$d['images']['banner']
        if (-not $logo) { $logo = [string]$d['images']['poster'] }
        $hue = -1
        $white = $true
        if ($logo) {
            $file = Join-Path $tmp ('logo-' + $id + '.png')
            try {
                Invoke-WebRequest -Uri $logo -UserAgent $ua -OutFile $file -UseBasicParsing | Out-Null
                $bmp = Get-Thumb $file
                $hue = Get-BrandHue $bmp
                $white = Test-WhiteBg $bmp
                $bmp.Dispose()
            } catch { Write-Warning ('{0} {1}: {2}' -f $id, $title, $_.Exception.Message) }
        }
        $rows += [pscustomobject]@{ id = $id; title = $title; hue = $hue; white = $white }
        Write-Host ('  {0,3}  {1,-28} hue {2,4}  white bg {3}' -f $id, $title, $hue, $white)
    }
}

$lines = @()
foreach ($r in $rows) {
    $w = 'false'
    if ($r.white) { $w = 'true' }
    $lines += ('        "{0}": [{1}, {2}]   '' {3}' -f $r.id, $r.hue, $w, $r.title)
}
$pairs = $lines -join "`r`n"
$src = @"
' ============================================================================
' ScBrand.brs - GENERATED by tools/build-sc-brand.ps1. Do not edit by hand.
'
' Each channel's [brand hue, logo on white], sampled from its own logo:
' hue 0..359, or -1 where the logo has too little colour (the card then uses
' the hashed tone); true when the logo's own background is white.
' Keyed by catalogue id.
' ============================================================================

function ScBrandTable() as object
    if m.scBrandTable <> invalid then return m.scBrandTable
    m.scBrandTable = {
$pairs
    }
    return m.scBrandTable
end function
"@
[IO.File]::WriteAllText($out, $src.TrimEnd() + "`r`n", (New-Object System.Text.UTF8Encoding $false))
$noHue = @($rows | Where-Object { $_.hue -lt 0 }).Count
$dark = @($rows | Where-Object { -not $_.white }).Count
Write-Host ('brand -> {0} ({1} channels, {2} without a colour, {3} not on white)' -f $out, $rows.Count, $noHue, $dark)
