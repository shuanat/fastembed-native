# FastEmbed C# Test Suite

This directory contains the comprehensive test suite for the FastEmbed C# binding.

## Test Project Structure

- **FastEmbed.Tests.csproj**: xUnit test project
- **FastEmbedClientTests.cs**: Unit tests for `FastEmbedClient` class
- **FastEmbedIntegrationTests.cs**: Integration tests for end-to-end workflows
- **FastEmbedOnnxTests.cs**: ONNX Runtime integration tests (conditional)
- **FastEmbedPerformanceTests.cs**: Performance benchmarks

## Running Tests

### Prerequisites

1. Build the native library first:

   ```bash
   cd ../../../bindings/shared
   make  # or use CMake on Windows
   ```

2. Ensure `fastembed.dll` (Windows) or `fastembed.so` (Linux/macOS) is in `bindings/shared/build/`

### Run All Tests

```bash
cd bindings/csharp/tests
dotnet test
```

### Run Specific Test Classes

```bash
# Unit tests only
dotnet test --filter "FullyQualifiedName~FastEmbedClientTests"

# Integration tests only
dotnet test --filter "FullyQualifiedName~FastEmbedIntegrationTests"

# Performance tests only
dotnet test --filter "FullyQualifiedName~FastEmbedPerformanceTests"
```

### Run with Coverage

```bash
dotnet test --collect:"XPlat Code Coverage"
```

## Test Coverage

The test suite follows CONTRIBUTING.md requirements:

- ✅ **Happy path** tests (valid inputs)
- ✅ **Edge cases** (empty text, zero vectors, large dimensions)
- ✅ **Error handling** (invalid arguments, null pointers)
- ✅ **Performance benchmarks** (critical operations)

## Test Categories

### Unit Tests (`FastEmbedClientTests.cs`)

Tests for individual `FastEmbedClient` methods:

- Constructor validation
- Embedding generation
- Vector operations (cosine similarity, dot product, norm, normalize, add)
- Error handling
- Edge cases

### Integration Tests (`FastEmbedIntegrationTests.cs`)

End-to-end workflow tests:

- Library loading and initialization
- Complete embedding workflows
- Batch operations
- Multiple client instances
- Different dimension support

### ONNX Tests (`FastEmbedOnnxTests.cs`)

ONNX Runtime integration tests:

- ONNX embedding generation
- Model loading and caching
- Error handling
- **Note**: These tests are skipped if ONNX Runtime or test model is not available

### Performance Tests (`FastEmbedPerformanceTests.cs`)

Performance benchmarks:

- Embedding generation throughput
- Vector operation performance
- Batch generation efficiency
- Dimension performance comparison

## Notes

- Tests require the native library (`fastembed.dll`/`fastembed.so`) to be built
- ONNX tests are conditional and skip if ONNX Runtime is not available
- Performance tests include assertions but primarily log metrics
- All tests follow .NET conventions and CONTRIBUTING.md guidelines
