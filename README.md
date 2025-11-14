# FastEmbed - High-Performance Multi-Language Embeddings Library

<div align="center">

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE) [![Commercial License Available](https://img.shields.io/badge/Commercial-License-orange.svg)](LICENSING.md)
[![Languages](https://img.shields.io/badge/languages-Node.js%20|%20Python%20|%20C%23%20|%20Java-blue)](bindings/)
[![Platform](https://img.shields.io/badge/platform-Linux%20|%20Windows%20|%20macOS-lightgrey)]()

**Ultra-fast text embeddings with native SIMD acceleration**

[Features](#-features) • [Languages](#-supported-languages) • [Performance](#-performance) • [Installation](#-quick-start) • [Documentation](#-documentation)

</div>

---

## 🎯 Overview

FastEmbed is a **cross-platform, multi-language** text embedding library providing:

- ⚡ **Blazing fast** hash-based embeddings (0.01-1ms per embedding)
- 🧠 **ONNX Runtime support** (1.23.2) for semantic embeddings (all 4 languages)
- 🌍 **4 native bindings**: Node.js, Python, C#, Java
- 🚀 **SIMD optimized** assembly code (SSE4/AVX2)
- 🔧 **Easy integration** with ML frameworks
- 📦 **Zero dependencies** (self-contained native libraries)

Perfect for real-time semantic search, large-scale text processing, edge deployment, and ML prototyping.

---

## ✨ Features

### Core Capabilities

- **Hash-based embeddings**: Deterministic, fast generation without neural networks
- **ONNX-based embeddings**: Semantic understanding with ONNX Runtime 1.23.2 (all 4 languages)
- **Vector operations**: Cosine similarity, dot product, normalization, addition
- **Batch processing**: Generate multiple embeddings efficiently
- **Text similarity**: High-level API for semantic comparison

### Technical Highlights

- **SIMD acceleration**: Hand-optimized x86-64 assembly (SSE4, AVX2)
- **Multi-threading**: Parallel processing support
- **Memory efficient**: Minimal memory footprint
- **Cross-platform**: Windows, Linux, macOS
- **ABI compliant**: Follows System V ABI for maximum compatibility

---

## 🌐 Supported Languages

| Language    | Binding  | Status  | Performance (ONNX, short text) | Install                              |
| ----------- | -------- | ------- | ------------------------------ | ------------------------------------ |
| **Java**    | JNI      | ✅ Ready | ⚡ 22.5 ms (45 emb/s)           | See [bindings/java/](bindings/java/) |
| **Node.js** | N-API    | ✅ Ready | ⚡ 27.1 ms (37 emb/s)           | `npm install && npm run build`       |
| **Python**  | pybind11 | ✅ Ready | ⚡ 28.6 ms (35 emb/s)           | `pip install .`                      |
| **C#**      | P/Invoke | ✅ Ready | ⚡ 28.5 ms (35 emb/s)           | `dotnet build`                       |

See [bindings/](bindings/) for detailed integration guides.

---

## 🚀 Performance

> **📊 Full Benchmarks:** See [BENCHMARK_RESULTS.md](BENCHMARK_RESULTS.md) for comprehensive performance data and methodology.

### Hash-based Embeddings (768-dimensional)

**Ultra-fast deterministic embeddings** - sub-millisecond performance:

- **Performance**: ~0.01-0.1 ms per embedding (~27,000 embeddings/sec average)
- **SIMD optimized**: Consistent performance across text lengths
- **Deterministic**: Same text always produces same embedding
- **Vector operations**: Sub-microsecond latency (see Vector Operations section below)

> **Note**: Hash-based embeddings are deterministic and fast, but lack semantic understanding. For semantic search, use ONNX-based embeddings below.

### ONNX-based Embeddings (768-dimensional, ONNX Runtime 1.23.2)

**All 4 language bindings support ONNX Runtime** - semantic understanding with quality embeddings:

| Language    | Short (108 chars) | Medium (460 chars) | Long (1574 chars) | Throughput (emb/s) |
| ----------- | ----------------- | ------------------ | ----------------- | ------------------ |
| **Java**    | 22.459 ms         | 47.361 ms          | 110.655 ms        | 45 (short)         |
| **Node.js** | 27.144 ms         | 53.582 ms          | 123.068 ms        | 37 (short)         |
| **Python**  | 28.569 ms         | 51.913 ms          | 123.028 ms        | 35 (short)         |
| **C#**      | 28.502 ms         | 54.355 ms          | 129.634 ms        | 35 (short)         |

**Key Features:**

- **Semantic quality**: 0.72 similarity for semantically similar texts, 0.59 for different
- **Batch processing**: 14-40 embeddings/sec (single), 14-17 emb/s (batch 100)
- **Memory efficient**: 0-0.3 MB overhead per embedding
- **Consistent performance** across all language bindings (8-45 emb/s depending on text length)

### Vector Operations

All bindings achieve **sub-microsecond** latency with SIMD optimizations:

- **Dot Product**: 0.000-0.001 ms (1M-5.6M ops/sec)
- **Cosine Similarity**: 0.001 ms (750K-2M ops/sec)  
- **Vector Norm**: 0.000-0.001 ms (1.4M-5.7M ops/sec)
- **Normalization**: 0.001-0.003 ms (350K-885K ops/sec)

*Tested on x86_64 (Windows/Linux) with GCC `-O3 -march=native`, SIMD instructions (AVX2/SSE4)*

---

## 🚀 Quick Start

### Prerequisites

**Windows**:

- Visual Studio 2022 Build Tools (with "Desktop development with C++")
- NASM >= 2.14 ([download](https://www.nasm.us/))
- Node.js 18+ (for Node.js binding)
- Python 3.7+ (for Python binding)
- .NET SDK 8.0+ (for C# binding)
- JDK 17+ and Maven (for Java binding)

**Linux/macOS**:

- NASM (assembler) >= 2.14
- C/C++ compiler (GCC 7+, Clang, or MSVC)
- Make

### Build Shared Native Library

**Windows**:

```batch
# Build shared library
python scripts\build_native.py

# Or use batch script
scripts\build_windows.bat
```

**Linux/macOS**:

```bash
# Clone repository
git clone https://github.com/shuanat/fastembed-native.git
cd fastembed-native

# Build shared C/Assembly library
make shared

# Or manually
cd bindings/shared
make all
make shared
cd ../..
```

**macOS** (alternative):

```bash
bash scripts/build_macos.sh
```

### Build All Language Bindings

**Windows**:

```batch
# Build all bindings at once
scripts\build_all_windows.bat

# Or build individually:
cd bindings\nodejs && npm install && npm run build
cd ..\python && python setup.py build_ext --inplace
cd ..\csharp\src && dotnet build
cd ..\..\java\java && mvn compile
```

**Linux/macOS**:

```bash
# Build all bindings
make all

# Or build individually (see language sections below)
```

### Choose Your Language

#### Node.js

**Windows**:

```batch
cd bindings\nodejs
npm install
npm run build
node test-native.js
```

**Linux/macOS**:

```bash
cd bindings/nodejs
npm install
npm run build
node test-native.js
```

```javascript
const { FastEmbedNativeClient } = require('./lib/fastembed-native');

const client = new FastEmbedNativeClient(768);
const embedding = client.generateEmbedding("machine learning");
console.log(embedding); // Float32Array[768]
```

#### Python

**Windows**:

```batch
REM Build shared native library first (required on Windows)
REM This produces embedding_lib.obj and embedding_generator.obj in bindings\shared\build\
scripts\build_windows.bat
REM Alternatively: python scripts\build_native.py

cd bindings\python
pip install pybind11 numpy
python setup.py build_ext --inplace
python test_python_native.py
```

Note (Windows): the Python extension links against precompiled assembly objects from
`bindings\shared\build\embedding_lib.obj` and `bindings\shared\build\embedding_generator.obj`.
If they are missing, build the shared library first using `scripts\build_windows.bat`
or `python scripts\build_native.py`.

**Linux/macOS**:

```bash
cd bindings/python
pip install pybind11 numpy
python setup.py build_ext --inplace
python test_python_native.py
```

```python
from fastembed_native import FastEmbedNative

client = FastEmbedNative(768)
embedding = client.generate_embedding("machine learning")
print(embedding.shape)  # (768,)
```

#### C #

**Windows**:

```batch
cd bindings\csharp\src
dotnet build FastEmbed.csproj
cd ..
dotnet build test_csharp_native.csproj
dotnet run --project test_csharp_native.csproj --no-build
```

**Linux/macOS**:

```bash
cd bindings/csharp/src
dotnet build FastEmbed.csproj
cd ..
LD_LIBRARY_PATH=../shared/build dotnet run --project test_csharp_native.csproj --no-build
```

```csharp
using FastEmbed;

var client = new FastEmbedClient(dimension: 768);
float[] embedding = client.GenerateEmbedding("machine learning");
```

#### Java

**Windows**:

```batch
cd bindings\java\java
mvn compile
cd ..
java -Djava.library.path=target\lib -cp "target\classes;target\lib\*" com.fastembed.FastEmbedBenchmark
```

**Linux/macOS**:

```bash
cd bindings/java/java
mvn compile
cd ..
java -Djava.library.path=target/lib -cp target/classes:target/lib/* com.fastembed.FastEmbedBenchmark
```

```java
import com.fastembed.FastEmbed;

FastEmbed client = new FastEmbed(768);
float[] embedding = client.generateEmbedding("machine learning");
```

---

## 💻 Usage Examples

### Vector Similarity

```python
# Python example
from fastembed_native import FastEmbedNative

client = FastEmbedNative(768)
emb1 = client.generate_embedding("artificial intelligence")
emb2 = client.generate_embedding("machine learning")

similarity = client.cosine_similarity(emb1, emb2)
print(f"Similarity: {similarity:.4f}")  # 0.9500+
```

### Batch Processing

```javascript
// Node.js example
const { FastEmbedNativeClient } = require('./lib/fastembed-native');

const client = new FastEmbedNativeClient(768);
const texts = ["AI", "ML", "NLP", "Computer Vision"];

const embeddings = texts.map(text => 
  client.generateEmbedding(text)
);

console.log(`Generated ${embeddings.length} embeddings`);
```

---

## 📚 API Reference

### Core Functions

#### `generateEmbedding(text, dimension)`

Generate embedding from text.

- **Parameters**:
  - `text` (string) - Input text
  - `dimension` (int) - Embedding dimension (e.g., 768)
- **Returns**: Float array/vector

#### `cosineSimilarity(vec1, vec2)`

Calculate cosine similarity between two vectors.

- **Returns**: `float` - Similarity score (-1 to 1)

#### `dotProduct(vec1, vec2)`

Calculate dot product of two vectors.

#### `vectorNorm(vec)`

Calculate L2 norm of a vector.

#### `normalizeVector(vec)`

Normalize vector to unit length (L2 normalization).

#### `addVectors(vec1, vec2)`

Element-wise vector addition.

See each binding's README for language-specific API details.

---

## 🏗️ Project Structure

```
fastembed/
├── bindings/
│   ├── shared/           # C/Assembly core library
│   │   ├── src/          # Assembly + C implementation
│   │   ├── include/      # Public headers
│   │   └── Makefile      # Build configuration
│   ├── nodejs/           # Node.js N-API binding
│   ├── python/           # Python pybind11 binding
│   ├── csharp/           # C# P/Invoke binding
│   └── java/             # Java JNI binding
├── scripts/              # Build automation scripts
├── docs/                 # Documentation
├── tests/                # Integration tests
├── Makefile              # Root build system
└── README.md             # This file
```

---

## 🔧 Building from Source

### Build All Bindings

```bash
# Root directory
make all          # Build shared library + all bindings
make shared       # Build shared library only
make nodejs       # Build Node.js binding
make python       # Build Python binding
make csharp       # Build C# binding
make java         # Build Java binding
make test         # Run all tests
make clean        # Clean build artifacts
```

### Platform-Specific Notes

**Windows**: Full native build support with Visual Studio.

```batch
# Build all bindings
scripts\build_all_windows.bat

# Run all tests
scripts\test_all_windows.bat
```

**Linux/macOS**: Use Makefile.

```bash
make all    # Build all
make test   # Run tests
```

**macOS** (alternative):

```bash
bash scripts/build_macos.sh
```

See [bindings/shared/README.md](bindings/shared/README.md) for detailed build instructions.

---

## 🧪 Testing

### Core Library Tests (C/Assembly)

**Windows**:

```batch
# Build and run all tests
scripts\build_cmake_windows.bat
cd bindings\shared\build_cmake
ctest -C Release

# Or run individual tests
Release\test_hash_functions.exe
Release\test_embedding_generation.exe
Release\test_sqrt_quality.exe
Release\benchmark_improved.exe
```

**Linux/WSL**:

```bash
# Build and run all tests
bash scripts/build_cmake_linux.sh
cd bindings/shared/build_cmake
ctest

# Or run individual tests
./test_hash_functions
./test_embedding_generation
./test_sqrt_quality
./benchmark_improved
```

**See:** [tests/README_TESTING.md](tests/README_TESTING.md) for detailed testing guide.

### Language Bindings Tests

**Windows**:

```batch
# Run all tests
scripts\test_all_windows.bat

# Or test individually
cd bindings\nodejs && node test-native.js
cd ..\python && python test_python_native.py
cd ..\csharp && dotnet run --project test_csharp_native.csproj
cd ..\java\java && mvn test
```

**Linux/macOS**:

```bash
# Test all bindings
make test

# Or test individually
cd bindings/nodejs && node test-native.js
cd bindings/python && python test_python_native.py
cd bindings/csharp && LD_LIBRARY_PATH=../shared/build dotnet run --project test_csharp_native.csproj
cd bindings/java && mvn test
```

---

## 📖 Documentation

| Document                    | Description                       |
| --------------------------- | --------------------------------- |
| [bindings/shared/README.md] | Shared C/Assembly library         |
| [bindings/nodejs/README.md] | Node.js binding guide             |
| [bindings/python/README.md] | Python binding guide              |
| [bindings/csharp/README.md] | C# binding guide                  |
| [bindings/java/README.md]   | Java binding guide                |
| [docs/ARCHITECTURE.md]      | System architecture and design    |
| [docs/API.md]               | Complete API reference            |
| [CONTRIBUTING.md]           | Contribution guidelines           |
| [CHANGELOG.md]              | Version history and release notes |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│   User Application (4 language bindings)    │
│   Node.js │ Python │ C# │ Java              │
└────┬──────┴───┬────┴────┬────┴──────────────┘
     │          │         │         │
     ▼          ▼         ▼         ▼
┌────────────────────────────────────────────┐
│         Language Binding Layer             │
│  N-API │ pybind11 │ P/Invoke │ JNI         │
└────────────────┬───────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────┐
│       FastEmbed C Library (shared/)        │
│  - Hash-based embedding generation         │
│  - Vector operations (dot, cosine, norm)   │
└────────────────┬───────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────┐
│   Optimized Assembly Code (x86-64)         │
│  - SIMD instructions (SSE4, AVX2)          │
│  - Hand-optimized hot paths                │
│  - System V ABI compliant                  │
└────────────────────────────────────────────┘
```

---

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Contribution

- 🐛 Bug fixes and stability improvements
- ✨ New language bindings (Go, Rust, Ruby)
- 📚 Documentation improvements
- 🚀 Performance optimizations
- 🧪 Test coverage expansion
- 💡 Use case examples

---

## 📄 License

Dual-licensed under **AGPL-3.0** and a **Commercial License**:

- Open Source: see [LICENSE](LICENSE)
- Commercial licensing (closed source/SaaS): see [LICENSING.md](LICENSING.md) and [LICENSE-COMMERCIAL.md](LICENSE-COMMERCIAL.md)

---

## 🙏 Acknowledgments

Built with:

- [NASM](https://www.nasm.us/) - Netwide Assembler
- [Node-API](https://nodejs.org/api/n-api.html) - Node.js native bindings
- [pybind11](https://github.com/pybind/pybind11) - Python C++ bindings
- [P/Invoke](https://learn.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke) - .NET native interop
- [JNI](https://docs.oracle.com/en/java/javase/11/docs/specs/jni/) - Java Native Interface

---

## 📞 Support

- 📖 [Documentation](docs/)
- 🐛 Issue Tracker (GitHub Issues)
- 💬 Discussions (GitHub Discussions)
- 📝 **Commercial License Requests:** open a GitHub Issue → "License Request" template

---

<div align="center">

**Made with ❤️ for developers who need fast, reliable embeddings**

⭐ **Star us on GitHub** if you find this useful!

</div>
