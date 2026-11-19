# Writes a capture's pixels as raw RGBA for decode-qr.js: an 8-byte header
# (uint32 LE width, height) then R,G,B,A per pixel. Optional crop x,y,w,h.
# (The buffer is $px: PowerShell names are case-blind, so $out IS $Out.)
param([string]$In, [string]$Out, [int]$X = 0, [int]$Y = 0, [int]$W = 0, [int]$H = 0)
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile((Resolve-Path $In))
if ($W -le 0) { $W = $src.Width; $H = $src.Height }
$bmp = $src.Clone((New-Object System.Drawing.Rectangle $X, $Y, $W, $H), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$src.Dispose()
$data = $bmp.LockBits((New-Object System.Drawing.Rectangle 0, 0, $W, $H), 'ReadOnly', [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$bytes = New-Object byte[] ($data.Stride * $H)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$stride = $data.Stride
$bmp.UnlockBits($data); $bmp.Dispose()
$px = New-Object byte[] (8 + $W * $H * 4)
[BitConverter]::GetBytes([uint32]$W).CopyTo($px, 0)
[BitConverter]::GetBytes([uint32]$H).CopyTo($px, 4)
$o = 8
for ($r = 0; $r -lt $H; $r++) {
    $row = $r * $stride
    for ($c = 0; $c -lt $W; $c++) {
        $i = $row + $c * 4
        # GDI+ stores BGRA.
        $px[$o] = $bytes[$i + 2]; $px[$o + 1] = $bytes[$i + 1]; $px[$o + 2] = $bytes[$i]; $px[$o + 3] = 255
        $o += 4
    }
}
[IO.File]::WriteAllBytes($Out, $px)
