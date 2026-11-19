<#
  Reads the dev Roku's BrightScript console (port 8085) for -Seconds and
  appends it to -Out. Run it in the background while driving the device.
#>
param([string]$Target = '192.168.0.106', [int]$Seconds = 30, [string]$Out)
$c = New-Object System.Net.Sockets.TcpClient
$c.Connect($Target, 8085)
$s = $c.GetStream()
$s.ReadTimeout = 500
$buf = New-Object byte[] 65536
$sb = New-Object System.Text.StringBuilder
$end = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $end) {
    try {
        $n = $s.Read($buf, 0, $buf.Length)
        if ($n -gt 0) { [void]$sb.Append([System.Text.Encoding]::UTF8.GetString($buf, 0, $n)) }
    } catch { }
}
$c.Close()
$text = $sb.ToString()
if ($Out) { Add-Content -Path $Out -Value $text -Encoding utf8 } else { $text }
