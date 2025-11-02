#!/bin/bash
# Run all FastEmbed benchmarks and collect results

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "FastEmbed Comprehensive Benchmark Suite"
echo "========================================"
echo ""
echo "Building shared library..."
cd "$PROJECT_ROOT/bindings/shared"
make clean && make all
echo "✅ Shared library built"
echo ""

RESULTS_FILE="$PROJECT_ROOT/BENCHMARK_RESULTS.md"

# Initialize results file
cat > "$RESULTS_FILE" << 'EOF'
# FastEmbed Performance Benchmarks

**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**System:** $(uname -s) $(uname -m)
**CPU:** $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)

---

## Test Configuration

- **Iterations:** 1000
- **Dimension:** 768
- **Warmup:** 100 iterations

---

EOF

echo "Running benchmarks..."
echo ""

# Node.js Benchmark
echo "=== Node.js (N-API) ==="
cd "$PROJECT_ROOT/bindings/nodejs"
if [ -f "benchmark.js" ]; then
    echo ""  >> "$RESULTS_FILE"
    echo "## Node.js (N-API)" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo '```' >> "$RESULTS_FILE"
    node benchmark.js | tee -a "$RESULTS_FILE"
    echo '```' >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
else
    echo "⚠️  benchmark.js not found, skipping"
fi
echo ""

# Python Benchmark
echo "=== Python (pybind11) ==="
cd "$PROJECT_ROOT/bindings/python"
if [ -f "benchmark.py" ]; then
    echo "" >> "$RESULTS_FILE"
    echo "## Python (pybind11)" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo '```' >> "$RESULTS_FILE"
    LD_LIBRARY_PATH="$PROJECT_ROOT/bindings/shared/build" python3 benchmark.py | tee -a "$RESULTS_FILE"
    echo '```' >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
else
    echo "⚠️  benchmark.py not found, skipping"
fi
echo ""

# C# Benchmark
echo "=== C# (P/Invoke) ==="
cd "$PROJECT_ROOT/bindings/csharp"
if [ -f "run_benchmark.sh" ]; then
    export PATH="$HOME/.dotnet:$PATH"
    export LD_LIBRARY_PATH="$PROJECT_ROOT/bindings/shared/build"
    echo "" >> "$RESULTS_FILE"
    echo "## C# (P/Invoke)" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo '```' >> "$RESULTS_FILE"
    bash run_benchmark.sh 2>&1 | grep -A 1000 "FastEmbed C#" | tee -a "$RESULTS_FILE"
    echo '```' >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
else
    echo "⚠️  run_benchmark.sh not found, skipping"
fi
echo ""

# Java Benchmark
echo "=== Java (JNI) ==="
cd "$PROJECT_ROOT/bindings/java"
if [ -f "run_benchmark.sh" ]; then
    export LD_LIBRARY_PATH="$PROJECT_ROOT/bindings/shared/build"
    echo "" >> "$RESULTS_FILE"
    echo "## Java (JNI)" >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
    echo '```' >> "$RESULTS_FILE"
    bash run_benchmark.sh 2>&1 | grep -A 1000 "FastEmbed Java" | tee -a "$RESULTS_FILE"
    echo '```' >> "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"
else
    echo "⚠️  run_benchmark.sh not found, skipping"
fi
echo ""

# Summary
cat >> "$RESULTS_FILE" << 'EOF'
---

## Notes

- All benchmarks measure **average time** over 1000 iterations after 100 warmup iterations
- **Embedding generation** tests use various text lengths
- **Vector operations** use pre-generated 768-dimensional embeddings
- Results may vary depending on system load, CPU frequency scaling, and other factors

## Recommendations

For **production use**, choose based on:

1. **Language ecosystem**: Use the binding that matches your primary language
2. **Performance requirements**: All bindings provide sub-millisecond vector operations
3. **Integration complexity**: Native bindings (N-API, pybind11, P/Invoke, JNI) offer better type safety

Run this benchmark in your target environment for accurate performance characteristics.
EOF

echo "========================================"
echo "✅ All benchmarks completed!"
echo ""
echo "Results saved to: $RESULTS_FILE"
echo "========================================"

