# FastEmbed Performance Benchmarks

Comprehensive performance testing suite for FastEmbed language bindings and platforms.

**Last Updated**: 2025-01-16  
**Version**: 1.0.1

---

## 🎯 Purpose

Measure and compare real-world performance across:

- **Platforms**: Linux x64, Windows x64, macOS ARM64
- **Language Bindings**: C (native), Node.js, Python
- **Embedding Types**: Hash-based (deterministic), ONNX-based (semantic)
- **Dimensions**: 128, 256, 512, 768, 1024, 2048
- **Text Lengths**: Short (~5 chars), Medium (~40 chars), Long (~250 chars)

---

## 📊 What We Measure

### 1. Hash-Based Embeddings

**Ultra-fast deterministic embeddings** - sub-millisecond performance:

- **Performance**: ~0.01-0.1 ms per embedding (~27,000 embeddings/sec average)
- **SIMD optimized**: Consistent performance across text lengths
- **Deterministic**: Same text always produces same embedding
- **Dimensions**: 128, 256, 512, 768, 1024, 2048
- **Platforms**: Linux (C, Node.js, Python), Windows (Node.js, Python), macOS (Node.js, Python)

### 2. ONNX-Based Embeddings

**Semantic understanding with ONNX Runtime 1.23.2**:

- **Performance**: 14-40 embeddings/sec (single), 14-46 emb/s (batch)
- **Memory**: 0-0.3 MB overhead per embedding
- **Quality**: 0.72 similarity for similar texts, 0.59 for different
- **Dimension**: 768 (ONNX model limitation)
- **Languages**: Node.js, Python, C#, Java (see [ONNX Benchmarks](#-onnx-benchmarks) section)

### 3. Vector Operations

All bindings achieve **sub-microsecond** latency with SIMD optimizations:

- **Dot Product**: 0.000-0.001 ms (1M-5.6M ops/sec)
- **Cosine Similarity**: 0.001 ms (750K-2M ops/sec)
- **Vector Norm**: 0.000-0.001 ms (1.4M-5.7M ops/sec)
- **Normalization**: 0.001-0.003 ms (350K-885K ops/sec)

---

## 🚀 Quick Start

### Automated CI Benchmarks

Benchmarks run automatically in CI/CD pipeline on every push:

- **Linux x64**: C, Node.js, Python
- **Windows x64**: Node.js, Python
- **macOS ARM64**: Node.js, Python

Results are aggregated and available as:

- **CI Artifact**: `benchmark-results-aggregated` (BENCHMARK_RESULTS_CI.md)
- **Individual Results**: Platform-specific artifacts

### Run Benchmarks Locally

#### Hash-Based Benchmarks (C)

**Linux**:

```bash
cd tests
gcc -O2 -I../bindings/shared/include benchmark_improved.c \
  -L../bindings/shared/build -lfastembed_native -lm -o benchmark
export LD_LIBRARY_PATH=../bindings/shared/build:$LD_LIBRARY_PATH
./benchmark
```

#### Hash-Based Benchmarks (Node.js)

**All Platforms**:

```bash
cd bindings/nodejs
npm install && npm run build
node benchmark.js
```

#### Hash-Based Benchmarks (Python)

**Linux/macOS**:

```bash
cd bindings/python
pip install pybind11 numpy
python setup.py build_ext --inplace
export LD_LIBRARY_PATH=../shared/build:$LD_LIBRARY_PATH
python3 benchmark.py
```

**Windows**:

```batch
cd bindings\python
pip install pybind11 numpy
python setup.py build_ext --inplace
python benchmark.py
```

---

## 📋 ONNX Benchmarks

### Run ONNX Benchmarks

**Note**: ONNX benchmarks require ONNX Runtime 1.23.2 to be downloaded and configured.

#### Node.js

```bash
cd bindings/nodejs
npm install && npm run build
node benchmark_onnx.js
```

#### Python

```bash
cd bindings/python
python setup.py build_ext --inplace
export LD_LIBRARY_PATH=../shared/build:$LD_LIBRARY_PATH
python benchmark_onnx.py
```

#### C\#

```bash
cd bindings/csharp
dotnet run --project benchmark_onnx.cs
```

#### Java

```bash
cd bindings/java/java
mvn compile
java -Djava.library.path=build -cp target/classes benchmark_onnx
```

### ONNX Benchmark Results

See [BENCHMARK_RESULTS.md](BENCHMARK_RESULTS.md) for detailed ONNX performance data.

**Key Findings**:

- **Performance**: Consistent ONNX performance across all language bindings (14-40 emb/s)
- **Latency**: Single embedding generation takes 24-29ms for short text, 47-54ms for medium, 110-129ms for long text
- **Throughput**: Batch processing shows sequential processing overhead (not true batch inference)
- **Memory**: Minimal memory overhead (0-0.3 MB per embedding)
- **Quality**: ONNX embeddings provide semantic understanding (0.72 similarity for similar texts, 0.59 for different)

---

## 💻 System Configuration

### CI/CD Runners (GitHub Actions)

Benchmarks run on GitHub Actions hosted runners with the following specifications:

#### Linux x64 (ubuntu-latest)

- **OS**: Ubuntu 22.04 LTS
- **CPU**: 2-core (x86-64)
- **RAM**: 7 GB
- **Architecture**: x86-64
- **Compiler**: GCC (version varies by runner)
- **Optimizations**: `-O2` (CI default)

#### Windows x64 (windows-latest)

- **OS**: Windows Server 2022
- **CPU**: 2-core (x86-64)
- **RAM**: 7 GB
- **Architecture**: x86-64
- **Compiler**: MSVC (Visual Studio 2022)
- **Optimizations**: Default MSVC optimizations

#### macOS ARM64 (macos-latest)

- **OS**: macOS 13 (Ventura) or later
- **CPU**: Apple Silicon (M1/M2) - ARM64
- **RAM**: 14 GB
- **Architecture**: ARM64
- **Compiler**: Clang (Apple LLVM)
- **Optimizations**: Default Clang optimizations

### Local Benchmark Configuration

For reproducible local benchmarks, document your system configuration:

**Linux**:

```bash
# CPU Information
lscpu | grep -E "Model name|Architecture|CPU\(s\)|Thread|Core"

# Memory
free -h

# Compiler Version
gcc --version
g++ --version

# System Load
uptime
```

**Windows**:

```batch
REM CPU Information
wmic cpu get name,numberofcores,numberoflogicalprocessors

REM Memory
wmic computersystem get totalphysicalmemory

REM Compiler Version
cl
```

**macOS**:

```bash
# CPU Information
sysctl -n machdep.cpu.brand_string
sysctl -n hw.ncpu
sysctl -n hw.physicalcpu

# Memory
sysctl hw.memsize

# Compiler Version
clang --version
```

### Recommended System Configuration

For best benchmark results:

- **CPU**: Modern x86-64 or ARM64 processor with SIMD support (SSE4/AVX2 for x86-64, NEON for ARM64)
- **RAM**: 4+ GB available
- **OS**: Recent stable release (Linux 5.x+, Windows 10+, macOS 12+)
- **Compiler**: GCC 7+, Clang 10+, or MSVC 2019+
- **Optimizations**: `-O3 -march=native` (Linux/macOS), `/O2` (Windows)
- **CPU Governor**: Performance mode (Linux: `cpupower frequency-set -g performance`)

### Performance Impact Factors

Benchmark results are affected by:

1. **CPU Architecture**: x86-64 vs ARM64 (different SIMD instructions)
2. **CPU Frequency**: Higher frequency = better performance
3. **CPU Governor**: Performance mode vs powersave mode
4. **System Load**: Background processes affect results
5. **Memory Bandwidth**: Faster RAM = better performance
6. **Compiler Optimizations**: `-O3 -march=native` vs `-O2`
7. **Thermal Throttling**: CPU throttling under load reduces performance

---

## 📈 Benchmark Methodology

### Test Configuration

| Parameter        | Value                                                   |
| ---------------- | ------------------------------------------------------- |
| **Iterations**   | 1000 (measurement)                                      |
| **Warmup**       | 100 iterations                                          |
| **Dimensions**   | 128, 256, 512, 768, 1024, 2048                          |
| **Text Lengths** | Short (~5 chars), Medium (~40 chars), Long (~250 chars) |

### Measurement Process

1. **Warmup Phase**: Run operation 100 times before measurement
   - Ensures JIT compilation (Node.js, Java)
   - Warms up CPU caches

2. **Measurement Phase**: Run operation 1000 times
   - Use high-precision timers:
     - C: `clock_gettime()` or `QueryPerformanceCounter()`
     - Node.js: `process.hrtime.bigint()`
     - Python: `time.perf_counter_ns()`
     - C#: `Stopwatch`
     - Java: `System.nanoTime()`

3. **Metrics Calculated**:
   - **Average time**: Total time / iterations
   - **Throughput**: Operations per second
   - **Standard deviation**: (optional, for statistical analysis)

---

## 🔍 Interpreting Results

### Good Performance Indicators

✅ **Hash-based embedding generation < 1ms** - Excellent for real-time applications

✅ **ONNX embedding generation 20-30ms** - Good for semantic search

✅ **Vector ops < 0.01ms** - SIMD optimizations working

✅ **Consistent results** - Low variance across iterations

### Performance Issues

⚠️ **Hash-based embedding > 10ms** - Check if library is built with optimizations (`-O3 -march=native`)

⚠️ **ONNX embedding > 100ms** - Check ONNX Runtime installation and model availability

⚠️ **High variance** - System load or thermal throttling

⚠️ **Vector ops > 1ms** - Assembly code may not be used

---

## 🛠️ Troubleshooting

### Benchmark Fails to Run

**Issue**: Missing library

```bash
# Linux/macOS
export LD_LIBRARY_PATH=../bindings/shared/build:$LD_LIBRARY_PATH

# Windows
# Ensure DLL is in PATH or same directory as executable
```

**Issue**: Not built with optimizations

```bash
cd bindings/shared
make clean
CFLAGS="-O3 -march=native" make all
```

### Unexpected Performance

**Check CPU frequency scaling**:

```bash
# Linux
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# Should be "performance" for benchmarks

# Set performance mode
sudo cpupower frequency-set -g performance
```

**Check system load**:

```bash
top
# Ensure no other heavy processes running
```

### ONNX Runtime Issues

**Missing ONNX Runtime**:

```bash
# Download ONNX Runtime 1.23.2
cd bindings
wget https://github.com/microsoft/onnxruntime/releases/download/v1.23.2/onnxruntime-linux-x64-1.23.2.tgz
tar -xzf onnxruntime-linux-x64-1.23.2.tgz
mv onnxruntime-linux-x64-1.23.2 onnxruntime
```

**Model not found**:

```bash
# Download model using script
python scripts/download_model.py
```

---

## 📝 Benchmark Files

| Language    | Hash-Based Benchmark   | ONNX Benchmark        | Location              |
| ----------- | ---------------------- | --------------------- | --------------------- |
| **C**       | `benchmark_improved.c` | -                     | `tests/`              |
| **Node.js** | `benchmark.js`         | `benchmark_onnx.js`   | `bindings/nodejs/`    |
| **Python**  | `benchmark.py`         | `benchmark_onnx.py`   | `bindings/python/`    |
| **C#**      | -                      | `benchmark_onnx.cs`   | `bindings/csharp/`    |
| **Java**    | -                      | `benchmark_onnx.java` | `bindings/java/java/` |

---

## 📊 CI/CD Integration

### Automated Benchmarking

Benchmarks run automatically in GitHub Actions CI/CD:

- **Trigger**: On every push to `master` or `release/*` branches
- **Platforms**: Linux x64, Windows x64, macOS ARM64
- **Languages**: C (Linux only), Node.js, Python
- **Results**: Aggregated in `benchmark-results-aggregated` artifact

### CI Benchmark Jobs

1. **benchmark-linux**: C, Node.js, Python benchmarks
2. **benchmark-windows**: Node.js, Python benchmarks
3. **benchmark-macos**: Node.js, Python benchmarks
4. **benchmark-aggregate**: Aggregates all results into BENCHMARK_RESULTS_CI.md

### Accessing CI Results

1. Go to GitHub Actions tab
2. Select latest workflow run
3. Download `benchmark-results-aggregated` artifact
4. Open `BENCHMARK_RESULTS_CI.md` for aggregated results

---

## 📚 Results Documentation

### Hash-Based Benchmark Results

- **CI Results**: `BENCHMARK_RESULTS_CI.md` (generated by CI)
- **Local Results**: Console output when running benchmarks

### ONNX Benchmark Results Documentation

- **Detailed Results**: [BENCHMARK_RESULTS.md](BENCHMARK_RESULTS.md)
- **CI Results**: Included in `BENCHMARK_RESULTS_CI.md` (if ONNX benchmarks run)

---

## 🤝 Contributing Benchmarks

Want to add more benchmarks? See [CONTRIBUTING.md](CONTRIBUTING.md).

### Guidelines

- **Consistent methodology** - Use same warmup/iterations
- **Fair comparison** - Measure same operations
- **Reproducible** - Document system configuration
- **Statistical rigor** - Include variance/stddev if possible
- **Platform coverage** - Test on multiple platforms when possible

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/shuanat/fastembed-native/issues)
- **Documentation**: [docs/testing/BENCHMARKS.md](docs/testing/BENCHMARKS.md)

---

**Last Updated**: 2025-01-16  
**Version**: 1.0.1
