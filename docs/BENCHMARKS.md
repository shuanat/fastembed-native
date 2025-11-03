# Performance Benchmarks - How to Run

See [../BENCHMARKS.md](../BENCHMARKS.md) for the complete benchmarking guide.

## Quick Run

```bash
# Run all benchmarks
bash scripts/run_benchmarks.sh

# Results will be saved to BENCHMARK_RESULTS.md
```

## Individual Benchmarks

### ONNX Benchmarks

- **Node.js**: `node bindings/nodejs/benchmark_onnx.js`
- **Python**: `python bindings/python/benchmark_onnx.py`
- **C#**: `dotnet run --project bindings/csharp/benchmark_onnx.cs`
- **Java**: `java -cp bindings/java/java/target/classes -Djava.library.path=build benchmark_onnx`

### Run All ONNX Benchmarks

**Windows:**

```batch
scripts\run_onnx_benchmarks.bat
```

**Linux:**

```bash
bash scripts/run_onnx_benchmarks.sh
```

## Results Location

After running benchmarks, check:

- `BENCHMARK_RESULTS.md` - Complete results with system info
- Console output - Real-time results

---

For detailed instructions, see [../BENCHMARKS.md](../BENCHMARKS.md).
