# DeepSeek Harness Windows Launcher

This is the Windows companion package for the independent DeepSeek Harness macOS shell. It starts the official `@deepseek-ai/dsh` Web runtime and opens `http://127.0.0.1:<port>` in the default browser. It is not an official DeepSeek desktop application and it does not include the DSH runtime, API keys, profiles, browser sessions, or the macOS-only `dsh-mac-control` plugin.

## Requirements

- Windows 10 or Windows 11 x64
- Node.js 20 or newer
- A local DSH runtime containing `node_modules\@deepseek-ai\dsh\lib\bin.js`
- PowerShell 5.1 or PowerShell 7

## Install

Run `install.ps1` for a per-user install, or use the reviewed NSIS installer from a GitHub Release. If Windows blocks a downloaded script, use `Unblock-File .\install.ps1` or set `Set-ExecutionPolicy -Scope Process Bypass` for the current PowerShell window only. The installer writes only under `%LOCALAPPDATA%\DeepSeek Harness` and creates a Start Menu shortcut. It does not require administrator rights. The current workflow does not code-sign the executable; verify the published SHA-256 file before running it.

To prepare a Windows build machine and install the official runtime in one step, open PowerShell and run:

```powershell
Set-Location windows
& .\bootstrap-build-environment.ps1
```

The bootstrap uses `winget` to install Git, Node.js LTS, and NSIS. Reopen PowerShell if Windows has not refreshed `PATH`. Use `-SkipDshRuntime` when the runtime is managed elsewhere. The script does not install credentials or profiles.

## Configure the official runtime

From PowerShell:

```powershell
New-Item -ItemType Directory -Force "$HOME\dsh-runtime" | Out-Null
Set-Location "$HOME\dsh-runtime"
npm init -y
npm install @deepseek-ai/dsh@0.1.0-rc.7
node node_modules\@deepseek-ai\dsh\lib\bin.js web --port 3080
```

Install this repository's plugin into the DSH `web` profile using the commit-pinned archive command in the main tutorial. The plugin's browser and desktop tools are macOS-only; on Windows use the official DSH Web UI and Windows-native tools that you have separately reviewed.

## Start

```powershell
& "$env:LOCALAPPDATA\DeepSeek Harness\launch-dsh.ps1" -DshRuntime "$HOME\dsh-runtime" -Port 3080
```

The launcher waits for the local port, opens the browser, writes logs to `%LOCALAPPDATA%\DeepSeek Harness\logs`, and stops the child runtime when the launcher exits. Use `-NoBrowser` for headless startup and `-Profile ultimate` only when that profile has been explicitly installed and audited.

## Build release artifacts

On Windows with NSIS installed:

```powershell
Set-Location windows
& .\build-release.ps1 -Version 0.1.0
```

This creates a portable ZIP, an NSIS per-user installer, and a SHA-256 file. The GitHub Actions workflow performs the same build on a `windows-2025` runner.

Before running a downloaded artifact, compare its output with the matching
line in the `.sha256` file:

```powershell
Get-FileHash .\DeepSeek-Harness-Setup-v0.1.0-x64.exe -Algorithm SHA256
Get-Content .\DeepSeek-Harness-Windows-x64-v0.1.0.sha256
```

## Uninstall

```powershell
& "$env:LOCALAPPDATA\DeepSeek Harness\uninstall.ps1"
```

This removes the launcher and shortcut but leaves the separately managed DSH runtime and profile untouched.
