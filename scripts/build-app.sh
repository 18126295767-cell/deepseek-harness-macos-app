#!/bin/zsh
set -euo pipefail

usage() {
  print "Usage: $0 --dsh-runtime /absolute/path/to/dsh-runtime [--install] [--output /absolute/path]"
}

runtime=""
install_app=false
output=""
while (( $# > 0 )); do
  case "$1" in
    --dsh-runtime) runtime="${2:-}"; shift 2 ;;
    --install) install_app=true; shift ;;
    --output) output="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) print -u2 "Unknown argument: $1"; usage; exit 2 ;;
  esac
done

[[ -n "$runtime" ]] || { print -u2 "--dsh-runtime is required"; exit 2; }
runtime="${runtime:A}"
[[ -f "$runtime/node_modules/@deepseek-ai/dsh/lib/bin.js" ]] || {
  print -u2 "Cannot find @deepseek-ai/dsh/lib/bin.js under $runtime"; exit 1
}
node_bin="$(command -v node)"
[[ -x "$node_bin" ]] || { print -u2 "Node.js is required"; exit 1; }

script_dir="${0:A:h}"
if [[ -f "$script_dir/main.swift" ]]; then
  repo="$script_dir"
  source_dir="$script_dir"
  template="$script_dir/com.houxinran.deepseek-harness.plist.template"
else
  repo="$script_dir:h"
  source_dir="$repo/App/DeepSeekHarnessApp"
  template="$repo/packaging/com.houxinran.deepseek-harness.plist.template"
fi
output="${output:-$repo/build}"
output="${output:A}"
app="$output/DeepSeekHarness.app"
contents="$app/Contents"
mkdir -p "$contents/MacOS" "$contents/Resources"

swiftc -O -whole-module-optimization \
  -framework AppKit -framework WebKit \
  "$source_dir/main.swift" \
  -o "$contents/MacOS/DeepSeekHarness"
cp "$source_dir/Info.plist" "$contents/Info.plist"
cp "$source_dir/icon-source.svg" "$output/icon-source.svg"
if [[ -f "$source_dir/DeepSeekHarness.app/Contents/Resources/DeepSeekHarness.icns" ]]; then
  cp "$source_dir/DeepSeekHarness.app/Contents/Resources/DeepSeekHarness.icns" "$contents/Resources/DeepSeekHarness.icns"
else
  cp "$source_dir/DeepSeekHarness.icns" "$contents/Resources/DeepSeekHarness.icns"
fi

if $install_app; then
  app_dir="$HOME/Applications"
  target_app="$app_dir/DeepSeek Harness.app"
  mkdir -p "$app_dir"
  ditto "$app" "$target_app"
  launch_agents="$HOME/Library/LaunchAgents"
  logs="$HOME/Library/Logs"
  mkdir -p "$launch_agents" "$logs"
  plist="$launch_agents/com.houxinran.deepseek-harness.plist"
  sed -e "s|__NODE_BIN__|$node_bin|g" \
      -e "s|__DSH_BIN__|$runtime/node_modules/@deepseek-ai/dsh/lib/bin.js|g" \
      -e "s|__WORKING_DIRECTORY__|$runtime|g" \
      -e "s|__LOG_PATH__|$logs/DeepSeekHarness.log|g" \
      "$template" > "$plist"
  launchctl bootout "gui/$(id -u)/com.houxinran.deepseek-harness" 2>/dev/null || true
  print "Installed: $target_app"
  print "LaunchAgent: $plist"
else
  print "Built: $app"
fi
