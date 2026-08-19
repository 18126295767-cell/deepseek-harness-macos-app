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

本公开仓库采用 GitHub 网页上传形成的根目录扁平结构。请把构建脚本、Swift 源码、
plist、图标和 LaunchAgent 模板保持在仓库根目录，并在该目录执行：

```bash
zsh ./build-app.sh \
  --dsh-runtime /绝对路径/dsh-runtime \
  --output ./build
```

输出为 `build/DeepSeekHarness.app`。脚本会编译 `main.swift`、复制 plist 和图标，不会
修改 DSH 运行时。

通过 `zsh` 调用脚本，不依赖 GitHub 网页上传可能未保留的可执行权限。同一脚本也能
自动识别本地开发所用的标准嵌套源码目录。

## 4. 安装和启动

```bash
zsh ./build-app.sh \
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

## 故障排查

启动失败时检查日志和运行时路径：

```bash
tail -100 "$HOME/Library/Logs/DeepSeekHarness.log"
test -x "$(command -v node)"
test -f /绝对路径/dsh-runtime/node_modules/@deepseek-ai/dsh/lib/bin.js
```

如果 3080 端口已被占用，请停止冲突的本地服务，或同时修改 App 外壳和 LaunchAgent。不要
把其他用户的绝对路径写进公开提交。
