# FastEmbed Documentation

Complete documentation for the FastEmbed high-performance embeddings library.

---

## 📚 Documentation Index

### Getting Started

- **[Main README](../README.md)** - Project overview, quick start, installation
- **[USE_CASES.md](USE_CASES.md)** - Real-world use cases and examples

### API Reference

- **[API.md](API.md)** - Complete API reference for all language bindings
  - C API (shared library)
  - Node.js API (N-API)
  - Python API (pybind11)
  - C# API (P/Invoke)
  - Java API (JNI)

### Architecture & Design

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture, data flow, design decisions
  - Layer responsibilities
  - Build system
  - Performance characteristics
  - Memory management
  - ABI compliance

### Build Guides

- **[BUILD_NATIVE.md](BUILD_NATIVE.md)** - Node.js N-API module build guide
- **[BUILD_PYTHON.md](BUILD_PYTHON.md)** - Python pybind11 module build guide
- **[BUILD_CSHARP.md](BUILD_CSHARP.md)** - C# P/Invoke module build guide
- **[BUILD_JAVA.md](BUILD_JAVA.md)** - Java JNI module build guide
- **[BUILD_WINDOWS.md](BUILD_WINDOWS.md)** - Windows-specific build instructions

---

## 📖 Documentation Structure

```
docs/
├── README.md              # This file (documentation index)
├── API.md                 # Complete API reference
├── ARCHITECTURE.md        # System design and architecture
├── USE_CASES.md           # Real-world use cases
├── BUILD_NATIVE.md        # Node.js build guide
├── BUILD_PYTHON.md        # Python build guide
├── BUILD_CSHARP.md        # C# build guide
├── BUILD_JAVA.md          # Java build guide
└── BUILD_WINDOWS.md       # Windows build guide
```

---

## 🚀 Quick Navigation

### I want to

**...understand what FastEmbed does**
→ Read [Main README](../README.md) and [USE_CASES.md](USE_CASES.md)

**...use FastEmbed in my project**
→ Check [API.md](API.md) for your language (Node.js, Python, C#, Java)

**...build FastEmbed from source**
→ See language-specific build guides:

- Node.js: [BUILD_NATIVE.md](BUILD_NATIVE.md)
- Python: [BUILD_PYTHON.md](BUILD_PYTHON.md)
- C#: [BUILD_CSHARP.md](BUILD_CSHARP.md)
- Java: [BUILD_JAVA.md](BUILD_JAVA.md)
- Windows: [BUILD_WINDOWS.md](BUILD_WINDOWS.md)

**...understand how FastEmbed works internally**
→ Read [ARCHITECTURE.md](ARCHITECTURE.md)

**...contribute to FastEmbed**
→ See [CONTRIBUTING.md](../CONTRIBUTING.md) and [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 📋 Documentation by Role

### For Users

Start here if you want to **use** FastEmbed in your application:

1. **[Main README](../README.md)** - Overview and quick start
2. **[API.md](API.md)** - API reference for your language
3. **[USE_CASES.md](USE_CASES.md)** - Real-world examples
4. **Language-specific build guide** - If building from source

### For Contributors

Start here if you want to **contribute** to FastEmbed:

1. **[CONTRIBUTING.md](../CONTRIBUTING.md)** - Contribution guidelines
2. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design and internals
3. **[API.md](API.md)** - API contracts and specifications
4. **[Build guides](.)** - How to build and test

### For Researchers

Start here if you want to **understand** FastEmbed's design:

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
2. **[Main README](../README.md)** - Performance benchmarks
3. **[API.md](API.md)** - API design rationale

---

## 🔧 Build Documentation

### Quick Build Reference

**All platforms (using Makefile):**

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

For detailed instructions, see the appropriate `BUILD_*.md` file.

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

- **Issues**: [GitHub Issues](https://github.com/yourusername/fastembed/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/fastembed/discussions)
- **Documentation**: You're here!

---

**Last updated:** November 1, 2024
