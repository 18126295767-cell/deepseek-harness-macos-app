import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
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

function sha256(file) {
  return createHash('sha256').update(fs.readFileSync(file)).digest('hex');
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
  assert.match(workflow, /PLAYWRIGHT_BROWSERS_PATH/);
  assert.match(capture, /runnerLabel: process\.env\.SCREENSHOT_RUNNER_LABEL/);
  assert.match(workflow, /SCREENSHOT_RUNNER_LABEL: windows-2025/);
  assert.match(workflow, /runnerLabel -ne "windows-2025"/);
  assert.match(workflow, /windows2025\|win25-vs2026/);
  assert.match(workflow, /deepseek-harness-windows-screenshots/);
  assert.match(workflow, /1600x1000/);
});

test('Windows workflows use a pinned, bounded official DSH installation', () => {
  for (const file of [
    '.github/workflows/windows-release.yml',
    '.github/workflows/windows-screenshot-candidate.yml',
  ]) {
    const workflow = fs.readFileSync(path.join(root, file), 'utf8');
    assert.match(workflow, /version: 9\.15\.9/, file);
    assert.match(
      workflow,
      /pnpm add --save-exact --ignore-scripts @deepseek-ai\/dsh@0\.1\.0-rc\.7/,
      file,
    );
  }

  const screenshots = fs.readFileSync(
    path.join(root, '.github', 'workflows', 'windows-screenshot-candidate.yml'),
    'utf8',
  );
  const release = fs.readFileSync(
    path.join(root, '.github', 'workflows', 'windows-release.yml'),
    'utf8',
  );
  assert.match(screenshots, /timeout-minutes: 35/);
  assert.match(release, /name: Smoke test official DSH Web runtime\r?\n        timeout-minutes: 30/);
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

test('reviewed Windows screenshots keep their runner proof, hashes, and guide links', () => {
  const expected = new Map([
    ['windows-01-developer-preview.png', '654600d8acf83ae594d030182bdb542ea0c856074051771727c26460776679a7'],
    ['windows-02-api-key-onboarding.png', '9f18a256695951ccd5a2c53931a3f1beb56f54546f32bec97684426d8c14ff1d'],
    ['windows-03-empty-workspace.png', '7ae5f0587f09bfd75b6f586bdd2309b05f80a4a824ae664a9f1b051f67d46825'],
    ['windows-04-model-settings.png', 'c29b6e50e3ddaff41eedb44890ef051a03bc70a504c0249451cd5bf109e47980'],
    ['windows-05-plugin-inventory.png', 'e5fbc24b1715e3bd509b476cc99e907d7fcd8ac3aba589dd907867b4c8006351'],
  ]);
  const proof = JSON.parse(fs.readFileSync(
    path.join(root, 'docs', 'images', 'windows-screenshot-proof.json'),
    'utf8',
  ));

  assert.equal(proof.platform, 'win32');
  assert.equal(proof.architecture, 'x64');
  assert.equal(proof.runnerLabel, 'windows-2025');
  assert.equal(proof.runnerImage, 'win25-vs2026');
  assert.equal(proof.commit, 'a46c7279cf742c4fa82d3291016cc6fc66f445f1');
  assert.equal(proof.browserProfile, 'fresh non-persistent Playwright context');
  assert.equal(proof.screenshots.length, expected.size);

  for (const [file, hash] of expected) {
    const image = path.join(root, 'docs', 'images', file);
    assert.deepEqual(pngDimensions(image), { width: 1600, height: 1000 }, file);
    assert.equal(sha256(image), hash, file);
    const record = proof.screenshots.find(item => item.file === file);
    assert.equal(record?.sha256, hash, file);
    assert.equal(record?.width, 1600, file);
    assert.equal(record?.height, 1000, file);
  }

  for (const guide of ['README.md', 'README.zh-CN.md']) {
    const contents = fs.readFileSync(path.join(root, guide), 'utf8');
    assert.match(contents, /docs\/images\/windows-03-empty-workspace\.png/, guide);
    assert.match(contents, /docs\/images\/windows-05-plugin-inventory\.png/, guide);
  }
  for (const guide of ['TUTORIAL.md', 'TUTORIAL.zh-CN.md']) {
    const contents = fs.readFileSync(path.join(root, guide), 'utf8');
    for (const file of expected.keys()) assert.match(contents, new RegExp(`docs/images/${file}`), guide);
  }

  const windowsGuides = fs.readdirSync(path.join(root, 'windows'))
    .filter(file => /^README.*\.md$/.test(file));
  assert.equal(windowsGuides.length, 12);
  for (const guide of windowsGuides) {
    const contents = fs.readFileSync(path.join(root, 'windows', guide), 'utf8');
    assert.match(contents, /\.\.\/docs\/images\/windows-03-empty-workspace\.png/, guide);
    assert.match(contents, /\.\.\/docs\/images\/windows-05-plugin-inventory\.png/, guide);
  }
});
