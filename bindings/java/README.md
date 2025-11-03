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

**ONNX Runtime Performance** (Nov 2025):

- ONNX embeddings: **22.5-110.7 ms** (8-45 emb/s depending on text length)
  - Short text (108 chars): **22.5 ms** (45 emb/s) - fastest!
  - Medium text (460 chars): **47.4 ms** (21 emb/s)
  - Long text (1574 chars): **110.7 ms** (9 emb/s)
- Hash-based embeddings: **~0.01-0.1 ms** (~27,000 emb/s average)
- Vector operations: **Sub-microsecond** latency

See [BENCHMARK_RESULTS.md](../../BENCHMARK_RESULTS.md) for complete benchmark data.
