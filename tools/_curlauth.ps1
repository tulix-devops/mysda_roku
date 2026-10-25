<#
  Shared credential handling for the two scripts that talk to the device's dev
  web server. Dot-sourced, not run.

  WHY NOT `curl -u rokudev:<pw>`: that puts the password in the child process's
  command line, and on Windows any process in the same session can read another
  process's command line (`Get-CimInstance Win32_Process`). Digest auth protects
  the credential on the wire and does nothing for it sitting in the process
  table for the life of every call.

  WHY NOT `--config -` ON STDIN: that would be better still - nothing on disk at
  all - but Windows' bundled curl (8.21.0, the one in System32) rejects it with
  "option --config: found an unknown config option" regardless of the config's
  content, line endings or quoting. The same bytes in a FILE authenticate
  correctly, so the stdin path is simply not available here.

  So: a config file with a random name, owner-only ACL and inheritance broken,
  written and deleted inside a try/finally. Not perfect - it is on disk for the
  length of one request - but it is not enumerable from another process, which
  is the exposure that actually matters on a shared workstation.
#>

function New-CurlAuthFile {
    param([Parameter(Mandatory)][string]$Password)

    $path = Join-Path ([System.IO.Path]::GetTempPath()) ("amx-" + [guid]::NewGuid().ToString('N') + ".cfg")
    Set-Content -Path $path -Value ('user = "rokudev:' + $Password + '"') -Encoding ascii

    $acl = Get-Acl $path
    # Break inheritance and drop the inherited ACEs, then grant this user only.
    $acl.SetAccessRuleProtection($true, $false)
    $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        $me, 'FullControl', 'Allow')))
    Set-Acl -Path $path -AclObject $acl

    return $path
}

function Remove-CurlAuthFile {
    param([string]$Path)
    if ($Path -and (Test-Path $Path)) { Remove-Item $Path -Force -ErrorAction SilentlyContinue }
}
