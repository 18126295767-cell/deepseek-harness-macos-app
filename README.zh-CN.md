# DeepSeek Harness macOS App

**把本地 DeepSeek Harness 变成像 Codex 一样可直接打开的桌面软件：服务留在 Mac 本机，工作流不必依赖浏览器。**

本仓库包含一个原生 AppKit/WebKit macOS 外壳，用于运行开源的
[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)。它会按需启动或
连接用户自行管理的本地 DSH 服务，并在原生 macOS 窗口中显示；外部链接才交给系统
浏览器，Harness 本身不会作为普通网页打开。

[English](README.md) · [上游与范围](UPSTREAM.md) · [许可证](LICENSE)

## 包含内容

- 原生 Swift AppKit 窗口和现有 DeepSeek Harness 视觉外壳。
- 一个可快速本地试用的 Apple Silicon `DeepSeekHarness.app` 预构建版本。
- 仅允许访问本地 Harness 地址（`127.0.0.1` / `localhost`）的 WebKit 视图。
- 按需启动本地 DSH 进程的 LaunchAgent 配置模板。
- 启动前检查 profile 的完整性，发现宿主 DSH 核心包的影子副本时安全停止。
- Windows 配套启动器，以及便携 ZIP 和 NSIS 发布目标。
- 中文 macOS 菜单、启动状态和错误提示。
- App 图标源文件和可复现构建脚本。

不包含：DeepSeek API 密钥、个人电话号码或邮箱、npm 依赖、用户会话、日志、私有
设置，也不包含之前的独立插件集合。请自行安装和配置 DSH 运行时。Windows 配套包只是
官方 Web runtime 的启动器，不是 macOS 专用原生控制插件的 Windows 移植版。

## 构建与安装

要求：Apple Silicon macOS 12 或更高版本、Xcode Command Line Tools、Node.js 22 或更高
版本，以及本地 DeepSeek Harness 运行时。

```bash
zsh ./scripts/build-app.sh \
  --dsh-runtime /绝对路径/dsh-runtime \
  --install
```

脚本会编译 Swift 外壳、生成 `DeepSeekHarness.app`，按照你提供的运行时路径生成当前
用户的 LaunchAgent，并安装到 `~/Applications/DeepSeek Harness.app`。它不会复制 API 密钥
或插件。

仅构建不安装：

```bash
zsh ./scripts/build-app.sh --dsh-runtime /绝对路径/dsh-runtime
```

本公开仓库采用标准源码目录：构建入口为 `scripts/build-app.sh`，Swift 源码位于
`App/DeepSeekHarnessApp`，LaunchAgent 模板位于 `packaging`。脚本仍兼容旧的扁平
导出布局。使用 `zsh` 调用，可以避免下载源码归档未保留可执行位时构建失败。

完整步骤见 [中文可复现构建教程](TUTORIAL.zh-CN.md)，英文教程见
[TUTORIAL.md](TUTORIAL.md)。

## Windows 配套环境

Windows 10/11 x64 通过 `windows/` 配套包支持。它启动 `@deepseek-ai/dsh` 并打开本地
Web UI，不宣称在 Windows 上提供 macOS 的 Automation/Accessibility 工具。在 Windows
构建机上先运行 `windows/bootstrap-build-environment.ps1`，再用
`windows/build-release.ps1` 生成便携 ZIP、NSIS 当前用户安装包和 SHA-256 校验文件。
GitHub Actions 会在真实的 `windows-2025` runner 上运行同样的构建并上传产物。

安装 Release 前请阅读 [Windows 指南](windows/README.zh-CN.md)，英文说明见
[Windows guide](windows/README.md)。

Windows 指南语言：[日本語](windows/README.ja.md) ·
[한국어](windows/README.ko.md) · [Español](windows/README.es.md) ·
[Français](windows/README.fr.md) · [Deutsch](windows/README.de.md) ·
[Português](windows/README.pt-BR.md) · [Русский](windows/README.ru.md) ·
[العربية](windows/README.ar.md) · [हिन्दी](windows/README.hi.md) ·
[繁體中文](windows/README.zh-TW.md)。

## 运行行为

只有本地服务就绪后，App 才会连接 `http://127.0.0.1:3080/`。关闭 App 会请求终止关联的
LaunchAgent 进程。外部链接交给系统浏览器，Harness 界面始终留在原生窗口内。

每次由 App 管理启动时，`profile-doctor.mjs` 都会把当前 profile 与实际 runtime 对照。
只要插件另装了一份宿主 `@deepseek-ai/dsh-*` 核心包，即使版本号相同也会被阻止，因为
Cordis 服务可能使用仅在当前物理副本中相同的 `Symbol`。检查器会指出冲突包和引入者，但
绝不自动删除文件。如果旧会话已经写入 `tool_calls` 却没有对应工具结果，请保留它作为
历史记录，并在新会话中重新发送任务，不要继续点击旧会话的“继续”。

## 上游归属与法律说明

本项目是基于 **DeepSeek AI** 开源的 **DeepSeek Harness** 开发的独立原生外壳，与
DeepSeek AI 没有隶属、赞助、代理或官方背书关系。上游项目仍按 MIT 协议独立授权；详见
[NOTICE](NOTICE) 与 [UPSTREAM.md](UPSTREAM.md)。

## 协议

本仓库中的 App 外壳和打包文件采用 [MIT License](LICENSE)。中文参考译文见
[LICENSE.zh-CN](LICENSE.zh-CN)；如有解释冲突，以英文 `LICENSE` 为准。
