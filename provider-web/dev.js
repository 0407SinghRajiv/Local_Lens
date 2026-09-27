/**
 * dev.js - Windows/OneDrive-safe Next.js dev server launcher
 *
 * Strategy: Pause OneDrive sync before starting Next.js so it cannot
 * lock .next/trace or other build files. OneDrive is resumed when the
 * server exits (Ctrl+C). This is the only 100% reliable fix when the
 * project lives inside OneDrive on Windows.
 */
const fs  = require('fs');
const path = require('path');
const cp  = require('child_process');

const root      = __dirname;
const nextDir   = path.join(root, '.next');
const traceFile = path.join(nextDir, 'trace');

// 1. Delete stale trace file from previous session
try {
  if (fs.existsSync(traceFile)) {
    fs.unlinkSync(traceFile);
    console.log('[dev.js] Cleared stale .next/trace');
  }
} catch (e) {
  console.warn('[dev.js] Could not clear trace:', e.message);
}

// 1b. Ensure to-json.js has EPERM error handler for Windows/OneDrive
try {
  const toJsonPath = path.join(root, 'node_modules', 'next', 'dist', 'trace', 'report', 'to-json.js');
  if (fs.existsSync(toJsonPath)) {
    let content = fs.readFileSync(toJsonPath, 'utf8');
    if (!content.includes('// Prevent unhandled EPERM error')) {
      content = content.replace(
        'this.writeStream = _fs.default.createWriteStream(this.file, writeStreamOptions);',
        'try { this.writeStream = _fs.default.createWriteStream(this.file, writeStreamOptions); this.writeStream.on("error", (err) => { /* Prevent unhandled EPERM error */ }); } catch (err) {}'
      );
      fs.writeFileSync(toJsonPath, content, 'utf8');
      console.log('[dev.js] Applied EPERM safety patch to Next.js trace reporter');
    }
  }
} catch (e) {
  console.warn('[dev.js] Patch note:', e.message);
}


// 2. Pause OneDrive sync (prevents file locking during dev)
function oneDriveCmd(action) {
  const odPaths = [
    process.env.LOCALAPPDATA + '\\Microsoft\\OneDrive\\OneDrive.exe',
    'C:\\Program Files\\Microsoft OneDrive\\OneDrive.exe',
    'C:\\Program Files (x86)\\Microsoft OneDrive\\OneDrive.exe',
  ];
  for (const odPath of odPaths) {
    if (fs.existsSync(odPath)) {
      try {
        cp.execSync(`"${odPath}" /pause`, { stdio: 'ignore', timeout: 3000 });
        return true;
      } catch (_) {}
    }
  }
  return false;
}

const paused = oneDriveCmd('pause');
if (paused) {
  console.log('[dev.js] OneDrive sync PAUSED - will resume on exit');
} else {
  console.log('[dev.js] OneDrive not found / already paused - continuing');
}

// 3. Start Next.js dev server
console.log('[dev.js] Starting Next.js...\n');
const nextBin = path.join(root, 'node_modules', 'next', 'dist', 'bin', 'next');

const child = cp.spawn(process.execPath, [nextBin, 'dev'], {
  stdio: 'inherit',
  cwd:   root,
  env:   { ...process.env, NEXT_TELEMETRY_DISABLED: '1' },
});

// 4. Resume OneDrive on exit
function resume() {
  if (paused) {
    const odPaths = [
      process.env.LOCALAPPDATA + '\\Microsoft\\OneDrive\\OneDrive.exe',
      'C:\\Program Files\\Microsoft OneDrive\\OneDrive.exe',
    ];
    for (const odPath of odPaths) {
      if (fs.existsSync(odPath)) {
        try { cp.execSync(`"${odPath}" /resume`, { stdio: 'ignore', timeout: 3000 }); } catch (_) {}
        break;
      }
    }
    console.log('\n[dev.js] OneDrive sync RESUMED');
  }
  process.exit(0);
}

child.on('close', () => resume());
process.on('SIGINT',  () => { child.kill('SIGINT');  resume(); });
process.on('SIGTERM', () => { child.kill('SIGTERM'); resume(); });
