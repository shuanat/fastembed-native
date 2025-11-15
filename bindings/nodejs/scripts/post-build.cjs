#!/usr/bin/env node
/**
 * Post-build script for Node.js binding
 * 
 * On macOS: Copy ONNX Runtime dylib to build/Release for @loader_path resolution
 * This ensures the native module can find libonnxruntime.dylib at runtime
 */

const fs = require('fs');
const path = require('path');

const platform = process.platform;

if (platform === 'darwin') {
  console.log('[Post-Build] macOS detected - copying ONNX Runtime dylib...');

  const projectRoot = path.resolve(__dirname, '../../..');
  const onnxLibDir = path.join(projectRoot, 'bindings/onnxruntime/lib');
  const buildDir = path.join(__dirname, '../build/Release');

  // Find all dylib files in ONNX Runtime lib directory
  try {
    if (!fs.existsSync(onnxLibDir)) {
      console.log('[Post-Build] Warning: ONNX Runtime lib directory not found:', onnxLibDir);
      process.exit(0);
    }

    const files = fs.readdirSync(onnxLibDir);
    const dylibFiles = files.filter(f => f.endsWith('.dylib'));

    if (dylibFiles.length === 0) {
      console.log('[Post-Build] Warning: No dylib files found in:', onnxLibDir);
      process.exit(0);
    }

    // Ensure build directory exists
    if (!fs.existsSync(buildDir)) {
      console.log('[Post-Build] Warning: Build directory not found:', buildDir);
      process.exit(0);
    }

    // Copy each dylib file
    dylibFiles.forEach(file => {
      const src = path.join(onnxLibDir, file);
      const dest = path.join(buildDir, file);

      try {
        fs.copyFileSync(src, dest);
        console.log('[Post-Build] ✓ Copied:', file);
      } catch (err) {
        console.error('[Post-Build] ✗ Failed to copy', file, ':', err.message);
      }
    });

    // Fix rpath references in .node file using install_name_tool
    const nodeFile = path.join(buildDir, 'fastembed_native.node');
    if (fs.existsSync(nodeFile)) {
      console.log('[Post-Build] Fixing rpath references in .node file...');

      const { execSync } = require('child_process');

      dylibFiles.forEach(file => {
        try {
          // Change @rpath reference to @loader_path (same directory)
          const cmd = `install_name_tool -change @rpath/${file} @loader_path/${file} "${nodeFile}"`;
          execSync(cmd, { stdio: 'inherit' });
          console.log('[Post-Build] ✓ Fixed rpath for:', file);
        } catch (err) {
          console.error('[Post-Build] ✗ Failed to fix rpath for', file, ':', err.message);
        }
      });
    } else {
      console.log('[Post-Build] Warning: fastembed_native.node not found');
    }

    console.log('[Post-Build] ✓ Post-build complete for macOS');
  } catch (err) {
    console.error('[Post-Build] Error:', err.message);
    // Don't fail the build, just warn
    process.exit(0);
  }
} else {
  console.log('[Post-Build] Platform:', platform, '- no post-build actions needed');
}

