# FastEmbed Testing Guide

## Overview

This document describes how to build and run the test suite for FastEmbed.

## Test Files

The test suite includes the following test files:

1. **test_hash_functions.c** - Unit tests for hash functions (positional_hash_asm, hash_to_float_sin_asm, generate_combined_hash_asm)
2. **test_embedding_generation.c** - Integration tests for embedding generation (all dimensions, consistency, edge cases)
3. **test_quality_improvement.c** - Quality improvement tests (text discrimination)
4. **test_onnx_dimension.c** - ONNX dimension detection and validation tests
5. **benchmark_improved.c** - Performance benchmarks for all dimensions

## Building Tests

### Using Makefile (Linux/macOS/WSL)

```bash
cd bindings/shared
make test-build
```

This will build all test executables in `bindings/shared/build/`:

- `test_basic`
- `test_hash_functions`
- `test_embedding_generation`
- `test_quality_improvement`
- `test_onnx_dimension` (if ONNX Runtime is available)

### Manual Compilation

If Makefile doesn't work, you can compile tests manually:

```bash
cd bindings/shared

# Compile test_hash_functions
gcc -O2 -Wall -I../../bindings/shared/include ../../tests/test_hash_functions.c \
    build/fastembed.a -o build/test_hash_functions -lm -Lbuild

# Compile test_embedding_generation
gcc -O2 -Wall -I../../bindings/shared/include ../../tests/test_embedding_generation.c \
    build/fastembed.a -o build/test_embedding_generation -lm -Lbuild

# Compile test_quality_improvement
gcc -O2 -Wall -I../../bindings/shared/include ../../tests/test_quality_improvement.c \
    build/fastembed.a -o build/test_quality_improvement -lm -Lbuild

# Compile benchmark_improved
gcc -O2 -Wall -I../../bindings/shared/include ../../tests/benchmark_improved.c \
    build/fastembed.a -o build/benchmark_improved -lm -Lbuild

# Compile test_onnx_dimension (requires ONNX Runtime)
gcc -O2 -Wall -DUSE_ONNX_RUNTIME -I../../bindings/shared/include \
    -I/path/to/onnxruntime/include ../../tests/test_onnx_dimension.c \
    build/fastembed.a -o build/test_onnx_dimension -lm -Lbuild \
    -L/path/to/onnxruntime/lib -lonnxruntime
```

## Running Tests

### Cross-Platform Test Scripts (Recommended)

We provide cross-platform test scripts that work on both Windows and Linux/WSL:

**Linux/WSL:**

```bash
scripts/test_shared_linux.sh
```

**Windows:**

```batch
scripts\test_shared_windows.bat
```

These scripts will:

- Check if the library is built
- Run all available tests
- Provide a summary of passed/failed tests
- Exit with appropriate error codes

### Using Makefile

```bash
cd bindings/shared
make test
```

This will run all available tests sequentially. The Makefile automatically detects the platform (Windows/Linux) and uses appropriate commands.

### Manual Execution

```bash
cd bindings/shared/build

# Run individual tests
LD_LIBRARY_PATH=. ./test_hash_functions
LD_LIBRARY_PATH=. ./test_embedding_generation
LD_LIBRARY_PATH=. ./test_quality_improvement
LD_LIBRARY_PATH=. ./test_onnx_dimension  # If ONNX Runtime is available

# Run benchmarks
LD_LIBRARY_PATH=. ./benchmark_improved
```

## Test Results

Test results are printed to stdout. Each test file will show:

- Individual test results (✓ PASS or ✗ FAIL)
- Test summary (tests run, passed, failed)
- Final status (All tests passed or Some tests failed)

### Example Output

```
FastEmbed Hash Functions Unit Tests
===================================

=== Test: positional_hash_asm - Deterministic ===
  ✓ PASS: hash1 == hash2
  Hash value: 1234567890

=== Test: positional_hash_asm - Position Sensitive ===
  ✓ PASS: hash1 != hash2
  'ab' hash: 1234567890
  'ba' hash: 9876543210

...

=== Test Summary ===
Tests run: 9
Tests passed: 9
Tests failed: 0

✓ All tests passed!
```

## Test Coverage

### Hash Functions Tests (test_hash_functions.c)

- ✅ Deterministic behavior
- ✅ Position sensitivity
- ✅ Seed sensitivity
- ✅ Range validation ([-1, 1] for Sin normalization)
- ✅ Distribution quality

### Embedding Generation Tests (test_embedding_generation.c)

- ✅ All supported dimensions (128, 256, 512, 768, 1024, 2048)
- ✅ Consistency (same text = same embedding)
- ✅ Different texts produce different embeddings
- ✅ Case-insensitive behavior
- ✅ Edge cases (empty text, long text, special characters)
- ✅ Default dimension (0 = 128)
- ✅ Invalid dimension rejection

### Quality Improvement Tests (test_quality_improvement.c)

- ✅ Single character difference detection
- ✅ Word order difference detection
- ✅ Similar texts similarity
- ✅ Semantically similar texts
- ✅ Completely different texts
- ✅ Identical texts
- ✅ Case variations (case-insensitive)

### ONNX Dimension Tests (test_onnx_dimension.c)

- ✅ Dimension auto-detection
- ✅ Dimension validation
- ✅ Dimension mismatch detection
- ✅ Dimension caching
- ✅ Invalid model path handling
- ✅ NULL model path handling
- ✅ Supported dimensions validation

### Performance Benchmarks (benchmark_improved.c)

- ✅ All dimensions performance
- ✅ Different text lengths
- ✅ Performance targets verification (128D < 0.05 ms, 768D < 0.15 ms)
- ✅ ONNX dimension detection performance

## Troubleshooting

### Tests fail to compile

1. **Check library is built**: Ensure `bindings/shared/build/fastembed.a` exists

   ```bash
   cd bindings/shared
   make all
   ```

2. **Check include paths**: Ensure `bindings/shared/include/fastembed.h` exists

3. **Check test file paths**: Ensure test files are in `tests/` directory at project root

### Tests fail at runtime

1. **Check library path**: Ensure `LD_LIBRARY_PATH` includes `bindings/shared/build/`

   ```bash
   export LD_LIBRARY_PATH=bindings/shared/build:$LD_LIBRARY_PATH
   ```

2. **Check assembly functions**: Some tests require assembly functions to be exported. Check `embedding_generator.asm` for `global` declarations.

3. **Check ONNX Runtime**: ONNX tests require ONNX Runtime to be installed and available.

### ONNX tests skipped

ONNX tests will be skipped if:

- ONNX Runtime is not installed
- `USE_ONNX_RUNTIME` is not defined during compilation
- Test model file is not found

This is expected behavior - ONNX tests are optional.

## Continuous Integration

Tests are automatically run in GitHub Actions CI on:

- Push to main/develop branches
- Pull requests

See `.github/workflows/ci.yml` for details.

## Next Steps

After running tests:

1. Review test output for any failures
2. Check test coverage
3. Run benchmarks to verify performance
4. Fix any issues found
5. Update tests if needed
