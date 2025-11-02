# FastEmbed Benchmarks

Performance benchmarking suite for FastEmbed library.

## Quick Start

```bash
# Build benchmarks
make benchmark-build

# Run benchmarks
make benchmark
```

## What's Measured

### 1. Hash-based Embedding Generation

- Throughput (embeddings per second)
- Latency per embedding
- Performance with different text lengths

### 2. ONNX Embedding Generation (with Caching)

- **First call**: Model loading time (includes disk I/O and model initialization)
- **Cached calls**: Inference-only time (reuses loaded model)
- **Performance comparison**: Speedup from caching
- **Model switching**: Time to reload after unload

### 3. Vector Operations

- Dot product
- Cosine similarity
- Vector norm calculation
- Vector normalization
- Vector addition

## Benchmark Configuration

Default settings:

- **Dimension**: 768 (BERT-base standard)
- **Warmup iterations**: 10 (to stabilize performance)
- **Benchmark iterations**: 1000 (for statistical significance)

To modify, edit `tests/benchmark.c`:

```c
#define DIMENSION 768
#define WARMUP_ITERATIONS 10
#define BENCHMARK_ITERATIONS 1000
```

## ONNX Runtime Requirements

For ONNX benchmarks:

1. Install ONNX Runtime: `make setup-onnx`
2. Place model file in `models/nomic-embed-text.onnx`
3. Build with ONNX support: `make benchmark-build` (auto-detects ONNX)

If ONNX Runtime is not available, ONNX benchmarks are skipped automatically.

## Example Output

```
╔══════════════════════════════════════════════════════════════╗
║          FastEmbed Performance Benchmarks                     ║
╚══════════════════════════════════════════════════════════════╝

=== Benchmark: Hash-based Embedding Generation ===
  Total time: 45.23 ms
  Operations: 4000 embeddings
  Average per embedding: 0.0113 ms
  Throughput: 88405.31 embeddings/sec

=== Benchmark: ONNX Embedding Generation (with Caching) ===
  Test 1: First Call (Model Loading)
    Time: 234.56 ms (58.64 ms per embedding)
  
  Test 2: Cached Calls (No Model Reload)
    Total time: 1250.34 ms
    Operations: 4000 embeddings
    Average per embedding: 0.3126 ms
    Throughput: 3199.85 embeddings/sec
  
  Test 3: Performance Comparison
    First call overhead: 58.33 ms
    Caching speedup: 187.5x faster
    Cache efficiency: 0.5% (loading time / inference time)
```

## Performance Characteristics

### Hash-based Embeddings

- **Fast**: ~0.01-0.1 ms per embedding
- **No model required**: Deterministic, lightweight
- **SIMD optimized**: Uses assembly code for maximum speed

### ONNX Embeddings (Cached)

- **First call**: 50-200 ms (model loading)
- **Cached inference**: 0.3-2 ms per embedding (depends on model)
- **Speedup from caching**: 50-200x faster than reloading
- **Memory**: Model stays in memory after first load

### Vector Operations

- **Sub-microsecond**: Most operations < 1 microsecond
- **SIMD optimized**: Assembly-level optimizations
- **Scalable**: Performance scales linearly with dimension

## Interpreting Results

### Good Performance Indicators

- Hash embeddings: > 50,000 embeddings/sec
- ONNX cached: > 1,000 embeddings/sec
- Vector ops: < 1 microsecond per operation
- Cache speedup: > 100x faster

### Performance Bottlenecks

- **Slow first ONNX call**: Normal (model loading)
- **Slow cached ONNX calls**: Check model complexity, consider optimization
- **Slow vector ops**: May indicate missing SIMD optimizations
- **Low cache speedup**: Model loading may be too fast relative to inference

## Advanced Usage

### Custom Iteration Count

Modify `BENCHMARK_ITERATIONS` in `benchmark.c` for more/less iterations:

```c
#define BENCHMARK_ITERATIONS 5000  // More iterations = better accuracy
```

### Testing Different Dimensions

```c
#define DIMENSION 1536  // Test with larger embeddings
```

### Memory Profiling

For memory profiling, use tools like `valgrind`:

```bash
valgrind --tool=massif ./build/benchmark
ms_print massif.out.*
```

## Continuous Benchmarking

Add to CI/CD pipeline:

```yaml
- name: Run Benchmarks
  run: |
    make benchmark-build
    make benchmark > benchmark_results.txt
```

## Troubleshooting

### Benchmark fails with "Model not found"

- Ensure ONNX model is in `models/` directory
- Check path in `benchmark.c`: `const char *model_path = "models/nomic-embed-text.onnx";`

### ONNX benchmarks skipped

- Run `make setup-onnx` to install ONNX Runtime
- Verify ONNX Runtime in `onnxruntime/` or `/usr/local/onnxruntime`

### Performance seems low

- Ensure compiler optimizations are enabled (`-O2` in Makefile)
- Check CPU supports SIMD instructions (SSE/AVX)
- Verify no other processes consuming CPU/memory

## Contributing

When adding new benchmarks:

1. Follow existing structure in `benchmark.c`
2. Include warmup iterations
3. Use `get_time_ms()` for timing
4. Print clear, formatted results
5. Add to this documentation
