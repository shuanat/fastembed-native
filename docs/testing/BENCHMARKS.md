# Performance Benchmarks - How to Run

See [../../BENCHMARKS.md](../../BENCHMARKS.md) for the complete benchmarking guide.

## Quick Run

### Hash-Based Benchmarks

**Linux:**

```bash
# C benchmark
cd tests
gcc -O2 -I../bindings/shared/include benchmark_improved.c \
  -L../bindings/shared/build -lfastembed_native -lm -o benchmark
export LD_LIBRARY_PATH=../bindings/shared/build:$LD_LIBRARY_PATH
./benchmark

# Node.js benchmark
cd bindings/nodejs
npm install && npm run build
node benchmark.js

# Python benchmark
cd bindings/python
python setup.py build_ext --inplace
export LD_LIBRARY_PATH=../shared/build:$LD_LIBRARY_PATH
python3 benchmark.py
```

**Windows:**

```batch
REM Node.js benchmark
cd bindings\nodejs
npm install && npm run build
node benchmark.js

REM Python benchmark
cd bindings\python
python setup.py build_ext --inplace
python benchmark.py
```

**macOS:**

```bash
# Node.js benchmark
cd bindings/nodejs
npm install && npm run build
node benchmark.js

# Python benchmark
cd bindings/python
python setup.py build_ext --inplace
export DYLD_LIBRARY_PATH=../shared/build:$DYLD_LIBRARY_PATH
python3 benchmark.py
```

### ONNX Benchmarks

- **Node.js**: `node bindings/nodejs/benchmark_onnx.js`
- **Python**: `python bindings/python/benchmark_onnx.py`
- **C#**: `dotnet run --project bindings/csharp/benchmark_onnx.cs`
- **Java**: `java -cp bindings/java/java/target/classes -Djava.library.path=build benchmark_onnx`

## CI/CD Automated Benchmarks

Benchmarks run automatically in GitHub Actions CI/CD:

- **Trigger**: On every push to `master` or `release/*` branches
- **Platforms**: Linux x64, Windows x64, macOS ARM64
- **Languages**: C (Linux only), Node.js, Python
- **Results**: Aggregated in `benchmark-results-aggregated` artifact

**To access CI results**:

1. Go to GitHub Actions tab
2. Select latest workflow run
3. Download `benchmark-results-aggregated` artifact
4. Open `BENCHMARK_RESULTS_CI.md`

## System Configuration

### CI/CD Runners

Benchmarks run on GitHub Actions hosted runners:

- **Linux x64**: Ubuntu 22.04, 2-core x86-64, 7 GB RAM
- **Windows x64**: Windows Server 2022, 2-core x86-64, 7 GB RAM
- **macOS ARM64**: macOS 13+, Apple Silicon (M1/M2), 14 GB RAM

### Documenting Local System

When running benchmarks locally, document your system:

**Linux**:

```bash
lscpu | grep -E "Model name|Architecture|CPU\(s\)"
free -h
gcc --version
```

**Windows**:

```batch
wmic cpu get name,numberofcores
wmic computersystem get totalphysicalmemory
cl
```

**macOS**:

```bash
sysctl -n machdep.cpu.brand_string
sysctl hw.memsize
clang --version
```

## Results Location

After running benchmarks, check:

- **CI Results**: `BENCHMARK_RESULTS_CI.md` (from GitHub Actions artifact)
- **ONNX Results**: `BENCHMARK_RESULTS.md` - Complete ONNX results
- **Local Results**: Console output - Real-time results

---

For detailed instructions and system configuration, see [../../BENCHMARKS.md](../../BENCHMARKS.md).
