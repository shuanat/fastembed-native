#!/bin/bash
set -e

cd "$(dirname "$0")"

# Setup paths
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-11-openjdk-amd64}
export PROJ_ROOT="$(cd .. && pwd)"
export LD_LIBRARY_PATH="$PROJ_ROOT/shared/build:target/lib:$LD_LIBRARY_PATH"

echo "Building Java benchmark..."

# Create directories
mkdir -p target/classes target/lib target/test-classes

# Compile JNI wrapper
echo "Compiling JNI wrapper..."
JNI_SRC=""
if [ -f "java/native/fastembed_jni.c" ]; then
    JNI_SRC="java/native/fastembed_jni.c"
elif [ -f "native/fastembed_jni.c" ]; then
    JNI_SRC="native/fastembed_jni.c"
else
    echo "Error: JNI source file not found"
    exit 1
fi

gcc -shared -fPIC -O3 \
    -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" \
    -I"$PROJ_ROOT/shared/include" \
    -o target/lib/libfastembed.so \
    "$JNI_SRC" \
    "$PROJ_ROOT/shared/build/embedding_lib.o" \
    "$PROJ_ROOT/shared/build/embedding_generator.o" \
    "$PROJ_ROOT/shared/build/embedding_lib_c.o" \
    -lm

# Compile Java classes
echo "Compiling Java classes..."
JAVA_SRC=""
if [ -f "java/src/main/java/com/fastembed/FastEmbed.java" ]; then
    JAVA_SRC="java/src/main/java/com/fastembed/FastEmbed.java"
elif [ -f "src/main/java/com/fastembed/FastEmbed.java" ]; then
    JAVA_SRC="src/main/java/com/fastembed/FastEmbed.java"
else
    echo "Error: FastEmbed.java not found"
    exit 1
fi

BENCHMARK_SRC=""
if [ -f "src/test/java/FastEmbedBenchmark.java" ]; then
    BENCHMARK_SRC="src/test/java/FastEmbedBenchmark.java"
else
    echo "Error: FastEmbedBenchmark.java not found"
    exit 1
fi

javac -d target/classes "$JAVA_SRC"
javac -d target/test-classes -cp target/classes "$BENCHMARK_SRC"

echo "Build complete!"
echo ""
echo "To run benchmark:"
echo "  java -Djava.library.path=target/lib -cp target/classes:target/test-classes com.fastembed.FastEmbedBenchmark"

