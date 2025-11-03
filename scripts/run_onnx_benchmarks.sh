#!/bin/bash
# Run ONNX benchmarks for all language bindings on Linux
# Requires: All bindings built, ONNX Runtime 1.23.2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$PROJECT_ROOT/benchmark_results"

echo "========================================"
echo "FastEmbed ONNX Benchmark Suite"
echo "========================================"
echo
echo "Results will be saved to: $RESULTS_DIR"
echo

mkdir -p "$RESULTS_DIR"

# Set library path
export LD_LIBRARY_PATH="$PROJECT_ROOT/bindings/shared/build:$LD_LIBRARY_PATH"

# Node.js ONNX Benchmark
echo "=== Node.js (N-API + ONNX) ==="
if [ -f "$PROJECT_ROOT/bindings/nodejs/benchmark_onnx.js" ]; then
    cd "$PROJECT_ROOT/bindings/nodejs"
    node benchmark_onnx.js
    if [ -f "benchmark_onnx_results.json" ]; then
        cp benchmark_onnx_results.json "$RESULTS_DIR/nodejs_onnx_results.json"
        echo "✓ Results saved to: benchmark_results/nodejs_onnx_results.json"
    fi
else
    echo "⚠️  benchmark_onnx.js not found, skipping"
fi
echo

# Python ONNX Benchmark
echo "=== Python (pybind11 + ONNX) ==="
if [ -f "$PROJECT_ROOT/bindings/python/benchmark_onnx.py" ]; then
    cd "$PROJECT_ROOT/bindings/python"
    python3 benchmark_onnx.py
    if [ -f "benchmark_onnx_results.json" ]; then
        cp benchmark_onnx_results.json "$RESULTS_DIR/python_onnx_results.json"
        echo "✓ Results saved to: benchmark_results/python_onnx_results.json"
    fi
else
    echo "⚠️  benchmark_onnx.py not found, skipping"
fi
echo

# C# ONNX Benchmark
echo "=== C# (P/Invoke + ONNX) ==="
if [ -f "$PROJECT_ROOT/bindings/csharp/benchmark_onnx.cs" ]; then
    cd "$PROJECT_ROOT/bindings/csharp"
    if command -v dotnet &> /dev/null; then
        dotnet run --project benchmark_onnx.cs 2>&1 || true
        if [ -f "benchmark_onnx_results.json" ]; then
            cp benchmark_onnx_results.json "$RESULTS_DIR/csharp_onnx_results.json"
            echo "✓ Results saved to: benchmark_results/csharp_onnx_results.json"
        fi
    else
        echo "⚠️  dotnet not found, skipping C# benchmark"
    fi
else
    echo "⚠️  benchmark_onnx.cs not found, skipping"
fi
echo

# Java ONNX Benchmark
echo "=== Java (JNI + ONNX) ==="
if [ -f "$PROJECT_ROOT/bindings/java/java/benchmark_onnx.java" ]; then
    cd "$PROJECT_ROOT/bindings/java/java"
    export LD_LIBRARY_PATH="$PROJECT_ROOT/bindings/java/java/build:$LD_LIBRARY_PATH"
    
    if command -v mvn &> /dev/null; then
        mvn compile -q
        if [ -d "target/classes" ]; then
            java -cp target/classes -Djava.library.path=build benchmark_onnx 2>&1 || true
        else
            echo "⚠️  Maven compilation failed, skipping Java benchmark"
        fi
    else
        echo "⚠️  mvn not found, skipping Java benchmark"
    fi
else
    echo "⚠️  benchmark_onnx.java not found, skipping"
fi
echo

# Aggregate results
echo "=== Aggregating Results ==="
if [ -f "$PROJECT_ROOT/scripts/aggregate_benchmarks.py" ]; then
    cd "$PROJECT_ROOT"
    python3 scripts/aggregate_benchmarks.py 2>&1 || true
else
    echo "⚠️  aggregate_benchmarks.py not found, skipping aggregation"
fi

echo
echo "========================================"
echo "✅ All ONNX benchmarks completed"
echo "========================================"
echo
echo "Results location: $RESULTS_DIR"
echo "Aggregated report: BENCHMARK_RESULTS.md"
echo

