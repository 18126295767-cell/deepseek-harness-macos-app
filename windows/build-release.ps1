[CmdletBinding()]
param(
  [string]$Version = "0.1.0",
  [string]$OutputDirectory = ""
)

$ErrorActionPreference = "Stop"
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
  throw "This release script must run on Windows."
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
  throw "Version must use numeric major.minor.patch format."
}

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$output = if ($OutputDirectory) { [IO.Path]::GetFullPath($OutputDirectory) } else { Join-Path $repo "releases" }
$stage = Join-Path $output "DeepSeek-Harness-Windows-x64"
New-Item -ItemType Directory -Force -Path $output | Out-Null
if (Test-Path $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Copy-Item (Join-Path $PSScriptRoot "launch-dsh.ps1") $stage -Force
Copy-Item (Join-Path $PSScriptRoot "launch-dsh.cmd") $stage -Force
Copy-Item (Join-Path $PSScriptRoot "install.ps1") $stage -Force
Copy-Item (Join-Path $PSScriptRoot "uninstall.ps1") $stage -Force
Copy-Item (Join-Path $PSScriptRoot "README.md") $stage -Force
Copy-Item (Join-Path $PSScriptRoot "README.zh-CN.md") $stage -Force
Copy-Item (Join-Path $PSScriptRoot "bootstrap-build-environment.ps1") $stage -Force
Copy-Item (Join-Path $repo "LICENSE") $stage -Force

$zip = Join-Path $output "DeepSeek-Harness-Windows-x64-v$Version.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal

$zipCheck = Join-Path $env:TEMP ("dsh-app-zip-" + [guid]::NewGuid().ToString("N"))
try {
  Expand-Archive -LiteralPath $zip -DestinationPath $zipCheck
  foreach ($required in @(
    "launch-dsh.ps1",
    "launch-dsh.cmd",
    "install.ps1",
    "uninstall.ps1",
    "README.md",
    "README.zh-CN.md",
    "LICENSE"
  )) {
    if (-not (Test-Path -LiteralPath (Join-Path $zipCheck $required))) {
      throw "The portable archive is missing $required."
    }
  }
} finally {
  if (Test-Path -LiteralPath $zipCheck) { Remove-Item -LiteralPath $zipCheck -Recurse -Force }
}

$makensis = Get-Command makensis.exe -ErrorAction SilentlyContinue
if ($null -eq $makensis) {
  $candidates = @(
    (Join-Path ${env:ProgramFiles(x86)} "NSIS\makensis.exe"),
    (Join-Path $env:ProgramFiles "NSIS\makensis.exe")
  ) | Where-Object { $_ -and (Test-Path $_) }
  if ($candidates.Count -gt 0) { $makensis = Get-Command $candidates[0] }
}
if ($null -eq $makensis) { throw "NSIS is required to build the installer. Install NSIS or build only the portable ZIP." }

$installer = Join-Path $output "DeepSeek-Harness-Setup-v$Version-x64.exe"
if (Test-Path $installer) { Remove-Item -LiteralPath $installer -Force }
& $makensis.Source "/DVERSION=$Version" "/DSTAGE_DIR=$stage" "/DOUT_FILE=$installer" (Join-Path $PSScriptRoot "installer.nsi")
if (-not (Test-Path $installer)) { throw "NSIS installer was not produced." }

$hashFile = Join-Path $output "DeepSeek-Harness-Windows-x64-v$Version.sha256"
@($zip, $installer) | ForEach-Object {
  "{0}  {1}" -f (Get-FileHash -Algorithm SHA256 -LiteralPath $_).Hash.ToLowerInvariant(), ([IO.Path]::GetFileName($_))
} | Set-Content -LiteralPath $hashFile -Encoding ascii

Remove-Item -LiteralPath $stage -Recurse -Force

Write-Host "Built Windows artifacts:"
Write-Host "  $zip"
Write-Host "  $installer"
Write-Host "  $hashFile"
