<#
.SYNOPSIS
  Builds the C - Showcase design's generated UI assets into images/png/sc/:
  round-shape 9-patches, image corner caps, the soft card shadow, the
  capsule's nav glyphs, the player/button glyphs and the whole-logo lockup.

.DESCRIPTION
  Everything is white (or black for the shadow) with alpha only, tinted at
  runtime with blendColor, which MULTIPLIES. RGB is constant across each
  asset, including alpha-0 pixels, so device scaling never pulls in a rim
  (knowledge/dev-roku/ninepatch-borders-draw-at-device-pixels).

  9-PATCH CORNERS DRAW AT DEVICE PIXELS. On a 720p panel the FHD plane is
  scaled by 2/3 but a 9-patch's fixed border is not, so every round shape is
  generated twice: r<N>.9.png for a 1080p UI and r<N>_hd.9.png (radius x 2/3)
  for 720p. ScShape() in source/ScTheme.brs picks one per device.

  A pill of height h needs radius floor((h-1)/2)
  (knowledge/dev-roku/ninepatch-pill-radius-off-by-one).

  Glyph geometry is the Showcase boards' own SVG (docs/design/source/C1-Home.dc.html,
  a 40-unit grid, stroke 3), drawn at 8x and downscaled once.

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

$pngDir = Join-Path $Dest 'images\png'
$scDir  = Join-Path $pngDir 'sc'
if (-not (Test-Path $scDir)) { New-Item -ItemType Directory -Path $scDir -Force | Out-Null }
$logoSrc = Join-Path $pngDir 'mysdatv_logo.png'

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
# Every pixel the same RGB; only alpha varies (see the header).
function Set-Clear($bmp, [int]$r, [int]$g, [int]$b) {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) { $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, $r, $g, $b)) }
    }
}
function Set-Markers($bmp, [int]$m) {
    $mark = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
    $s = $bmp.Width
    $bmp.SetPixel($m, 0, $mark); $bmp.SetPixel(0, $m, $mark)
    $bmp.SetPixel($m, $s - 1, $mark); $bmp.SetPixel($s - 1, $m, $mark)
}

# Coverage of a quarter-disc corner, supersampled. inside = $true counts the
# disc (a filled round shape); $false counts outside it (corner caps).
function Get-Coverage([int]$x, [int]$y, [int]$r, [bool]$inside) {
    if ($x -eq $r -or $y -eq $r) { if ($inside) { return 255 } else { return 0 } }
    $cx = if ($x -lt $r) { $r } else { $r + 1 }
    $cy = if ($y -lt $r) { $r } else { $r + 1 }
    $ss = 8; $n = 0
    for ($sy = 0; $sy -lt $ss; $sy++) {
        for ($sx = 0; $sx -lt $ss; $sx++) {
            $px = $x + ($sx + 0.5) / $ss; $py = $y + ($sy + 0.5) / $ss
            $d = [math]::Sqrt(($px - $cx) * ($px - $cx) + ($py - $cy) * ($py - $cy))
            if ($inside) { if ($d -le $r) { $n++ } } else { if ($d -gt $r) { $n++ } }
        }
    }
    return [int][math]::Round(255 * $n / ($ss * $ss))
}

# A filled rounded shape: white, the four corners of radius r, a 1-px
# stretchable centre row and column.
function New-RoundPatch([int]$r, [string]$path) {
    $content = 2 * $r + 1
    $out = New-Bitmap ($content + 2) ($content + 2)
    Set-Clear $out 255 255 255
    for ($y = 0; $y -lt $content; $y++) {
        for ($x = 0; $x -lt $content; $x++) {
            $a = Get-Coverage $x $y $r $true
            if ($a -gt 0) { $out.SetPixel($x + 1, $y + 1, [System.Drawing.Color]::FromArgb($a, 255, 255, 255)) }
        }
    }
    Set-Markers $out ($r + 1)
    Save-Png $out $path
    $out.Dispose()
}

# Corner caps: white OUTSIDE the corner arcs, tinted to whatever lies behind
# a picture so its corners read round (knowledge/dev-roku/rounded-corners-on-images).
function New-CornerCaps([int]$r, [string]$path) {
    $content = 2 * $r + 1
    $out = New-Bitmap ($content + 2) ($content + 2)
    Set-Clear $out 255 255 255
    for ($y = 0; $y -lt $content; $y++) {
        for ($x = 0; $x -lt $content; $x++) {
            $a = Get-Coverage $x $y $r $false
            if ($a -gt 0) { $out.SetPixel($x + 1, $y + 1, [System.Drawing.Color]::FromArgb($a, 255, 255, 255)) }
        }
    }
    Set-Markers $out ($r + 1)
    Save-Png $out $path
    $out.Dispose()
}

# A soft drop shadow for a card of corner radius r: black, peak alpha at the
# card, falling off over $blur px. Drawn at the card's rect grown by $blur
# on every side (and nudged down by the caller).
function New-Shadow([int]$r, [int]$blur, [double]$peak, [string]$path, [int]$rgb = 0) {
    $half = $blur + $r
    $content = 2 * $half + 1
    $out = New-Bitmap ($content + 2) ($content + 2)
    Set-Clear $out $rgb $rgb $rgb
    $sigma = $blur / 2.6
    for ($y = 0; $y -lt $content; $y++) {
        for ($x = 0; $x -lt $content; $x++) {
            # Distance from the card's rounded rect (whose corner centre is
            # at (half, half) in this quadrant-symmetric patch).
            $px = [math]::Abs(($x + 0.5) - ($half + 0.5))
            $py = [math]::Abs(($y + 0.5) - ($half + 0.5))
            $qx = $px - ($half - $blur - $r) ; $qy = $py - ($half - $blur - $r)
            # The card edge sits $blur in from the patch edge.
            $ex = [math]::Max($qx, 0.0); $ey = [math]::Max($qy, 0.0)
            $d = [math]::Sqrt($ex * $ex + $ey * $ey) - $r
            if ($d -le 0) { $a = $peak } else { $a = $peak * [math]::Exp(-($d * $d) / (2 * $sigma * $sigma)) }
            $ai = [int][math]::Round(255 * $a)
            if ($ai -gt 0) { $out.SetPixel($x + 1, $y + 1, [System.Drawing.Color]::FromArgb($ai, $rgb, $rgb, $rgb)) }
        }
    }
    Set-Markers $out ($half + 1)
    Save-Png $out $path
    $out.Dispose()
}

# -- 1. Round shapes (pills, plates, circles), 1080p and 720p ----------------
# 2: progress bars (h 5-6)   7: logo badges   14: cards   17: 36-px pills
# 22: logo plates   26: 54-px chips   35: 72-px buttons and nav circles
# 51: the capsule
$radii = @(2, 7, 14, 17, 22, 26, 35, 51)
foreach ($r in $radii) {
    New-RoundPatch $r (Join-Path $scDir "r$r.9.png")
    $rh = [int][math]::Max(1, [math]::Floor($r * 2 / 3))
    New-RoundPatch $rh (Join-Path $scDir "r${r}_hd.9.png")
}
Write-Host ("round shapes -> {0} (r {1}, each with an _hd copy)" -f $scDir, ($radii -join ', '))

# Plain circles (not 9-patches: a fixed size scales with the plane like any
# picture): the player's -10 / +10 (76), play-pause (92) and the seek knob (26).
function New-Circle([int]$d, [string]$path) {
    $big = New-Bitmap ($d * 8) ($d * 8)
    Set-Clear $big 255 255 255
    $g = New-Graphics $big
    $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)), 0, 0, ($d * 8), ($d * 8))
    $g.Dispose()
    $small = Resize-Bitmap $big $d $d
    Save-Png $small $path
    $small.Dispose(); $big.Dispose()
}
foreach ($d in @(26, 76, 92)) { New-Circle $d (Join-Path $scDir "circle$d.png") }
Write-Host "circles      -> circle26, circle76, circle92"

# -- 2. Picture corner caps, 1080p and 720p -----------------------------------
foreach ($r in @(14, 18)) {
    New-CornerCaps $r (Join-Path $scDir "caps$r.9.png")
    New-CornerCaps ([int][math]::Floor($r * 2 / 3)) (Join-Path $scDir "caps${r}_hd.9.png")
}
Write-Host "corner caps  -> caps14, caps18 (+ _hd)"

# -- 2b. A focus ring: a hollow rounded frame of outer radius r, stroke s,
# drawn a few px OUTSIDE a card so it never meets the picture's corner caps
# (Catch-up focus option A, owner 2026-11-12).
function In-RoundRect([double]$px, [double]$py, [double]$x0, [double]$y0, [double]$x1, [double]$y1, [double]$r) {
    if ($px -lt $x0 -or $py -lt $y0 -or $px -gt $x1 -or $py -gt $y1) { return $false }
    $cx = [math]::Min([math]::Max($px, $x0 + $r), $x1 - $r)
    $cy = [math]::Min([math]::Max($py, $y0 + $r), $y1 - $r)
    return ((($px - $cx) * ($px - $cx) + ($py - $cy) * ($py - $cy)) -le $r * $r)
}
function New-RingPatch([int]$r, [int]$s, [string]$path) {
    $content = 2 * $r + 1
    $out = New-Bitmap ($content + 2) ($content + 2)
    Set-Clear $out 255 255 255
    $ss = 8
    for ($y = 0; $y -lt $content; $y++) {
        for ($x = 0; $x -lt $content; $x++) {
            $n = 0
            for ($sy = 0; $sy -lt $ss; $sy++) {
                for ($sx = 0; $sx -lt $ss; $sx++) {
                    $px = $x + ($sx + 0.5) / $ss; $py = $y + ($sy + 0.5) / $ss
                    if ((In-RoundRect $px $py 0 0 $content $content $r) -and -not (In-RoundRect $px $py $s $s ($content - $s) ($content - $s) ($r - $s))) { $n++ }
                }
            }
            $a = [int][math]::Round(255 * $n / ($ss * $ss))
            if ($a -gt 0) { $out.SetPixel($x + 1, $y + 1, [System.Drawing.Color]::FromArgb($a, 255, 255, 255)) }
        }
    }
    Set-Markers $out ($r + 1)
    Save-Png $out $path
    $out.Dispose()
}
New-RingPatch 21 4 (Join-Path $scDir 'ring21.9.png')
New-RingPatch 14 3 (Join-Path $scDir 'ring21_hd.9.png')
Write-Host "focus ring   -> ring21 (+ _hd): stroke 4"

# -- 3. The lifted card's shadow ----------------------------------------------
New-Shadow 14 36 0.70 (Join-Path $scDir 'shadow14.9.png')
New-Shadow 9 24 0.70 (Join-Path $scDir 'shadow14_hd.9.png')
Write-Host "shadow       -> shadow14 (+ _hd): blur 36 plane px"
# The focus splash: the same falloff in WHITE, tinted by alpha (owner,
# 2026-11-12: a white splash behind the focused card).
New-Shadow 14 30 0.80 (Join-Path $scDir 'glow14.9.png') 255
New-Shadow 9 20 0.80 (Join-Path $scDir 'glow14_hd.9.png') 255
Write-Host "glow         -> glow14 (+ _hd): white, blur 30 plane px"

# -- 4. Glyphs (the boards' SVG on a 40-unit grid) ----------------------------
$SS = 8
$WHITE = [System.Drawing.Color]::White
function pt([double]$x, [double]$y, [double]$u) { New-Object System.Drawing.PointF([single]($x * $u), [single]($y * $u)) }
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
function New-Glyph([string]$name, [scriptblock]$draw, [int]$size, [double]$stroke = 3.0) {
    $big = $size * $SS
    $bmp = New-Bitmap $big $big
    Set-Clear $bmp 255 255 255
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
    Save-Png $small (Join-Path $scDir "$name.png")
    $small.Dispose(); $bmp.Dispose(); $pen.Dispose(); $brush.Dispose()
}

# The capsule's five destinations, drawn at 36 px in a 72-px circle.
New-Glyph 'nav_home' {
    param($g, $pen, $brush, $u)
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 6 19 $u), (pt 20 7 $u), (pt 34 19 $u)))
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 10 16 $u), (pt 10 33 $u), (pt 30 33 $u), (pt 30 16 $u)))
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 17 33 $u), (pt 17 24 $u), (pt 23 24 $u), (pt 23 33 $u)))
} 36
New-Glyph 'nav_channels' {
    param($g, $pen, $brush, $u)
    $g.DrawPath($pen, (New-RoundedPath (5*$u) (12*$u) (30*$u) (20*$u) (3.5*$u)))
    $g.DrawLine($pen, (pt 14 36 $u), (pt 26 36 $u))
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 15 5 $u), (pt 20 11 $u), (pt 25 5 $u)))
} 36
New-Glyph 'nav_radio' {
    param($g, $pen, $brush, $u)
    $g.DrawPath($pen, (New-RoundedPath (4*$u) (14*$u) (32*$u) (21*$u) (3.5*$u)))
    $g.DrawEllipse($pen, [single](9*$u), [single](19*$u), [single](11*$u), [single](11*$u))
    $g.DrawLine($pen, (pt 25 21 $u), (pt 31 21 $u))
    $g.DrawLine($pen, (pt 25 27.5 $u), (pt 31 27.5 $u))
    $g.DrawLine($pen, (pt 9 14 $u), (pt 30 5 $u))
} 36
New-Glyph 'nav_catchup' {
    param($g, $pen, $brush, $u)
    $g.DrawArc($pen, [single](6*$u), [single](6*$u), [single](28*$u), [single](28*$u), 200, 290)
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 4.5 8 $u), (pt 6.6 15.3 $u), (pt 13.6 13 $u)))
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 20 12 $u), (pt 20 20 $u), (pt 26 23.5 $u)))
} 36
New-Glyph 'nav_account' {
    param($g, $pen, $brush, $u)
    $g.DrawEllipse($pen, [single](13.5*$u), [single](6*$u), [single](13*$u), [single](13*$u))
    $g.DrawArc($pen, [single](7*$u), [single](22.5*$u), [single](26*$u), [single](23*$u), 180, 180)
} 36

# Buttons and the player transport.
New-Glyph 'play' {
    param($g, $pen, $brush, $u)
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddPolygon([System.Drawing.PointF[]]@((pt 10 5 $u), (pt 35 20 $u), (pt 10 35 $u)))
    $g.FillPath($brush, $p)
} 24
New-Glyph 'pause' {
    param($g, $pen, $brush, $u)
    $g.FillPath($brush, (New-RoundedPath (9*$u) (6*$u) (8*$u) (28*$u) (2*$u)))
    $g.FillPath($brush, (New-RoundedPath (23*$u) (6*$u) (8*$u) (28*$u) (2*$u)))
} 24
New-Glyph 'restart' {
    param($g, $pen, $brush, $u)
    $g.DrawArc($pen, [single](7*$u), [single](7*$u), [single](26*$u), [single](26*$u), 210, 290)
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 6 9 $u), (pt 8.2 16.6 $u), (pt 15.6 14.4 $u)))
} 24 3.5
New-Glyph 'check' {
    param($g, $pen, $brush, $u)
    $g.DrawLines($pen, [System.Drawing.PointF[]]@((pt 8 21 $u), (pt 16 29 $u), (pt 32 11 $u)))
} 24 4.0
Write-Host "glyphs       -> nav_home, nav_channels, nav_radio, nav_catchup, nav_account, play, pause, restart, check"

# -- 5. The WHOLE logo, at the size it is drawn ------------------------------
# 144x75 at (12, 40) above the capsule (showcase.md). Never a crop of the
# lockup: the globe-only mark was rejected by the owner (2026-10-06).
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
$lw = 144; $lh = 75
# Fit the lockup inside 144x75 at its own aspect, centred: never stretched.
$scale = [math]::Min($lw / $bw, $lh / $bh)
$dw = [int][math]::Round($bw * $scale); $dh = [int][math]::Round($bh * $scale)
$big = New-Bitmap ($lw * 4) ($lh * 4)
Set-Clear $big 255 255 255
$g = New-Graphics $big
$g.DrawImage($logo, (New-Object System.Drawing.Rectangle([int](($lw - $dw) * 2), [int](($lh - $dh) * 2), ($dw * 4), ($dh * 4))),
    (New-Object System.Drawing.Rectangle($minx, $miny, $bw, $bh)), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$small = Resize-Bitmap $big $lw $lh
Save-Png $small (Join-Path $scDir 'logo_144.png')
$small.Dispose(); $big.Dispose(); $logo.Dispose()
Write-Host ("logo         -> logo_144.png (lockup {0}x{1} fitted as {2}x{3})" -f $bw, $bh, $dw, $dh)
