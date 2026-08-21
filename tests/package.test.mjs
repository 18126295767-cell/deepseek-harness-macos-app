import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function pngDimensions(file) {
  const bytes = fs.readFileSync(file);
  assert.deepEqual([...bytes.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
  return { width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) };
}

test('macOS and Windows packages include the profile doctor', () => {
  const buildScript = fs.readFileSync(path.join(root, 'scripts', 'build-app.sh'), 'utf8');
  const launchAgent = fs.readFileSync(path.join(root, 'packaging', 'com.houxinran.deepseek-harness.plist.template'), 'utf8');
  const windowsBuild = fs.readFileSync(path.join(root, 'windows', 'build-release.ps1'), 'utf8');
  const windowsLauncher = fs.readFileSync(path.join(root, 'windows', 'launch-dsh.ps1'), 'utf8');

  assert.match(buildScript, /profile-doctor\.mjs/);
  assert.match(launchAgent, /__DOCTOR_SCRIPT__/);
  assert.match(launchAgent, /__ERROR_MARKER__/);
  assert.match(windowsBuild, /profile-doctor\.mjs/);
  assert.match(windowsLauncher, /profile-doctor\.mjs/);
  assert.equal(fs.existsSync(path.join(root, 'App', 'DeepSeekHarnessApp', 'DeepSeekHarness.app', 'Contents', 'Resources', 'profile-doctor.mjs')), true);
});

test('all Windows language guides include the profile integrity recovery', () => {
  const guides = fs.readdirSync(path.join(root, 'windows'))
    .filter(file => /^README.*\.md$/.test(file));
  assert.equal(guides.length, 12);
  for (const guide of guides) {
    const contents = fs.readFileSync(path.join(root, 'windows', guide), 'utf8');
    assert.match(contents, /@deepseek-ai\/dsh-/i, guide);
    assert.match(contents, /tool_calls/i, guide);
  }
});

test('Windows executable discovery preserves complete fallback paths', () => {
  for (const file of [
    'windows/build-release.ps1',
    'windows/launch-dsh.ps1',
    'windows/bootstrap-build-environment.ps1',
    '.github/workflows/windows-release.yml',
  ]) {
    const source = fs.readFileSync(path.join(root, file), 'utf8');
    assert.match(source, /Select-Object -First 1/);
    assert.doesNotMatch(source, /\$(?:nsisC|c)andidates(?:\.Count|\[0\])/);
  }
});

test('Windows verification summary closes its artifact loop', () => {
  const workflow = fs.readFileSync(path.join(root, '.github', 'workflows', 'windows-release.yml'), 'utf8');
  assert.match(
    workflow,
    /foreach \(\$artifact in \$artifacts\) \{[\s\S]*?GITHUB_STEP_SUMMARY[\s\S]*?^          \}$/m,
  );
});

test('Windows documentation screenshots are isolated and verified', () => {
  const capture = fs.readFileSync(path.join(root, 'scripts', 'capture-windows-ui.mjs'), 'utf8');
  const workflow = fs.readFileSync(
    path.join(root, '.github', 'workflows', 'windows-screenshot-candidate.yml'),
    'utf8',
  );

  assert.match(capture, /viewport = \{ width: 1600, height: 1000 \}/);
  assert.match(capture, /locale: 'en-US'/);
  assert.match(capture, /parsedUrl\.hostname !== '127\.0\.0\.1'/);
  assert.match(capture, /fresh non-persistent Playwright context/);
  assert.match(capture, /validatePng/);
  assert.match(capture, /Promise\.race/);
  assert.match(capture, /setTimeout\(resolve, 5_000\)/);
  assert.match(capture, /windows-screenshot-proof\.json/);
  assert.match(capture, /crypto\.createHash\('sha256'\)/);
  assert.match(capture, /windows-05-plugin-inventory\.png/);
  assert.match(workflow, /capture-windows-ui\.mjs/);
  assert.match(workflow, /windows-2025/);
  assert.match(workflow, /runnerImage -ne "windows2025"/);
  assert.match(workflow, /deepseek-harness-windows-screenshots/);
  assert.match(workflow, /1600x1000/);
});

test('macOS documentation screenshots are lossless and linked', () => {
  assert.deepEqual(
    pngDimensions(path.join(root, 'docs', 'images', 'macos-dsh-home.png')),
    { width: 1600, height: 900 },
  );
  assert.deepEqual(
    pngDimensions(path.join(root, 'docs', 'images', 'macos-app-home.png')),
    { width: 1281, height: 768 },
  );

  for (const guide of ['README.md', 'README.zh-CN.md', 'TUTORIAL.md', 'TUTORIAL.zh-CN.md']) {
    const contents = fs.readFileSync(path.join(root, guide), 'utf8');
    assert.match(contents, /docs\/images\/macos-dsh-home\.png/, guide);
    assert.match(contents, /docs\/images\/macos-app-home\.png/, guide);
  }
});
