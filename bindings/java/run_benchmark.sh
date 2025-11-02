#!/bin/bash
set -e

cd "$(dirname "$0")"

# Build first
bash build_benchmark.sh

# Run benchmark
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-11-openjdk-amd64}
export PROJ_ROOT="$(cd .. && pwd)"
export LD_LIBRARY_PATH="$PROJ_ROOT/shared/build:target/lib:$LD_LIBRARY_PATH"

echo ""
echo "Running benchmark..."
java -Djava.library.path=target/lib -cp target/classes:target/test-classes com.fastembed.FastEmbedBenchmark

