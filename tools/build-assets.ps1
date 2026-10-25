<#
.SYNOPSIS
  Builds mySDAtv's generated UI assets for the WPALive-derived design:
  rail glyphs, the accent focus glow, the navy ground and its left fade,
  corner caps, the top-bar logo and the rail mark.

.DESCRIPTION
  Ported 2026-10-06 from wpa_live_roku/tools/build-assets.ps1 (the Tulix Roku
  engine's asset pipeline). The COLOURS are mySDAtv's own, sampled from the
  logo (images/png/mysdatv_logo.png): the globe's cyan ring #17C1EE is the
  accent, the globe's navy the ground, "my" red is LIVE, "SDA" gold the
  highlight. Keep in step with SdPalette() in source/SdTheme.brs.

  ENGINE-COPIED, NOT GENERATED (taken as-is from wpa_live_roku/images/ on
  2026-10-06, colour-neutral white shapes tinted at runtime): images/fonts/*
  (Manrope, Inter), shapes/pill_r3..r29.9.png, flat_white.png,
  ramp_diag.png, edge_fade_left.png, fade_top/bottom/right.png, and the
  nav glyphs account.png and search.png.

  GLYPHS are stroked at 8x on a 40-unit grid and downscaled once
  (knowledge/dev-roku/image-sharpness-pipeline), pure white with alpha,
  because blendColor MULTIPLIES.

.NOTES
  Re-runnable. Overwrites what it generates and nothing else.
#>
[CmdletBinding()]
param([string]$Dest = '')

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$here = $PSScriptRoot
if (-not $here) { $here = Split-Path $MyInvocation.MyCommand.Path -Parent }
if (-not $Dest) { $Dest = Split-Path $here -Parent }

# The ONE accent (keep in step with cAccent in source/SdTheme.brs).
$ACCENT = [System.Drawing.ColorTranslator]::FromHtml('#17C1EE')
$WHITE  = [System.Drawing.Color]::White

$pngDir   = Join-Path $Dest 'images\png'
$navDir   = Join-Path $pngDir 'nav'
$brandDir = Join-Path $pngDir 'brand'
$shapeDir = Join-Path $pngDir 'shapes'
$groundDir = Join-Path $pngDir 'ground'
$logoSrc  = Join-Path $pngDir 'mysdatv_logo.png'
foreach ($d in @($navDir, $brandDir, $shapeDir, $groundDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Save-Png($bmp, [string]$path) { $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png) }
function New-Bitmap([int]$w, [int]$h) {
    New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
}
function New-Graphics($bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    return $g
}
function Resize-Bitmap($src, [int]$w, [int]$h) {
    $dst = New-Bitmap $w $h
    $g = New-Graphics $dst
    $g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)))
    $g.Dispose()
    return $dst
}
function pt([double]$x, [double]$y, [double]$u) {
    New-Object System.Drawing.PointF([single]($x * $u), [single]($y * $u))
}
function New-RoundedPath([double]$x, [double]$y, [double]$w, [double]$h, [double]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = [single]($r * 2)
    $p.AddArc([single]$x, [single]$y, $d, $d, 180, 90)
    $p.AddArc([single]($x + $w - $d), [single]$y, $d, $d, 270, 90)
    $p.AddArc([single]($x + $w - $d), [single]($y + $h - $d), $d, $d, 0, 90)
    $p.AddArc([single]$x, [single]($y + $h - $d), $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# -- 1. Rail glyphs -----------------------------------------------------------
$SS = 8
function New-Glyph([string]$name, [scriptblock]$draw, [double]$stroke = 3.0, [int]$size = 40) {
    $big = $size * $SS
    $bmp = New-Bitmap $big $big
    $g = New-Graphics $bmp
    $u = [double]$big / 40.0
    $pen = New-Object System.Drawing.Pen($WHITE, [single]($stroke * $u))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $brush = New-Object System.Drawing.SolidBrush($WHITE)
    & $draw $g $pen $brush $u
    $g.Dispose()
    $small = Resize-Bitmap $bmp $size $size
    Save-Png $small (Join-Path $navDir "$name.png")
    $small.Dispose(); $bmp.Dispose(); $pen.Dispose(); $brush.Dispose()
}

# Television: a TV - rounded screen, a stand, two antenna strokes (the
# engine's "channels" glyph).
New-Glyph 'tv' {
    param($g, $pen, $brush, $u)
    $g.DrawPath($pen, (New-RoundedPath (5*$u) (12*$u) (30*$u) (20*$u) (3.5*$u)))
    $g.DrawLine($pen, (pt 14 36 $u), (pt 26 36 $u))
    $g.DrawLine($pen, (pt 15 5 $u), (pt 20 11 $u))
    $g.DrawLine($pen, (pt 25 5 $u), (pt 20 11 $u))
}

# Television Languages: a globe - the outline, the central meridian as an
# ellipse, the equator and two parallels. The logo's own globe, in a stroke.
New-Glyph 'languages' {
    param($g, $pen, $brush, $u)
    $g.DrawEllipse($pen, [single](5*$u), [single](5*$u), [single](30*$u), [single](30*$u))
    $g.DrawEllipse($pen, [single](13*$u), [single](5*$u), [single](14*$u), [single](30*$u))
    $g.DrawLine($pen, (pt 5 20 $u), (pt 35 20 $u))
    $g.DrawLine($pen, (pt 8 12.5 $u), (pt 32 12.5 $u))
    $g.DrawLine($pen, (pt 8 27.5 $u), (pt 32 27.5 $u))
}

# DVR: a clock face with a counter-clockwise arrow - "watch what you missed".
New-Glyph 'dvr' {
    param($g, $pen, $brush, $u)
    $g.DrawArc($pen, [single](6*$u), [single](6*$u), [single](28*$u), [single](28*$u), 200, 290)
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 4.5 8 $u), (pt 6.6 15.3 $u), (pt 13.6 13 $u)))
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 20 12 $u), (pt 20 20 $u), (pt 26 23.5 $u)))
}

# Radios: a radio - the body, a speaker on the left, two tuning lines on the
# right, and the aerial.
New-Glyph 'radio' {
    param($g, $pen, $brush, $u)
    $g.DrawPath($pen, (New-RoundedPath (4*$u) (14*$u) (32*$u) (21*$u) (3.5*$u)))
    $g.DrawEllipse($pen, [single](9*$u), [single](19*$u), [single](11*$u), [single](11*$u))
    $g.DrawLine($pen, (pt 25 21 $u), (pt 31 21 $u))
    $g.DrawLine($pen, (pt 25 27.5 $u), (pt 31 27.5 $u))
    $g.DrawLine($pen, (pt 9 14 $u), (pt 30 5 $u))
}
Write-Host "rail glyphs -> $navDir (tv, languages, dvr, radio; account is engine-copied)"

# -- 2. The focused tile's soft glow -------------------------------------------
# A halo with the accent baked in, faded in over the card on focus. Every
# pixel is the accent's RGB, only alpha varies: the device filters RGB and
# alpha separately when scaling a 9-patch, and mixed pixels draw a bright
# rim. Borders draw at DEVICE px, so one asset per panel: g30 (1080p), g20
# (720p).
function New-GlowFrame([int]$G, [string]$path, $Tint = $ACCENT) {
    $band = 9; $rIn = 9
    $content = 2 * ($G + $band + $rIn) + 1
    $size = $content + 2
    $c = ($content - 1) / 2.0
    $holeHalf = $c - $G - $band + 0.5
    $reach = $band + $G
    $peak = 0.62
    $ss = 4
    $out = New-Bitmap $size $size
    for ($y = 0; $y -lt $content; $y++) {
        for ($x = 0; $x -lt $content; $x++) {
            $glow = 0.0
            for ($sy = 0; $sy -lt $ss; $sy++) {
                for ($sx = 0; $sx -lt $ss; $sx++) {
                    $px = [math]::Abs($x + ($sx + 0.5) / $ss - 0.5 - $c)
                    $py = [math]::Abs($y + ($sy + 0.5) / $ss - 0.5 - $c)
                    $qx = $px - ($holeHalf - $rIn); $qy = $py - ($holeHalf - $rIn)
                    $dH = [math]::Sqrt([math]::Pow([math]::Max($qx, 0), 2) + [math]::Pow([math]::Max($qy, 0), 2)) + [math]::Min([math]::Max($qx, $qy), 0) - $rIn
                    if ($dH -ge 0) {
                        $t = [math]::Min(1.0, $dH / $reach)
                        $s = $t * $t * (3 - 2 * $t)
                        $glow += $peak * [math]::Pow(1.0 - $s, 1.8)
                    }
                }
            }
            $a = [int][math]::Round(255 * $glow / ($ss * $ss))
            $out.SetPixel($x + 1, $y + 1, [System.Drawing.Color]::FromArgb($a, $Tint.R, $Tint.G, $Tint.B))
        }
    }
    $mark = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
    $m = [int]$c + 1
    $out.SetPixel($m, 0, $mark); $out.SetPixel(0, $m, $mark)
    $out.SetPixel($m, $size - 1, $mark); $out.SetPixel($size - 1, $m, $mark)
    Save-Png $out $path
    $out.Dispose()
}
New-GlowFrame 30 (Join-Path $shapeDir 'glow_frame_g30.9.png')
New-GlowFrame 20 (Join-Path $shapeDir 'glow_frame_g20.9.png')
# Palettes with their own focus colour get their own glow, suffixed by name
# (theme gGlow20 / gGlow30). Keep in step with SdPalette() cAccent.
$ACCENTS = [ordered]@{ myred = '#F0262B' }
foreach ($an in $ACCENTS.Keys) {
    $tint = [System.Drawing.ColorTranslator]::FromHtml($ACCENTS[$an])
    New-GlowFrame 30 (Join-Path $shapeDir "glow_frame_g30_$an.9.png") $tint
    New-GlowFrame 20 (Join-Path $shapeDir "glow_frame_g20_$an.9.png") $tint
}
Write-Host "glow frame  -> $shapeDir\glow_frame_g30 / g20 .9.png (#17C1EE, plus $($ACCENTS.Keys -join ', '))"

# -- 3. The ground: the globe's navy, lit from the top left ---------------------
# 960x540 stretched to the plane, dithered. c2 MUST equal the palette's
# cGround: it fills most of the page and tints the corner caps.
$GROUNDS = [ordered]@{
    sdanavy = @{ c0 = @(0x0E, 0x3A, 0x6E); c1 = @(0x08, 0x24, 0x48); c2 = @(0x04, 0x14, 0x2B) }
    myred   = @{ c0 = @(0x1F, 0x2A, 0x44); c1 = @(0x14, 0x1C, 0x30); c2 = @(0x0B, 0x12, 0x22) }
}
$SPOT = @{ cx = 0.12 * 1920; cy = -0.05 * 1080; rx = 0.75 * 1920; ry = 0.85 * 1080 }
function Get-SpotColour($P, [double]$x, [double]$y) {
    $dx = ($x - $SPOT.cx) / $SPOT.rx; $dy = ($y - $SPOT.cy) / $SPOT.ry
    $t = [math]::Min(1.0, [math]::Sqrt($dx * $dx + $dy * $dy))
    if ($t -lt 0.45) { $a = $P.c0; $b = $P.c1; $u = $t / 0.45 } else { $a = $P.c1; $b = $P.c2; $u = ($t - 0.45) / 0.55 }
    $u = $u * $u * (3 - 2 * $u)
    return @(($a[0] + ($b[0] - $a[0]) * $u), ($a[1] + ($b[1] - $a[1]) * $u), ($a[2] + ($b[2] - $a[2]) * $u))
}
function Save-Argb([int]$w, [int]$h, [byte[]]$buf, [string]$path) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
    $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, $bmp.PixelFormat)
    [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $data.Scan0, $buf.Length)
    $bmp.UnlockBits($data)
    Save-Png $bmp $path
    $bmp.Dispose()
}
function New-GroundPalette([string]$name, $P, [string]$dir) {
    $rnd = New-Object System.Random(7)
    $w = 960; $h = 540
    $buf = New-Object byte[] ($w * $h * 4)
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $c = Get-SpotColour $P (($x + 0.5) * 2) (($y + 0.5) * 2)
            $i = ($y * $w + $x) * 4
            $buf[$i]     = [byte][math]::Max(0, [math]::Min(255, [math]::Floor($c[2] + $rnd.NextDouble())))
            $buf[$i + 1] = [byte][math]::Max(0, [math]::Min(255, [math]::Floor($c[1] + $rnd.NextDouble())))
            $buf[$i + 2] = [byte][math]::Max(0, [math]::Min(255, [math]::Floor($c[0] + $rnd.NextDouble())))
            $buf[$i + 3] = 255
        }
    }
    Save-Argb $w $h $buf (Join-Path $dir "$name.png")
    # The left-edge fade under the collapsed rail, in the ground's own colours.
    $w = 150; $h = 1080
    $buf = New-Object byte[] ($w * $h * 4)
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $c = Get-SpotColour $P ($x + 0.5) ($y + 0.5)
            $t = $x / ($w - 1.0); $s = $t * $t * (3 - 2 * $t)
            $i = ($y * $w + $x) * 4
            $buf[$i]     = [byte][math]::Round($c[2])
            $buf[$i + 1] = [byte][math]::Round($c[1])
            $buf[$i + 2] = [byte][math]::Round($c[0])
            $buf[$i + 3] = [byte][math]::Round(255 * [math]::Pow([math]::Max(0.0, 1.0 - $s), 0.6))
        }
    }
    Save-Argb $w $h $buf (Join-Path $dir "${name}_fade_left.png")
}
foreach ($gn in $GROUNDS.Keys) { New-GroundPalette $gn $GROUNDS[$gn] $groundDir }
Write-Host "ground      -> $groundDir ($($GROUNDS.Keys -join ', '), plus _fade_left)"

# -- 4. Corner caps: only the four wedges outside a radius-9 arc -------------
function New-CornerCaps([int]$r, [string]$path) {
    $content = 2 * $r + 1
    $size = $content + 2
    $ss = 8
    $out = New-Bitmap $size $size
    for ($y = 0; $y -lt $content; $y++) {
        for ($x = 0; $x -lt $content; $x++) {
            if ($x -eq $r -or $y -eq $r) { continue }
            $cxp = if ($x -lt $r) { $r } else { $r + 1 }
            $cyp = if ($y -lt $r) { $r } else { $r + 1 }
            $outside = 0
            for ($sy = 0; $sy -lt $ss; $sy++) {
                for ($sx = 0; $sx -lt $ss; $sx++) {
                    $px = $x + ($sx + 0.5) / $ss; $py = $y + ($sy + 0.5) / $ss
                    $d = [math]::Sqrt(($px - $cxp) * ($px - $cxp) + ($py - $cyp) * ($py - $cyp))
                    if ($d -gt $r) { $outside++ }
                }
            }
            $a = [int][math]::Round(255 * $outside / ($ss * $ss))
            if ($a -gt 0) { $out.SetPixel($x + 1, $y + 1, [System.Drawing.Color]::FromArgb($a, 255, 255, 255)) }
        }
    }
    $mark = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
    $m = $r + 1
    $out.SetPixel($m, 0, $mark); $out.SetPixel(0, $m, $mark)
    $out.SetPixel($m, $size - 1, $mark); $out.SetPixel($size - 1, $m, $mark)
    Save-Png $out $path
    $out.Dispose()
}
New-CornerCaps 9 (Join-Path $shapeDir 'corners_r9.9.png')
Write-Host "corners     -> $shapeDir\corners_r9.9.png"

# -- 5. Brand: the top-bar logo and the rail mark -----------------------------
# Both cut from the transparent logo (mysdatv_logo.png, 540x405 with air
# round it). The lockup's bounding box is found from the alpha channel, so a
# re-exported logo needs no hand-measured crop. Each is authored AT the size
# it is drawn, so it resamples exactly once.
if (-not (Test-Path $logoSrc)) { throw "No logo at $logoSrc" }
$logo = [System.Drawing.Bitmap]::FromFile($logoSrc)
$minx = $logo.Width; $miny = $logo.Height; $maxx = -1; $maxy = -1
for ($y = 0; $y -lt $logo.Height; $y++) {
    for ($x = 0; $x -lt $logo.Width; $x++) {
        if ($logo.GetPixel($x, $y).A -gt 16) {
            if ($x -lt $minx) { $minx = $x }; if ($x -gt $maxx) { $maxx = $x }
            if ($y -lt $miny) { $miny = $y }; if ($y -gt $maxy) { $maxy = $y }
        }
    }
}
$bw = $maxx - $minx + 1; $bh = $maxy - $miny + 1

# Top bar: the full lockup at 108 px tall (a multiple of 3: 72 device px on
# the 720p panel), width from its own aspect, rounded to a multiple of 3.
$topH = 108
$topW = [int]([math]::Round($bw * $topH / $bh / 3.0) * 3)
$top = New-Bitmap $topW $topH
$g = New-Graphics $top
$g.DrawImage($logo, (New-Object System.Drawing.Rectangle(0, 0, $topW, $topH)),
    (New-Object System.Drawing.Rectangle($minx, $miny, $bw, $bh)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
Save-Png $top (Join-Path $brandDir 'wordmark_top.png')
$top.Dispose()
Write-Host "wordmark    -> $brandDir\wordmark_top.png (${topW}x${topH})"

# Rail mark: the globe, a circle cut from the lockup's middle. The globe is
# the widest run of navy-blue columns; the circle takes its ring too.
$cols = @()
for ($x = 0; $x -lt $logo.Width; $x++) {
    $n = 0
    for ($y = 0; $y -lt $logo.Height; $y++) {
        $c = $logo.GetPixel($x, $y)
        if ($c.A -gt 200 -and $c.B -gt ($c.R + 40) -and $c.R -lt 80) { $n++ }
    }
    if ($n -gt 40) { $cols += $x }
}
$gx0 = ($cols | Measure-Object -Minimum).Minimum; $gx1 = ($cols | Measure-Object -Maximum).Maximum
$gcx = ($gx0 + $gx1) / 2.0
$gcy = ($miny + $maxy) / 2.0
# The globe proper, inside its ring: the full ring's box takes a slice of
# the "t" of "tv" at its right edge.
$gs = [int](($gx1 - $gx0) * 0.84)
foreach ($ms in @(60, 240)) {
    $big = $ms * 4
    $bmp = New-Bitmap $big $big
    $g = New-Graphics $bmp
    $clip = New-Object System.Drawing.Drawing2D.GraphicsPath
    $clip.AddEllipse(0, 0, $big, $big)
    $g.SetClip($clip)
    $g.DrawImage($logo, (New-Object System.Drawing.Rectangle(0, 0, $big, $big)),
        (New-Object System.Drawing.Rectangle([int]($gcx - $gs / 2), [int]($gcy - $gs / 2), $gs, $gs)),
        [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $small = Resize-Bitmap $bmp $ms $ms
    Save-Png $small (Join-Path $brandDir "mark_$ms.png")
    $small.Dispose(); $bmp.Dispose()
}
$logo.Dispose()
Write-Host "mark        -> $brandDir\mark_60.png, mark_240.png (the globe)"
