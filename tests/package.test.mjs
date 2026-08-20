import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

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
