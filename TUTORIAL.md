# Reproducible Build Tutorial

This tutorial builds the native shell from source and connects it to a local
DeepSeek Harness runtime. It does not fetch or embed API keys, plugins, user
sessions, or logs.

## 1. Requirements

- Apple Silicon Mac with macOS 12 or later
- Xcode Command Line Tools (`xcode-select --install`)
- Node.js 22 or later
- A local DSH runtime with `@deepseek-ai/dsh/lib/bin.js`

Verify the tools:

```bash
swiftc --version
node --version
```

## 2. Prepare the runtime

Install DeepSeek Harness separately and record its absolute runtime directory.
For an existing local runtime:

```bash
cd /absolute/path/to/dsh-runtime
test -f node_modules/@deepseek-ai/dsh/lib/bin.js
```

Configure your provider and API key in the runtime's own settings. Never put
credentials in this repository, a commit, a screenshot, or an issue report.

## 3. Build

This published repository uses a flat root layout created by GitHub's web
uploader. Keep the build script, Swift source, plist, icon, and LaunchAgent
template together at the repository root. From that root, run:

```bash
zsh ./build-app.sh \
  --dsh-runtime /absolute/path/to/dsh-runtime \
  --output ./build
```

The output is `build/DeepSeekHarness.app`. The script compiles `main.swift`,
copies the plist and icon, and does not modify the DSH runtime.

Calling the script through `zsh` avoids relying on the executable bit, which a
GitHub web upload may not preserve. The same script also detects the standard
nested source layout used by local development checkouts.

## 4. Install and launch

```bash
zsh ./build-app.sh \
  --dsh-runtime /absolute/path/to/dsh-runtime \
  --install
open "$HOME/Applications/DeepSeek Harness.app"
```

The LaunchAgent is generated at
`~/Library/LaunchAgents/com.houxinran.deepseek-harness.plist`; logs go to
`~/Library/Logs/DeepSeekHarness.log`.

## 5. Verify reproducibility

Check that the generated app is an Apple Silicon executable and that its plist
is valid:

```bash
file build/DeepSeekHarness.app/Contents/MacOS/DeepSeekHarness
plutil -lint build/DeepSeekHarness.app/Contents/Info.plist
```

A successful verification reports a Mach-O 64-bit arm64 executable and an
`OK` result from `plutil`.

The app should connect only to `http://127.0.0.1:3080/`. External links should
open in the system browser. If the local service is not ready, the app shows a
Chinese startup status and retries before presenting the log location.

## Troubleshooting

If startup fails, inspect the log and validate the runtime path:

```bash
tail -100 "$HOME/Library/Logs/DeepSeekHarness.log"
test -x "$(command -v node)"
test -f /absolute/path/to/dsh-runtime/node_modules/@deepseek-ai/dsh/lib/bin.js
```

If port 3080 is occupied, stop the conflicting local service or adapt the App
shell and LaunchAgent together. Do not hard-code another user's path into a
public commit.
