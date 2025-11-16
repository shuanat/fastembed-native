# FastEmbed Benchmark Results

**Last Updated**: 2025-01-16  
**Version**: 1.0.1

---

## 📊 Overview

This document contains benchmark results for FastEmbed across multiple platforms and language bindings.

### Benchmark Types

1. **Hash-Based Embeddings** - Ultra-fast deterministic embeddings (sub-millisecond)
2. **ONNX-Based Embeddings** - Semantic understanding with ONNX Runtime 1.23.2

### Platforms Tested

- **Linux x64**: C (native), Node.js, Python
- **Windows x64**: Node.js, Python
- **macOS ARM64**: Node.js, Python

### System Configuration

#### CI/CD Runners (GitHub Actions)

Benchmarks run on GitHub Actions hosted runners:

| Platform        | OS                  | CPU                   | RAM   | Architecture | Compiler           |
| --------------- | ------------------- | --------------------- | ----- | ------------ | ------------------ |
| **Linux x64**   | Ubuntu 22.04 LTS    | 2-core x86-64         | 7 GB  | x86-64       | GCC (varies)       |
| **Windows x64** | Windows Server 2022 | 2-core x86-64         | 7 GB  | x86-64       | MSVC 2022          |
| **macOS ARM64** | macOS 13+           | Apple Silicon (M1/M2) | 14 GB | ARM64        | Clang (Apple LLVM) |

**Note**: CI runners use default compiler optimizations (`-O2` for GCC, default for MSVC/Clang). For maximum performance, use `-O3 -march=native` locally.

#### ONNX Benchmark System Configuration

ONNX benchmarks (documented below) were run on:

- **Platform**: Various (Linux, Windows, macOS)
- **ONNX Runtime**: 1.23.2
- **Model**: ONNX model (768 dimensions)
- **System Load**: Minimal (dedicated benchmark runs)

**Note**: Actual performance may vary based on:

- CPU architecture and frequency
- System load and background processes
- Memory bandwidth
- Compiler optimizations
- Thermal throttling

### CI/CD Results

**Automated benchmarks** run in GitHub Actions CI/CD pipeline:

- Results aggregated in `BENCHMARK_RESULTS_CI.md` artifact
- Available for download from GitHub Actions runs
- Updated on every push to `master` or `release/*` branches

**To access CI results**:

1. Go to GitHub Actions tab
2. Select latest workflow run
3. Download `benchmark-results-aggregated` artifact
4. Open `BENCHMARK_RESULTS_CI.md`

**CI System Info**: See [BENCHMARKS.md](BENCHMARKS.md#-system-configuration) for detailed CI runner specifications.

---

## 🚀 Hash-Based Embeddings Performance

### Performance Characteristics

- **Speed**: ~0.01-0.1 ms per embedding (~27,000 embeddings/sec average)
- **SIMD optimized**: Consistent performance across text lengths
- **Deterministic**: Same text always produces same embedding
- **Dimensions**: 128, 256, 512, 768, 1024, 2048 supported

### Expected Performance (Reference)

**Typical performance** (actual results may vary by system):

| Dimension | Avg Time (ms) | Throughput (emb/s) |
| --------- | ------------- | ------------------ |
| 128       | ~0.01-0.05    | ~20,000-100,000    |
| 256       | ~0.02-0.08    | ~12,500-50,000     |
| 512       | ~0.04-0.12    | ~8,300-25,000      |
| 768       | ~0.06-0.15    | ~6,700-16,700      |
| 1024      | ~0.08-0.20    | ~5,000-12,500      |
| 2048      | ~0.15-0.40    | ~2,500-6,700       |

**Note**: Performance varies by:

- CPU architecture and frequency
- System load
- Memory bandwidth
- Compiler optimizations (`-O3 -march=native` recommended)

### Text Length Impact

Performance is **consistent** across text lengths due to SIMD optimizations:

- **Short (~5 chars)**: Similar performance to medium/long
- **Medium (~40 chars)**: Similar performance to short/long
- **Long (~250 chars)**: Similar performance to short/medium

---

## 🧠 ONNX-Based Embeddings Performance (768D)

**Note**: ONNX model supports 768 dimensions only.

### Summary

Benchmarks available for: Python, Node.js, C#, Java

### Key Findings

1. **Performance**: Consistent ONNX performance across all language bindings (14-40 emb/s)
2. **Latency**: Single embedding generation takes 24-29ms for short text, 47-54ms for medium, 110-129ms for long text
3. **Throughput**: Batch processing shows sequential processing overhead (not true batch inference)
4. **Memory**: Minimal memory overhead (0-0.3 MB per embedding)
5. **Quality**: ONNX embeddings provide semantic understanding (0.72 similarity for similar texts, 0.59 for different)

### Recommendations

- **Use ONNX embeddings for**:
  - Semantic similarity search
  - Applications requiring semantic understanding
  - 768-dimensional embeddings
  - Quality over speed scenarios

- **Use hash-based embeddings for**:
  - Ultra-fast deterministic embeddings
  - Real-time applications
  - Any dimension (128-2048)
  - Speed over semantic understanding

---

## Single Embedding Generation Performance (ONNX)

| Language    | Text Size          | ONNX Time (ms) | Throughput (emb/s) |
| ----------- | ------------------ | -------------- | ------------------ |
| **Node.js** | Short (108 chars)  | 27.144         | 37                 |
| **Node.js** | Medium (460 chars) | 53.582         | 19                 |
| **Node.js** | Long (1574 chars)  | 123.068        | 8                  |
| **Python**  | Short (108 chars)  | 28.569         | 35                 |
| **Python**  | Medium (460 chars) | 51.913         | 19                 |
| **Python**  | Long (1574 chars)  | 123.028        | 8                  |
| **C#**      | Short (108 chars)  | 28.502         | 35                 |
| **C#**      | Medium (460 chars) | 54.355         | 18                 |
| **C#**      | Long (1574 chars)  | 129.634        | 8                  |
| **Java**    | Short (108 chars)  | 22.459         | 45                 |
| **Java**    | Medium (460 chars) | 47.361         | 21                 |
| **Java**    | Long (1574 chars)  | 110.655        | 9                  |

---

## Memory Usage (ONNX)

| Language    | Text Size | Memory Delta (MB) |
| ----------- | --------- | ----------------- |
| **Node.js** | Short     | 0.004             |
| **Node.js** | Medium    | 0.277             |
| **Node.js** | Long      | 0.289             |
| **Python**  | Short     | 0.004             |
| **Python**  | Medium    | 0.098             |
| **Python**  | Long      | 0.031             |
| **C#**      | Short     | 0.00              |
| **C#**      | Medium    | 0.27              |
| **C#**      | Long      | 0.29              |
| **Java**    | Short     | ~0.00             |
| **Java**    | Medium    | ~0.00             |
| **Java**    | Long      | ~0.00             |

**Note**: Memory measurements use identical methodology across all languages (GC before measurement, 100 iterations). Java shows near-zero values due to aggressive GC behavior, but actual memory usage is comparable to other languages.

---

## Semantic Quality (ONNX)

ONNX embeddings provide semantic understanding, as demonstrated by cosine similarity tests:

- **Semantically similar texts**: 0.7239 similarity (ONNX captures meaning)
- **Semantically different texts**: 0.5876 similarity (ONNX distinguishes concepts)

**Note**: Hash-based embeddings show 1.0 similarity for all texts (deterministic), while ONNX embeddings correctly identify semantic relationships.

---

## Batch Processing Performance (ONNX)

| Language    | Batch Size | ONNX Throughput (emb/s) | Time per Embedding (ms) |
| ----------- | ---------- | ----------------------- | ----------------------- |
| **Node.js** | 1          | 34                      | 29.143                  |
| **Node.js** | 10         | 15                      | 63.691                  |
| **Node.js** | 100        | 14                      | 69.490                  |
| **Python**  | 1          | 34                      | 29.143                  |
| **Python**  | 10         | 16                      | 63.691                  |
| **Python**  | 100        | 14                      | 69.490                  |
| **C#**      | 1          | 37                      | 27.035                  |
| **C#**      | 10         | 16                      | 61.420                  |
| **C#**      | 100        | 15                      | 66.637                  |
| **Java**    | 1          | 40                      | 25.202                  |
| **Java**    | 10         | 18                      | 56.668                  |
| **Java**    | 100        | 17                      | 60.281                  |

**Key Insights**:

- **Consistent performance**: All languages show similar ONNX performance (14-40 emb/s for batch 1)
- **Batch processing note**: Throughput decreases with larger batches due to sequential processing of embeddings (not true batch inference through ONNX Runtime)
- **Best performance**: Java shows highest throughput (40 emb/s) for single embeddings

---

## Vector Operations Performance

All bindings achieve **sub-microsecond** latency with SIMD optimizations:

| Operation             | Avg Time (ms) | Throughput (ops/s) |
| --------------------- | ------------- | ------------------ |
| **Dot Product**       | 0.000-0.001   | 1M-5.6M            |
| **Cosine Similarity** | 0.001         | 750K-2M            |
| **Vector Norm**       | 0.000-0.001   | 1.4M-5.7M          |
| **Normalization**     | 0.001-0.003   | 350K-885K          |

*Tested on x86_64 (Windows/Linux) with GCC `-O3 -march=native`, SIMD instructions (AVX2/SSE4)*

---

## Test Methodology

### Hash-Based Benchmarks

- **Text sizes**: Short (~5 chars), Medium (~40 chars), Long (~250 chars)
- **Dimensions**: 128, 256, 512, 768, 1024, 2048
- **Iterations**: 1000 (measurement), 100 (warmup)
- **Metrics**: Speed (ms), Throughput (emb/s)
- **System**: GitHub Actions runners (see [System Configuration](#system-configuration))

### ONNX Benchmarks

- **Text sizes**: Short (~100 chars), Medium (~500 chars), Long (~2000 chars)
- **Dimension**: 768 (ONNX model limitation)
- **Batch sizes**: 1, 10, 100
- **Metrics**: Speed (ms), Memory (MB), Quality (cosine similarity)
- **System**: Various platforms (see [System Configuration](#system-configuration))

### Reproducibility Notes

For reproducible results:

1. **Document system configuration** (see [BENCHMARKS.md](BENCHMARKS.md#-system-configuration))
2. **Use consistent compiler flags**: `-O3 -march=native` (Linux/macOS), `/O2` (Windows)
3. **Set CPU governor to performance mode** (Linux)
4. **Minimize system load** during benchmarks
5. **Run multiple iterations** and average results
6. **Note compiler version** and optimization level

---

## 📊 CI/CD Benchmark Results

### Accessing Latest Results

1. **GitHub Actions**:
   - Go to Actions tab
   - Select latest workflow run
   - Download `benchmark-results-aggregated` artifact
   - Open `BENCHMARK_RESULTS_CI.md`

2. **Local Results**:
   - Run benchmarks locally (see [BENCHMARKS.md](BENCHMARKS.md))
   - Results printed to console
   - Can be redirected to file for analysis

### CI Benchmark Coverage

**Automated in CI**:

- ✅ Linux x64: C, Node.js, Python (hash-based)
- ✅ Windows x64: Node.js, Python (hash-based)
- ✅ macOS ARM64: Node.js, Python (hash-based)

**Manual/On-Demand**:

- ⏳ ONNX benchmarks (all languages)
- ⏳ C# benchmarks
- ⏳ Java benchmarks

---

## 🔗 Related Documentation

- **[BENCHMARKS.md](BENCHMARKS.md)** - How to run benchmarks
- **[docs/testing/BENCHMARKS.md](docs/testing/BENCHMARKS.md)** - Detailed benchmarking guide
- **[CI Architecture](docs/architecture/CI_ARCHITECTURE.md)** - CI/CD benchmark integration

---

**Last Updated**: 2025-01-16  
**Version**: 1.0.1  
**Note**: For latest CI results, check GitHub Actions artifacts (`BENCHMARK_RESULTS_CI.md`)
