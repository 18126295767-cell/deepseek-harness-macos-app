[CmdletBinding()]
param(
  [string]$InstallDirectory = "$env:LOCALAPPDATA\DeepSeek Harness"
)

$ErrorActionPreference = "Stop"
$target = [IO.Path]::GetFullPath($InstallDirectory)
$shortcutPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\DeepSeek Harness\DeepSeek Harness.lnk"
if (Test-Path $shortcutPath) { Remove-Item -LiteralPath $shortcutPath -Force }
$shortcutDirectory = Split-Path $shortcutPath -Parent
if (Test-Path $shortcutDirectory) { Remove-Item -LiteralPath $shortcutDirectory -Force }
if (Test-Path $target) { Remove-Item -LiteralPath $target -Recurse -Force }
Write-Host "Removed the Windows launcher. The DSH runtime and profile were not deleted."
