# FastEmbed Documentation

Complete documentation for the FastEmbed high-performance embeddings library.

**Last Updated**: 2025-01-14  
**Version**: 1.0.1

---

## 📚 Documentation Index

### 🚀 Getting Started

**New to FastEmbed? Start here:**

- **[Main README](../README.md)** - Project overview, quick start, installation guide
- **[USE_CASES.md](USE_CASES.md)** - Real-world use cases and practical examples

**Quick Links:**

- [Installation Guide](../README.md#installation)
- [Quick Start Examples](../README.md#quick-start)
- [Performance Overview](../README.md#-performance)

---

### 📖 API Reference

**Complete API documentation for all language bindings:**

- **[API.md](API.md)** - Comprehensive API reference
  - **C API** (shared library) - Core functions, vector operations, ONNX API
  - **Node.js API** (N-API) - JavaScript/TypeScript bindings
  - **Python API** (pybind11) - NumPy integration
  - **C# API** (P/Invoke) - .NET bindings
  - **Java API** (JNI) - JVM bindings

**Quick Reference:**

- [Hash-Based Embeddings](API.md#core-functions) - `generateEmbedding()`, `batchGenerateEmbedding()`
- [ONNX Embeddings](API.md#onnx-functions) - `generateOnnxEmbedding()`, `unloadOnnxModel()`
- [Vector Operations](API.md#vector-operations) - `cosineSimilarity()`, `dotProduct()`, `normalizeVector()`

---

### 🏗️ Architecture & Design

**Deep dive into FastEmbed's internal design:**

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture with Mermaid diagrams
  - System overview (5-layer architecture)
  - Data flow diagrams (Hash-based, ONNX, Batch)
  - Component interactions
  - Build system flow
  - Memory management
  - Performance characteristics
  - ABI compliance

**Algorithm & Implementation Details:**

- **[ALGORITHM_SPECIFICATION.md](ALGORITHM_SPECIFICATION.md)** - Hash-based embedding algorithm specification
  - Square Root normalization
  - Positional hashing
  - Dimension support
  - Quality metrics

- **[ALGORITHM_MATH.md](ALGORITHM_MATH.md)** - Mathematical foundation
  - Algorithm theory
  - Normalization properties
  - Quality improvement analysis
  - Experimental validation

- **[ASSEMBLY_DESIGN.md](ASSEMBLY_DESIGN.md)** - Assembly implementation design
  - x86-64 SIMD optimization
  - ABI compliance (System V, Microsoft x64)
  - Performance optimizations

**Reading Order:**

1. Start with [ARCHITECTURE.md](ARCHITECTURE.md) for system overview
2. Read [ALGORITHM_SPECIFICATION.md](ALGORITHM_SPECIFICATION.md) for algorithm details
3. Review [ALGORITHM_MATH.md](ALGORITHM_MATH.md) for mathematical foundation
4. Study [ASSEMBLY_DESIGN.md](ASSEMBLY_DESIGN.md) for low-level implementation

---

### 🔧 Build Guides

**Platform and language-specific build instructions:**

#### By Language

- **[BUILD_NATIVE.md](BUILD_NATIVE.md)** - Node.js N-API module build guide
- **[BUILD_PYTHON.md](BUILD_PYTHON.md)** - Python pybind11 module build guide
- **[BUILD_CSHARP.md](BUILD_CSHARP.md)** - C# P/Invoke module build guide
- **[BUILD_JAVA.md](BUILD_JAVA.md)** - Java JNI module build guide

#### By Platform

- **[BUILD_WINDOWS.md](BUILD_WINDOWS.md)** - Windows-specific build instructions
- **[BUILD_CMAKE.md](BUILD_CMAKE.md)** - CMake build system (cross-platform, recommended)

**Quick Build Reference:**

| Platform    | Language | Build Guide                                                            |
| ----------- | -------- | ---------------------------------------------------------------------- |
| Linux/macOS | All      | [BUILD_CMAKE.md](BUILD_CMAKE.md) or [BUILD_NATIVE.md](BUILD_NATIVE.md) |
| Windows     | All      | [BUILD_WINDOWS.md](BUILD_WINDOWS.md)                                   |
| Any         | Node.js  | [BUILD_NATIVE.md](BUILD_NATIVE.md)                                     |
| Any         | Python   | [BUILD_PYTHON.md](BUILD_PYTHON.md)                                     |
| Any         | C#       | [BUILD_CSHARP.md](BUILD_CSHARP.md)                                     |
| Any         | Java     | [BUILD_JAVA.md](BUILD_JAVA.md)                                         |

**Prerequisites Checklist:**

- ✅ NASM (x86-64 assembler)
- ✅ C Compiler (GCC, Clang, or MSVC)
- ✅ Language-specific tools (Node.js, Python, .NET SDK, JDK)
- ✅ CMake 3.15+ (optional, for CMake build)

---

### 🔬 Advanced Topics

**For advanced users and contributors:**

- **[BENCHMARKS.md](BENCHMARKS.md)** - How to run performance benchmarks
- **[RELEASING.md](RELEASING.md)** - Release process and versioning guide
- **[TESTING_WORKFLOWS.md](TESTING_WORKFLOWS.md)** - Testing GitHub Actions workflows

---

## 📖 Documentation Structure

```
docs/
├── README.md                      # This file (documentation index)
│
├── Getting Started
│   └── USE_CASES.md               # Real-world use cases
│
├── API Reference
│   └── API.md                     # Complete API reference
│
├── Architecture & Design
│   ├── ARCHITECTURE.md            # System architecture (with Mermaid diagrams)
│   ├── ALGORITHM_SPECIFICATION.md # Algorithm specification
│   ├── ALGORITHM_MATH.md          # Mathematical foundation
│   └── ASSEMBLY_DESIGN.md         # Assembly implementation
│
├── Build Guides
│   ├── BUILD_NATIVE.md            # Node.js build
│   ├── BUILD_PYTHON.md            # Python build
│   ├── BUILD_CSHARP.md            # C# build
│   ├── BUILD_JAVA.md              # Java build
│   ├── BUILD_WINDOWS.md           # Windows-specific
│   └── BUILD_CMAKE.md             # CMake build (recommended)
│
└── Advanced Topics
    ├── BENCHMARKS.md              # Performance benchmarks
    ├── RELEASING.md               # Release process
    └── TESTING_WORKFLOWS.md       # CI/CD workflows
```

---

## 🚀 Quick Navigation

### I want to

**...understand what FastEmbed does**
→ Start with [Main README](../README.md) and [USE_CASES.md](USE_CASES.md)

**...use FastEmbed in my project**
→ Check [API.md](API.md) for your language:

- **Node.js**: [Node.js API](API.md#nodejs-api)
- **Python**: [Python API](API.md#python-api)
- **C#**: [C# API](API.md#c-api)
- **Java**: [Java API](API.md#java-api)

**...build FastEmbed from source**
→ Choose your build method:

- **CMake** (recommended): [BUILD_CMAKE.md](BUILD_CMAKE.md)
- **Language-specific**: [BUILD_NATIVE.md](BUILD_NATIVE.md), [BUILD_PYTHON.md](BUILD_PYTHON.md), [BUILD_CSHARP.md](BUILD_CSHARP.md), [BUILD_JAVA.md](BUILD_JAVA.md)
- **Windows**: [BUILD_WINDOWS.md](BUILD_WINDOWS.md)

**...understand how FastEmbed works internally**
→ Read [ARCHITECTURE.md](ARCHITECTURE.md) with visual Mermaid diagrams

**...learn about the algorithm**
→ Study [ALGORITHM_SPECIFICATION.md](ALGORITHM_SPECIFICATION.md) and [ALGORITHM_MATH.md](ALGORITHM_MATH.md)

**...contribute to FastEmbed**
→ See [CONTRIBUTING.md](../CONTRIBUTING.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [ASSEMBLY_DESIGN.md](ASSEMBLY_DESIGN.md)

**...run benchmarks**
→ Follow [BENCHMARKS.md](BENCHMARKS.md) guide

**...create a release**
→ See [RELEASING.md](RELEASING.md) for release process

---

## 📋 Documentation by Role

### 👤 For Users

**Start here if you want to use FastEmbed in your application:**

1. **[Main README](../README.md)** - Overview, installation, quick start
2. **[USE_CASES.md](USE_CASES.md)** - Real-world examples and use cases
3. **[API.md](API.md)** - API reference for your language (Node.js, Python, C#, Java)
4. **Language-specific build guide** - If building from source:
   - Node.js: [BUILD_NATIVE.md](BUILD_NATIVE.md)
   - Python: [BUILD_PYTHON.md](BUILD_PYTHON.md)
   - C#: [BUILD_CSHARP.md](BUILD_CSHARP.md)
   - Java: [BUILD_JAVA.md](BUILD_JAVA.md)

**Common Tasks:**

- [Generate embeddings](API.md#core-functions) - Hash-based or ONNX
- [Calculate similarity](API.md#vector-operations) - Cosine similarity, dot product
- [Batch processing](API.md#core-functions) - Process multiple texts efficiently

---

### 👨‍💻 For Contributors

**Start here if you want to contribute to FastEmbed:**

1. **[CONTRIBUTING.md](../CONTRIBUTING.md)** - Contribution guidelines, Git workflow, coding standards
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design, data flow, component interactions
3. **[API.md](API.md)** - API contracts and specifications
4. **[ASSEMBLY_DESIGN.md](ASSEMBLY_DESIGN.md)** - Assembly implementation details
5. **Build guides** - How to build and test:
   - [BUILD_CMAKE.md](BUILD_CMAKE.md) - Recommended CMake build
   - [BUILD_WINDOWS.md](BUILD_WINDOWS.md) - Windows-specific instructions
6. **[TESTING_WORKFLOWS.md](TESTING_WORKFLOWS.md)** - CI/CD workflow testing

**Key Areas:**

- [System Architecture](ARCHITECTURE.md#system-overview) - Understand the 5-layer design
- [Build System](ARCHITECTURE.md#build-system) - How components are built
- [Memory Management](ARCHITECTURE.md#memory-management) - Allocation strategies
- [ABI Compliance](ARCHITECTURE.md#abi-compliance-system-v-x86-64) - Assembly requirements

---

### 🔬 For Researchers

**Start here if you want to understand FastEmbed's design and algorithms:**

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture with visual diagrams
2. **[ALGORITHM_SPECIFICATION.md](ALGORITHM_SPECIFICATION.md)** - Algorithm specification and design
3. **[ALGORITHM_MATH.md](ALGORITHM_MATH.md)** - Mathematical foundation and theory
4. **[ASSEMBLY_DESIGN.md](ASSEMBLY_DESIGN.md)** - Low-level implementation details
5. **[Main README](../README.md#-performance)** - Performance benchmarks and metrics
6. **[BENCHMARKS.md](BENCHMARKS.md)** - How to run and analyze benchmarks

**Research Topics:**

- [Hash-Based Embeddings](ALGORITHM_SPECIFICATION.md) - Algorithm design and quality metrics
- [Square Root Normalization](ALGORITHM_MATH.md#square-root-normalization-mathematical-properties) - Mathematical properties
- [SIMD Optimization](ASSEMBLY_DESIGN.md) - Performance optimizations
- [Performance Analysis](ARCHITECTURE.md#performance-characteristics) - Detailed performance data

---

## 🔧 Build Documentation

### Quick Build Reference

**Recommended: CMake (cross-platform)**

```bash
# CMake build (recommended)
cmake -B build -S .
cmake --build build
```

See [BUILD_CMAKE.md](BUILD_CMAKE.md) for detailed CMake instructions.

**Alternative: Makefile (Linux/macOS)**

```bash
make all      # Build everything
make test     # Run tests
make clean    # Clean build artifacts
```

**Language-specific builds:**

```bash
# Node.js
cd bindings/nodejs && npm install && npm run build

# Python
cd bindings/python && python setup.py build_ext --inplace

# C#
cd bindings/csharp && dotnet build

# Java
cd bindings/java && mvn install
```

**Windows-specific:**

See [BUILD_WINDOWS.md](BUILD_WINDOWS.md) for Windows build instructions.

### Build Guide Selection

| Your Situation          | Recommended Guide                    |
| ----------------------- | ------------------------------------ |
| **First time building** | [BUILD_CMAKE.md](BUILD_CMAKE.md)     |
| **Windows user**        | [BUILD_WINDOWS.md](BUILD_WINDOWS.md) |
| **Node.js developer**   | [BUILD_NATIVE.md](BUILD_NATIVE.md)   |
| **Python developer**    | [BUILD_PYTHON.md](BUILD_PYTHON.md)   |
| **C# developer**        | [BUILD_CSHARP.md](BUILD_CSHARP.md)   |
| **Java developer**      | [BUILD_JAVA.md](BUILD_JAVA.md)       |
| **Cross-platform**      | [BUILD_CMAKE.md](BUILD_CMAKE.md)     |

---

## 📊 Performance Documentation

Performance benchmarks are documented in:

- **[BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md)** - Complete measured performance data (Nov 1, 2025)
- **[BENCHMARKS.md](../BENCHMARKS.md)** - How to run benchmarks yourself
- **[Main README](../README.md#-performance)** - High-level performance summary
- **[ARCHITECTURE.md](ARCHITECTURE.md#performance-characteristics)** - Detailed performance analysis
- **Binding READMEs** - Language-specific performance notes:
  - [bindings/nodejs/README.md](../bindings/nodejs/README.md)
  - [bindings/python/README.md](../bindings/python/README.md)
  - [bindings/csharp/README.md](../bindings/csharp/README.md)
  - [bindings/java/README.md](../bindings/java/README.md)

---

## 🔗 External Resources

### SIMD & Assembly

- [Intel SIMD Intrinsics Guide](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html)
- [System V ABI x86-64](https://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf)

### Language Bindings

- [Node.js N-API Documentation](https://nodejs.org/api/n-api.html)
- [pybind11 Documentation](https://pybind11.readthedocs.io/)
- [P/Invoke Documentation](https://learn.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke)
- [JNI Specification](https://docs.oracle.com/en/java/javase/11/docs/specs/jni/)

### Build Tools

- [NASM Documentation](https://www.nasm.us/docs.php)
- [node-gyp Documentation](https://github.com/nodejs/node-gyp)
- [CMake Documentation](https://cmake.org/documentation/)

---

## 🤝 Contributing to Documentation

Found a typo or want to improve documentation? See [CONTRIBUTING.md](../CONTRIBUTING.md).

### Documentation Guidelines

- **Clear and concise** - Avoid jargon when possible
- **Examples included** - Show, don't just tell
- **Platform-specific** - Note differences between Linux/Windows/macOS
- **Code samples** - Include runnable code examples
- **Keep updated** - Update docs when changing code

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/shuanat/fastembed-native/issues)
- **Discussions**: [GitHub Discussions](https://github.com/shuanat/fastembed-native/discussions)
- **Documentation**: You're here!

---

---

## 🔍 Search Tips

**Looking for something specific?**

- **API functions**: Search in [API.md](API.md)
- **Build issues**: Check [BUILD_WINDOWS.md](BUILD_WINDOWS.md) or [BUILD_CMAKE.md](BUILD_CMAKE.md)
- **Performance**: See [ARCHITECTURE.md#performance-characteristics](ARCHITECTURE.md#performance-characteristics)
- **Algorithm details**: Read [ALGORITHM_SPECIFICATION.md](ALGORITHM_SPECIFICATION.md)
- **Use cases**: Browse [USE_CASES.md](USE_CASES.md)

---

## 📊 Documentation Statistics

- **Total Files**: 16 documentation files
- **Categories**: 5 (Getting Started, API, Architecture, Build, Advanced)
- **Languages Covered**: 4 (Node.js, Python, C#, Java)
- **Platforms Covered**: 3 (Linux, Windows, macOS)
- **Diagrams**: 8 Mermaid diagrams in ARCHITECTURE.md

---

**Last Updated**: 2025-01-14  
**Documentation Version**: 1.0.1
