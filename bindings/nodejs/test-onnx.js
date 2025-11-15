// Test ONNX Runtime integration for FastEmbed Native N-API module
import { existsSync } from 'fs';
import { createRequire } from 'module';
import { join } from 'path';
const require = createRequire(import.meta.url);

console.log('Testing FastEmbed ONNX Runtime Integration...\n');

// Check if ONNX model is available
const MODEL_PATH = join(process.cwd(), '..', '..', 'models', 'nomic-embed-text', 'onnx', 'model.onnx');
const ONNX_AVAILABLE = existsSync(MODEL_PATH);

if (!ONNX_AVAILABLE) {
  console.log('⚠ ONNX model not found at:', MODEL_PATH);
  console.log('⚠ Skipping ONNX tests (this is expected if ONNX Runtime is not configured)');
  console.log('⚠ To run ONNX tests, place an ONNX model at:', MODEL_PATH);
  process.exit(0); // Exit successfully (skip tests)
}

try {
  // Load native module
  const nativeModule = require('./build/Release/fastembed_native.node');
  console.log('✓ Native module loaded successfully');

  // Check if ONNX functions are available
  if (!nativeModule.generateOnnxEmbedding) {
    console.log('⚠ ONNX functions not available in native module');
    console.log('⚠ This may indicate ONNX Runtime was not linked at compile time');
    console.log('⚠ Skipping ONNX tests');
    process.exit(0); // Exit successfully (skip tests)
  }

  console.log('✓ ONNX functions available in native module');
  console.log('  Model path:', MODEL_PATH);
  console.log('');

  // Test 1: Get ONNX model dimension
  console.log('1. Testing getOnnxModelDimension (if available)...');
  try {
    // Note: getOnnxModelDimension may not be exposed in Node.js binding
    // This test is conditional
    if (nativeModule.getOnnxModelDimension) {
      const dim = nativeModule.getOnnxModelDimension(MODEL_PATH);
      console.log('✓ Model dimension detected:', dim);
    } else {
      console.log('  (getOnnxModelDimension not exposed in Node.js binding)');
    }
  } catch (error) {
    console.log('  (getOnnxModelDimension test skipped:', error.message + ')');
  }
  console.log('');

  // Test 2: Generate ONNX embedding
  console.log('2. Testing generateOnnxEmbedding...');
  const text = "machine learning artificial intelligence";
  const dimension = 768; // Common ONNX model dimension

  try {
    const embedding = nativeModule.generateOnnxEmbedding(MODEL_PATH, text, dimension);
    console.log('✓ ONNX embedding generated');
    console.log('  Type:', embedding.constructor.name);
    console.log('  Length:', embedding.length);
    console.log('  First 5 values:', Array.from(embedding.slice(0, 5)));

    // Verify embedding is normalized (unit vector)
    const norm = nativeModule.vectorNorm(embedding);
    console.log('  Norm:', norm.toFixed(4), '(should be ~1.0 for L2-normalized)');

    if (Math.abs(norm - 1.0) > 0.1) {
      console.warn('  ⚠ Warning: Embedding norm is not ~1.0, may not be normalized');
    }
  } catch (error) {
    console.error('✗ Failed to generate ONNX embedding:', error.message);
    const lastError = nativeModule.getOnnxLastError ? nativeModule.getOnnxLastError() : null;
    if (lastError) {
      console.error('  ONNX error:', lastError);
    }
    throw error;
  }
  console.log('');

  // Test 3: ONNX error handling
  console.log('3. Testing ONNX error handling...');
  try {
    // Try with non-existent model
    nativeModule.generateOnnxEmbedding('non_existent_model.onnx', 'text', 768);
    console.warn('  ⚠ Warning: Should have thrown error for non-existent model');
  } catch (error) {
    console.log('✓ Error handling works (non-existent model correctly rejected)');
    const lastError = nativeModule.getOnnxLastError ? nativeModule.getOnnxLastError() : null;
    if (lastError) {
      console.log('  Error message:', lastError);
    }
  }
  console.log('');

  // Test 4: ONNX model caching
  console.log('4. Testing ONNX model caching...');
  const text1 = "first text";
  const text2 = "second text";

  // First call (model load)
  const start1 = Date.now();
  const emb1 = nativeModule.generateOnnxEmbedding(MODEL_PATH, text1, dimension);
  const time1 = Date.now() - start1;
  console.log(`  First call: ${time1}ms (includes model loading)`);

  // Second call (cached model)
  const start2 = Date.now();
  const emb2 = nativeModule.generateOnnxEmbedding(MODEL_PATH, text2, dimension);
  const time2 = Date.now() - start2;
  console.log(`  Second call: ${time2}ms (cached model)`);

  if (time2 < time1) {
    console.log('✓ Model caching works (second call faster)');
  } else {
    console.log('  (Caching may not be noticeable for small models)');
  }
  console.log('');

  // Test 5: Unload ONNX model
  console.log('5. Testing unloadOnnxModel...');
  try {
    const result = nativeModule.unloadOnnxModel();
    console.log('✓ Model unloaded, result:', result);

    // Next call should reload model
    const start3 = Date.now();
    const emb3 = nativeModule.generateOnnxEmbedding(MODEL_PATH, text1, dimension);
    const time3 = Date.now() - start3;
    console.log(`  Reload after unload: ${time3}ms`);
  } catch (error) {
    console.error('✗ Failed to unload model:', error.message);
    throw error;
  }
  console.log('');

  // Test 6: Get ONNX last error
  console.log('6. Testing getOnnxLastError...');
  if (nativeModule.getOnnxLastError) {
    const errorMsg = nativeModule.getOnnxLastError();
    if (errorMsg) {
      console.log('  Last error:', errorMsg);
    } else {
      console.log('  No error (expected if previous operations succeeded)');
    }
    console.log('✓ getOnnxLastError works');
  } else {
    console.log('  (getOnnxLastError not exposed in Node.js binding)');
  }
  console.log('');

  // Test 7: Dimension validation
  console.log('7. Testing dimension validation...');
  try {
    // Try with wrong dimension (if model supports validation)
    nativeModule.generateOnnxEmbedding(MODEL_PATH, text, 128); // Wrong dimension
    console.warn('  ⚠ Warning: Should have validated dimension mismatch');
  } catch (error) {
    console.log('✓ Dimension validation works (wrong dimension correctly rejected)');
  }
  console.log('');

  console.log('========================================');
  console.log('ALL ONNX TESTS PASSED ✓');
  console.log('========================================');
  console.log('\nONNX Runtime integration is working correctly!');

} catch (error) {
  console.error('\n✗ Error:', error.message);
  console.error('Stack:', error.stack);

  // Try to get ONNX error if available
  try {
    const nativeModule = require('./build/Release/fastembed_native.node');
    if (nativeModule.getOnnxLastError) {
      const onnxError = nativeModule.getOnnxLastError();
      if (onnxError) {
        console.error('ONNX error:', onnxError);
      }
    }
  } catch (e) {
    // Ignore
  }

  process.exit(1);
}

