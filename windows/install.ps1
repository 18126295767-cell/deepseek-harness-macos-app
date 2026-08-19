[CmdletBinding()]
param(
  [string]$InstallDirectory = "$env:LOCALAPPDATA\DeepSeek Harness"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$sourceDirectories = @(
  (Resolve-Path $PSScriptRoot).Path,
  (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)
$target = [IO.Path]::GetFullPath($InstallDirectory)
if ($sourceDirectories | Where-Object { $target.TrimEnd('\') -eq $_.TrimEnd('\') }) {
  throw "InstallDirectory must not be the source directory."
}
if ($target.TrimEnd('\') -eq [IO.Path]::GetPathRoot($target).TrimEnd('\')) {
  throw "InstallDirectory must not be a drive root."
}

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "launch-dsh.ps1") -Destination $target -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "launch-dsh.cmd") -Destination $target -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "uninstall.ps1") -Destination $target -Force
Get-ChildItem $PSScriptRoot -Filter "README*.md" -File | Copy-Item -Destination $target -Force
$licenseSource = Join-Path $PSScriptRoot "LICENSE"
if (-not (Test-Path $licenseSource -PathType Leaf)) {
  $licenseSource = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "LICENSE"
}
Copy-Item -LiteralPath $licenseSource -Destination $target -Force

$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\DeepSeek Harness"
New-Item -ItemType Directory -Force -Path $startMenu | Out-Null
$shortcutPath = Join-Path $startMenu "DeepSeek Harness.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $target "launch-dsh.cmd"
$shortcut.WorkingDirectory = $target
$shortcut.Description = "Start the local DeepSeek Harness Web runtime"
$shortcut.Save()

Write-Host "Installed Windows launcher to $target"
Write-Host "Start Menu shortcut: $shortcutPath"
Write-Host "The official DSH runtime must be installed separately."
