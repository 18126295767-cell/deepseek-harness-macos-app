# DeepSeek Harness macOS App

**A real desktop window for a local DeepSeek Harness: launch it like Codex, keep the service on your Mac, and leave the browser out of the workflow.**

This repository contains a small native AppKit/WebKit shell for the open-source
[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness). It starts
or reconnects to a user-managed local DSH service, displays it in a native
macOS window, and keeps external links in the system browser. The app itself
does not open the Harness as a normal web page.

[中文说明](README.zh-CN.md) · [上游与范围](UPSTREAM.md) · [许可证](LICENSE)

## Included

- Native Swift AppKit window with the existing DeepSeek Harness visual shell.
- A prebuilt Apple Silicon `DeepSeekHarness.app` for quick local testing.
- WebKit view restricted to the local Harness origin (`127.0.0.1` / `localhost`).
- LaunchAgent helper that starts the local DSH process on demand.
- A Windows companion launcher with portable ZIP and NSIS release targets.
- Chinese macOS menus and startup/error states.
- App icon source files and a reproducible build script.

Not included: DeepSeek API keys, personal phone or email information, npm
dependencies, user sessions, logs, private settings, or the separate plugin
collection. Install and configure the DSH runtime yourself. The Windows
companion is a launcher for the official Web runtime, not a Windows port of
the macOS-only native control plugin.

## Build and install

Requirements: Apple Silicon macOS 12 or newer, Xcode Command Line Tools, Node.js
22 or newer, and a local DeepSeek Harness installation.

```bash
zsh ./scripts/build-app.sh \
  --dsh-runtime /absolute/path/to/dsh-runtime \
  --install
```

The script compiles the Swift shell, creates `DeepSeekHarness.app`, generates a
per-user LaunchAgent with your actual runtime paths, and installs the app under
`~/Applications/DeepSeek Harness.app`. It does not copy API keys or plugins.

To build without installing:

```bash
zsh ./scripts/build-app.sh --dsh-runtime /absolute/path/to/dsh-runtime
```

The published repository uses the standard source tree: the build entry point
is `scripts/build-app.sh`, Swift sources are under `App/DeepSeekHarnessApp`, and
the LaunchAgent template is under `packaging`. The script also accepts the old
flat export layout for backward compatibility. Run it with `zsh` so the build
does not depend on an executable bit being preserved by an archive download.

See [TUTORIAL.md](TUTORIAL.md) for a complete reproducible setup and
[TUTORIAL.zh-CN.md](TUTORIAL.zh-CN.md) for the Chinese guide.

## Windows companion

Windows 10/11 x64 is supported through the `windows/` companion package. It
starts `@deepseek-ai/dsh` and opens the local Web UI; it does not claim to
provide macOS Automation/Accessibility tools on Windows. Prepare a Windows
machine with `windows/bootstrap-build-environment.ps1`, then build a portable
ZIP, an NSIS per-user installer, and SHA-256 manifest with
`windows/build-release.ps1`. The GitHub Actions workflow runs on a real
`windows-2025` runner and uploads the same artifacts.

Read the [Windows guide](windows/README.md) or
[中文 Windows 指南](windows/README.zh-CN.md) before installing a release.

## Runtime behavior

The app connects to `http://127.0.0.1:3080/` only after the local service is
ready. Closing the app requests termination of the associated LaunchAgent
process. External links are handed to the system browser, while the Harness UI
stays inside the native window.

## Attribution and legal notice

This is an independent native shell based on the open-source **DeepSeek Harness**
project by **DeepSeek AI**. It is not affiliated with, sponsored by, endorsed by,
or an official product of DeepSeek AI. The upstream project remains separately
licensed under MIT; see [NOTICE](NOTICE) and [UPSTREAM.md](UPSTREAM.md).

## License

The app shell and packaging files in this repository are released under the
[MIT License](LICENSE). A Chinese reference translation is provided in
[LICENSE.zh-CN](LICENSE.zh-CN); the English text controls in case of conflict.
