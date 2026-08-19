[CmdletBinding()]
param(
  [string]$InstallDirectory = "$env:LOCALAPPDATA\DeepSeek Harness"
)

$ErrorActionPreference = "Stop"
$source = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$target = [IO.Path]::GetFullPath($InstallDirectory)
if ($target.TrimEnd('\') -eq $source.TrimEnd('\')) {
  throw "InstallDirectory must not be the source directory."
}

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "launch-dsh.ps1") -Destination $target -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "launch-dsh.cmd") -Destination $target -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "README.md") -Destination $target -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "README.zh-CN.md") -Destination $target -Force -ErrorAction SilentlyContinue

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
