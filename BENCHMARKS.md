# FastEmbed Performance Benchmarks

Comprehensive performance testing suite for all FastEmbed language bindings.

---

## 🎯 Purpose

Measure and compare real-world performance across all language bindings:

- **Node.js** (N-API)
- **Python** (pybind11)
- **C#** (P/Invoke)
- **Java** (JNI)

---

## 📊 What We Measure

### 1. Embedding Generation

- Various text lengths (short, medium, long)
- Average time per operation
- Throughput (operations/second)

### 2. Vector Operations

- Cosine similarity
- Dot product
- Vector norm (L2)
- Vector normalization
- Vector addition

---

## 🚀 Quick Start

### Run All Benchmarks (Linux/WSL)

```bash
# Build everything first
make all

# Run comprehensive benchmark suite
bash scripts/run_benchmarks.sh
```

This will:

1. Build the shared C/Assembly library
2. Run benchmarks for all 4 language bindings
3. Generate `BENCHMARK_RESULTS.md` with results

### Run Individual Benchmarks

#### Node.js

```bash
cd bindings/nodejs
npm install && npm run build
node benchmark.js
```

#### Python

```bash
cd bindings/python
python setup.py build_ext --inplace
LD_LIBRARY_PATH=../shared/build python benchmark.py
```

#### C #

```bash
cd bindings/csharp
bash run_benchmark.sh
```

Or manually:

```bash
cd bindings/csharp
export PATH="$HOME/.dotnet:$PATH"
export LD_LIBRARY_PATH=../shared/build
dotnet run --project benchmark.csproj -c Release
```

#### Java

```bash
cd bindings/java
bash run_benchmark.sh
```

Or manually:

```bash
cd bindings/java
# Build JNI wrapper and compile classes
bash build_benchmark.sh

# Run benchmark
java -Djava.library.path=target/lib -cp target/classes:target/test-classes com.fastembed.FastEmbedBenchmark
```

---

## 📋 Test Configuration

| Parameter      | Value                       |
| -------------- | --------------------------- |
| **Iterations** | 1000 (measurement)          |
| **Warmup**     | 100 iterations              |
| **Dimension**  | 768 (standard for models)   |
| **Test Texts** | 5 samples (various lengths) |

---

## 🔬 Benchmark Methodology

### 1. Warmup Phase

- Run operation 100 times before measurement
- Ensures JIT compilation (Node.js, Java)
- Warms up CPU caches

### 2. Measurement Phase

- Run operation 1000 times
- Use high-precision timers:
  - Node.js: `process.hrtime.bigint()`
  - Python: `time.perf_counter_ns()`
  - C#: `Stopwatch`
  - Java: `System.nanoTime()`

### 3. Metrics Calculated

- **Average time**: Total time / iterations
- **Throughput**: Operations per second
- **Standard deviation**: (optional, for statistical analysis)

---

## 📈 Expected Results

**Typical performance (reference, your results may vary):**

### Embedding Generation

- **Fast bindings** (N-API, pybind11): 0.01-0.1 ms
- **Medium bindings** (P/Invoke, JNI): 0.5-2 ms

### Vector Operations

- **All bindings**: 0.0001-0.001 ms (SIMD-optimized)

**Note:** Actual performance depends on:

- CPU architecture and frequency
- System load
- Memory bandwidth
- Compiler optimizations

---

## 🔍 Interpreting Results

### Good Performance Indicators

✅ **Embedding generation < 1ms** - Excellent for real-time applications

✅ **Vector ops < 0.01ms** - SIMD optimizations working

✅ **Consistent results** - Low variance across iterations

### Performance Issues

⚠️ **Embedding > 10ms** - Check if library is built with optimizations

⚠️ **High variance** - System load or thermal throttling

⚠️ **Vector ops > 1ms** - Assembly code may not be used

---

## 🛠️ Troubleshooting

### Benchmark Fails to Run

**Issue**: Missing library

```
LD_LIBRARY_PATH=../shared/build <command>
```

**Issue**: Not built with optimizations

```bash
cd bindings/shared
make clean
CFLAGS="-O3 -march=native" make all
```

### Unexpected Performance

**Check CPU frequency scaling:**

```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# Should be "performance" for benchmarks
```

**Set performance mode:**

```bash
sudo cpupower frequency-set -g performance
```

**Check system load:**

```bash
top
# Ensure no other heavy processes running
```

---

## 📝 Benchmark Files

| Language | Benchmark File                                        |
| -------- | ----------------------------------------------------- |
| Node.js  | `bindings/nodejs/benchmark.js`                        |
| Python   | `bindings/python/benchmark.py`                        |
| C#       | `bindings/csharp/benchmark.cs`                        |
| Java     | `bindings/java/src/test/java/FastEmbedBenchmark.java` |
| Runner   | `scripts/run_benchmarks.sh`                           |

---

## 🤝 Contributing Benchmarks

Want to add more benchmarks? See [CONTRIBUTING.md](CONTRIBUTING.md).

### Guidelines

- **Consistent methodology** - Use same warmup/iterations
- **Fair comparison** - Measure same operations
- **Reproducible** - Document system configuration
- **Statistical rigor** - Include variance/stddev if possible

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/shuanat/fastembed-native/issues)
- **Discussions**: [GitHub Discussions](https://github.com/shuanat/fastembed-native/discussions)

---

**Last updated:** November 1, 2024
