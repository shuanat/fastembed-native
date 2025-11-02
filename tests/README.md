# FastEmbed Tests

Unit tests for FastEmbed library functions.

## Running Tests

### Build and Run

```bash
# Build tests
make test-build

# Run tests
make test
```

### Performance Benchmarks

```bash
# Build benchmarks
make benchmark-build

# Run benchmarks
make benchmark
```

For detailed benchmark documentation, see [BENCHMARK.md](BENCHMARK.md).

### Manual Build

```bash
# Linux
gcc -o test_basic tests/test_basic.c fastembed.a -lm -Iinclude
LD_LIBRARY_PATH=. ./test_basic

# Windows
gcc -o test_basic.exe tests/test_basic.c fastembed.lib -lm -Iinclude
test_basic.exe
```

### Testing ONNX Features

To test ONNX Runtime integration (model loading, caching, etc.):

```bash
# 1. Install ONNX Runtime (if not already installed)
make setup-onnx

# 2. Download test model (optional, for full integration tests)
# Place your .onnx model in models/ directory

# 3. Build and run tests (ONNX tests are included if ONNX Runtime is available)
make test-build
make test
```

**ONNX Test Requirements:**

- ONNX Runtime installed (`make setup-onnx`)
- ONNX model file (optional, for actual inference tests)
- Model should be placed in `models/` directory

## Test Coverage

Current tests cover:

### Hash-based Embeddings (Core)

- ✅ Embedding generation
- ✅ Dot product calculation
- ✅ Cosine similarity
- ✅ Vector norm calculation
- ✅ Vector normalization
- ✅ Vector addition
- ✅ Consistency (same input → same output)

### ONNX Runtime Integration (Optional)

- ⚠️ ONNX embedding generation (requires ONNX Runtime)
- ⚠️ Model session caching
- ⚠️ Model switching
- ⚠️ Session unloading

**Note**: ONNX tests require ONNX Runtime to be installed. Run `make setup-onnx` to install it.

## Adding New Tests

1. Create test file in `tests/` directory
2. Add to `TEST_SOURCES` in `Makefile`
3. Follow existing test structure:
   - Use `ASSERT_EQ`, `ASSERT_NE`, `ASSERT_NOT_NULL` macros
   - Print clear test descriptions
   - Return 0 on success, 1 on failure

## Example Test Structure

```c
void test_my_feature() {
    printf("\n=== Test: My Feature ===\n");
    
    // Test code here
    float result = fastembed_my_function(...);
    
    ASSERT_EQ(result, expected_value);
}
```

## ONNX Model Caching Tests

When testing ONNX features, you can verify model caching behavior:

```c
#include "fastembed.h"

void test_onnx_caching() {
    printf("\n=== Test: ONNX Model Caching ===\n");
    
    float embedding1[768], embedding2[768];
    const char *model_path = "models/nomic-embed-text.onnx";
    
    // First call - loads model (slower)
    int result1 = fastembed_onnx_generate(model_path, "Hello", embedding1, 768);
    ASSERT_EQ_INT(result1, 0);
    
    // Second call - uses cache (faster)
    int result2 = fastembed_onnx_generate(model_path, "World", embedding2, 768);
    ASSERT_EQ_INT(result2, 0);
    
    // Unload model
    int unload_result = fastembed_onnx_unload();
    ASSERT_EQ_INT(unload_result, 0);
    
    // Next call will reload model
    int result3 = fastembed_onnx_generate(model_path, "Test", embedding1, 768);
    ASSERT_EQ_INT(result3, 0);
}
```

**Expected Behavior:**

- First call: Model loads from disk (~100-500ms)
- Subsequent calls: Reuse cached session (fast, no reload)
- After `fastembed_onnx_unload()`: Next call reloads model
- Switching models: Automatic unload/load when model_path changes

## Known Issues

### Segmentation Fault in Tests

Some tests may fail with segmentation faults due to known issues with the assembly embedding generation code. The tests are designed to handle this gracefully:

- Vector operations (dot product, cosine similarity, etc.) are fully tested and work correctly
- Embedding generation tests may fail if the assembly code has issues
- Tests will skip embedding generation if it causes crashes

**Status**: This is a known limitation. Vector operations are production-ready, embedding generation may need fixes.

### ONNX Runtime Requirements

ONNX tests require:

- ONNX Runtime installed and available in `onnxruntime/` or `/usr/local/onnxruntime`
- Model file in `models/` directory (optional for basic tests)
- Compilation with `-DUSE_ONNX_RUNTIME` flag

If ONNX Runtime is not available, ONNX-related tests will be skipped automatically.

## Continuous Integration

Tests are automatically run in GitHub Actions CI on:

- Push to main/develop branches
- Pull requests

See `.github/workflows/ci.yml` for details.
