# FastEmbed Java Binding

Native Java binding using JNI for ultra-fast embeddings and vector operations.

## Installation

```bash
mvn clean install
```

## Usage

```java
import com.fastembed.FastEmbed;

FastEmbed client = new FastEmbed(256);

// Generate embedding
float[] embedding = client.generateEmbedding("Hello, world!");

// Vector operations
float similarity = client.cosineSimilarity(vec1, vec2);
float norm = client.vectorNorm(embedding);
float[] normalized = client.normalizeVector(embedding);
```

## API

See main [FastEmbed README](../../README.md) for full API documentation.

## Building

### Prerequisites

- JDK 11+
- Maven 3.6+
- NASM (for assembly)
- C compiler (MSVC on Windows, GCC/Clang on Linux/macOS)

### Build Commands

```bash
# Build shared library first
cd ../shared && make all

# Compile JNI wrapper
cd ../java
gcc -shared -fPIC -O3 \
    -I"${JAVA_HOME}/include" -I"${JAVA_HOME}/include/linux" \
    -o target/lib/libfastembed.so \
    native/fastembed_jni.c \
    ../shared/build/*.o -lm

# Build Java project
mvn clean install

# Run tests
java -Djava.library.path=target/lib -cp target/fastembed-1.0-SNAPSHOT.jar TestFastEmbedJava
```

## Performance

**Measured Performance** (Nov 2025):

- Embedding generation: **0.013-0.048 ms** (20K-78K ops/sec)
- Vector operations: **Sub-microsecond** (up to **1.97M ops/sec**)

See [BENCHMARK_RESULTS.md](../../BENCHMARK_RESULTS.md) for complete benchmark data.
