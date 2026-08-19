# 可复现构建教程

本教程从源码构建原生 macOS 外壳，并将它连接到本地 DeepSeek Harness 运行时。
它不会获取或嵌入 API 密钥、插件、用户会话或日志。

## 1. 环境要求

- Apple Silicon Mac，macOS 12 或更高版本
- Xcode Command Line Tools（可执行 `xcode-select --install`）
- Node.js 22 或更高版本
- 一个包含 `@deepseek-ai/dsh/lib/bin.js` 的本地 DSH 运行时

检查工具：

```bash
swiftc --version
node --version
```

## 2. 准备运行时

请单独安装 DeepSeek Harness，并记录运行时目录的绝对路径。已有本地运行时可执行：

```bash
cd /绝对路径/dsh-runtime
test -f node_modules/@deepseek-ai/dsh/lib/bin.js
```

请在运行时自己的设置中配置模型供应商和 API 密钥。不要把凭据放进本仓库、提交记录、
截图或 issue。

## 3. 构建

本公开仓库采用标准嵌套源码目录。在仓库根目录执行：

```bash
zsh ./scripts/build-app.sh \
  --dsh-runtime /绝对路径/dsh-runtime \
  --output ./build
```

输出为 `build/DeepSeekHarness.app`。脚本会编译 `main.swift`、复制 plist 和图标，不会
修改 DSH 运行时。

通过 `zsh` 调用脚本，不依赖源码归档可能未保留的可执行位。同一脚本仍会
自动识别旧的扁平导出布局，以保持向后兼容。

## 4. 安装和启动

```bash
zsh ./scripts/build-app.sh \
  --dsh-runtime /绝对路径/dsh-runtime \
  --install
open "$HOME/Applications/DeepSeek Harness.app"
```

LaunchAgent 会生成到
`~/Library/LaunchAgents/com.houxinran.deepseek-harness.plist`，日志位于
`~/Library/Logs/DeepSeekHarness.log`。

## 5. 验证可复现性

检查生成的 App 是 Apple Silicon 可执行文件，并确认 plist 有效：

```bash
file build/DeepSeekHarness.app/Contents/MacOS/DeepSeekHarness
plutil -lint build/DeepSeekHarness.app/Contents/Info.plist
```

验证成功时，`file` 应显示 Mach-O 64 位 arm64 可执行文件，`plutil` 应返回 `OK`。

App 应只连接 `http://127.0.0.1:3080/`；外部链接应交给系统浏览器。若本地服务尚未就绪，
App 会显示中文启动状态并重试，失败后提示日志位置。

## 6. Windows 配套环境

Windows 包是官方 DSH Web runtime 的独立启动器。它不包含 runtime 或凭据，也不会把
仅适用于 macOS 的 `dsh-mac-control` 工具变成 Windows 工具。环境要求是 Windows 10/11
x64、PowerShell 5.1 或 7，以及用于准备环境的 `winget`。

从源码目录准备 Windows 构建机：

```powershell
Set-Location windows
& .\bootstrap-build-environment.ps1
```

该脚本通过 `winget` 安装 Git、Node.js LTS 和 NSIS，并在 `$HOME\dsh-runtime` 创建单独的
`@deepseek-ai/dsh@0.1.0-rc.7` runtime。给 Windows `web` profile 添加插件前，请先审阅
主仓库教程中的提交固定命令。安装器改变 `PATH` 后请重新打开 PowerShell。

在 Windows 上构建发布产物：

```powershell
& .\build-release.ps1 -Version 0.1.0
```

输出包括 `DeepSeek-Harness-Windows-x64-v0.1.0.zip`、
`DeepSeek-Harness-Setup-v0.1.0-x64.exe` 和 `.sha256` 校验文件。NSIS 安装器按当前用户
安装，不要求管理员权限。便携包包含 `launch-dsh.cmd`、`launch-dsh.ps1`、安装/卸载脚本、
两份 Windows 指南和 MIT 协议。

启动已安装的启动器：

```powershell
& "$env:LOCALAPPDATA\DeepSeek Harness\launch-dsh.ps1" `
  -DshRuntime "$HOME\dsh-runtime" -Port 3080
```

它会等待 `127.0.0.1:3080` 就绪、打开默认浏览器，把日志写入
`%LOCALAPPDATA%\DeepSeek Harness\logs`，并在启动器退出时停止子 DSH 进程。无头启动可用
`-NoBrowser`。GitHub Actions 会在 `windows-2025` runner 上调用同一个
`windows/build-release.ps1`，并上传 ZIP、安装器和哈希文件。

## 故障排查

启动失败时检查日志和运行时路径：

```bash
tail -100 "$HOME/Library/Logs/DeepSeekHarness.log"
test -x "$(command -v node)"
test -f /绝对路径/dsh-runtime/node_modules/@deepseek-ai/dsh/lib/bin.js
```

如果 3080 端口已被占用，请停止冲突的本地服务，或同时修改 App 外壳和 LaunchAgent。不要
把其他用户的绝对路径写进公开提交。

Windows 出错时检查 `%LOCALAPPDATA%\DeepSeek Harness\logs`，确认 runtime 目录中存在
`node_modules\@deepseek-ai\dsh\lib\bin.js`，构建安装器失败时确认 NSIS 已安装。不要把
macOS 的 LaunchAgent 或 `osascript` 命令复制到 Windows 脚本中。
