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
- 中文 macOS 菜单、启动状态和错误提示。
- App 图标源文件和可复现构建脚本。

不包含：DeepSeek API 密钥、个人电话号码或邮箱、npm 依赖、用户会话、日志、私有
设置，也不包含之前的独立插件集合。请自行安装和配置 DSH 运行时。

## 构建与安装

要求：Apple Silicon macOS 12 或更高版本、Xcode Command Line Tools、Node.js 22 或更高
版本，以及本地 DeepSeek Harness 运行时。

```bash
./scripts/build-app.sh \
  --dsh-runtime /绝对路径/dsh-runtime \
  --install
```

脚本会编译 Swift 外壳、生成 `DeepSeekHarness.app`，按照你提供的运行时路径生成当前
用户的 LaunchAgent，并安装到 `~/Applications/DeepSeek Harness.app`。它不会复制 API 密钥
或插件。

仅构建不安装：

```bash
./scripts/build-app.sh --dsh-runtime /绝对路径/dsh-runtime
```

## 运行行为

只有本地服务就绪后，App 才会连接 `http://127.0.0.1:3080/`。关闭 App 会请求终止关联的
LaunchAgent 进程。外部链接交给系统浏览器，Harness 界面始终留在原生窗口内。

## 上游归属与法律说明

本项目是基于 **DeepSeek AI** 开源的 **DeepSeek Harness** 开发的独立原生外壳，与
DeepSeek AI 没有隶属、赞助、代理或官方背书关系。上游项目仍按 MIT 协议独立授权；详见
[NOTICE](NOTICE) 与 [UPSTREAM.md](UPSTREAM.md)。

## 协议

本仓库中的 App 外壳和打包文件采用 [MIT License](LICENSE)。中文参考译文见
[LICENSE.zh-CN](LICENSE.zh-CN)；如有解释冲突，以英文 `LICENSE` 为准。
