# Changelog

All notable changes to FastEmbed will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- GitHub Actions CI/CD pipeline for automated builds and tests
- Comprehensive API documentation (docs/API.md)
- Architecture documentation (docs/ARCHITECTURE.md)
- Code of Conduct and Security Policy

### Changed

- Restructured project into language-specific `bindings/` directory
- Consolidated README.md to single English version
- Moved build guides to `docs/` directory

### Fixed

- (None yet)

---

## [1.0.0] - 2024-11-01

### Added

- **Core Features:**
  - Hash-based text embedding generation (768-dimensional vectors)
  - SIMD-optimized vector operations (dot product, cosine similarity, L2 norm, normalization, addition)
  - Assembly implementation (x86-64, SSE4/AVX2)
  - System V ABI compliance

- **Language Bindings:**
  - **Node.js:** N-API binding with `FastEmbedNativeClient` class (0.014-0.049 ms, measured)
  - **Python:** pybind11 binding with `FastEmbedNative` class (0.012-0.047 ms, measured)
  - **C#:** P/Invoke binding with `FastEmbedClient` class (0.014-0.051 ms, measured)
  - **Java:** JNI binding with `FastEmbed` class (0.013-0.048 ms, measured)

- **Build System:**
  - Cross-platform Makefile (Linux, macOS, Windows/WSL)
  - Language-specific build configurations (node-gyp, setup.py, dotnet, maven)
  - Automated assembly compilation and linking

- **Tests:**
  - Unit tests for all language bindings
  - Performance benchmarks
  - Integration tests (Weaviate + FastEmbed)

- **Documentation:**
  - Comprehensive README with quick start guide
  - Language-specific build guides (BUILD_NATIVE.md, BUILD_PYTHON.md, BUILD_CSHARP.md, BUILD_JAVA.md)
  - API reference and usage examples

### Performance

- Embedding generation: 0.01ms (Node.js/Python), 0.5-1ms (C#/Java)
- Throughput: 109k emb/s (Node.js/Python), 1-2k emb/s (C#/Java)
- SIMD speedup: 4-8x vs. scalar C implementation

### Platform Support

- Linux x86-64 (Ubuntu 20.04+, Debian 11+, Fedora 35+)
- Windows x64 (via WSL or MSYS2/MinGW)
- macOS x86-64 and ARM64 (M1/M2, via Rosetta)

---

## [0.2.0] - 2024-10-25

### Added

- C# P/Invoke binding
- Java JNI binding
- Root Makefile for building all bindings
- Integration tests with Weaviate vector database

### Changed

- Improved assembly ABI compliance (callee-saved registers, stack alignment)
- Refactored C wrapper functions for consistency

### Fixed

- Segmentation faults in `cosine_similarity_asm` due to incorrect register preservation
- Stack alignment issues in assembly functions
- FFI compatibility on Windows

---

## [0.1.0] - 2024-10-15

### Added

- Initial release with core C/Assembly library
- Node.js N-API binding
- Python pybind11 binding
- Hash-based embedding generation
- SIMD-optimized vector operations (dot product, cosine similarity, L2 norm)
- CLI tools for embedding generation and vector operations

### Platform Support

- Linux x86-64

---

## How to Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting bugs, requesting features, and submitting pull requests.

---

## Version History Summary

| Version | Date       | Highlights                                        |
| ------- | ---------- | ------------------------------------------------- |
| 1.0.0   | 2024-11-01 | Full multi-language support (4 bindings), ABI fix |
| 0.2.0   | 2024-10-25 | C# and Java bindings, Weaviate integration        |
| 0.1.0   | 2024-10-15 | Initial release (Node.js, Python, C library)      |

---

## Links

- [GitHub Repository](https://github.com/yourusername/fastembed)
- [Issue Tracker](https://github.com/yourusername/fastembed/issues)
- [Discussions](https://github.com/yourusername/fastembed/discussions)
- [Documentation](docs/)
