# Performance Benchmarks - How to Run

See [../BENCHMARKS.md](../BENCHMARKS.md) for the complete benchmarking guide.

## Quick Run

```bash
# Run all benchmarks
bash scripts/run_benchmarks.sh

# Results will be saved to BENCHMARK_RESULTS.md
```

## Individual Benchmarks

- **Node.js**: `node bindings/nodejs/benchmark.js`
- **Python**: `python bindings/python/benchmark.py`
- **C#**: `dotnet run --project bindings/csharp/benchmark.csproj`
- **Java**: See [../BENCHMARKS.md](../BENCHMARKS.md)

## Results Location

After running benchmarks, check:

- `BENCHMARK_RESULTS.md` - Complete results with system info
- Console output - Real-time results

---

For detailed instructions, see [../BENCHMARKS.md](../BENCHMARKS.md).
