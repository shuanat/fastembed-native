# Changelog

All notable changes to FastEmbed will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- (Future improvements will be listed here)

---

## [1.0.1] - 2025-01-16

### Added

- **Improved Hash-Based Algorithm:**
  - Square Root normalization for better embedding quality (3.9x improvement over linear)
  - Positional hashing for improved semantic similarity
  - Configurable vector dimensions: 128, 256, 512, 768, 1024, 2048
  - Support for all dimensions in batch API

- **ONNX Runtime Integration:**
  - Automatic ONNX model dimension detection
  - Dimension validation for ONNX models
  - Model caching for improved performance
  - ONNX API functions: `fastembed_onnx_generate()`, `fastembed_onnx_unload()`, `fastembed_onnx_get_last_error()`, `fastembed_onnx_get_model_dimension()`

- **C# Test Suite:**
  - Comprehensive xUnit test suite with 56+ tests
  - Unit tests (happy path, edge cases, error handling)
  - Integration tests (end-to-end workflows)
  - ONNX tests (conditional, skip if ONNX unavailable)
  - Performance benchmarks

- **Documentation:**
  - ONNX API documentation (to be completed in Phase 2)
  - Test documentation for C# binding
  - **Documentation Restructure and Enhancement (2025-01-14):**
    - Enhanced ARCHITECTURE.md with 8 Mermaid diagrams (system architecture, data flow, component interactions, build system, memory management, ONNX architecture)
    - Reorganized documentation structure with clear taxonomy (Getting Started, API Reference, Architecture & Design, Build Guides, Advanced Topics)
    - Enhanced docs/README.md as comprehensive documentation index with role-based navigation paths
    - Added cross-references ("See Also" sections) to all major documentation files
    - Added navigation breadcrumbs to all documentation files
    - Consolidated overlapping content in BUILD_*.md files with cross-references
    - Translated all documentation to English (100% English coverage)
    - Improved navigation and discoverability of documentation
  - **Branching Strategy Documentation (2025-01-16):**
    - Added comprehensive BRANCHING_STRATEGY.md with Git Flow workflow
    - Updated CONTRIBUTING.md with new branching strategy
    - Updated CI workflow triggers for release branches

- **Scripts Restructure and Refactor (2025-01-14):**
  - Removed 13 unused scripts (70% reduction: from 19 to 5 scripts)
  - Refactored all remaining scripts to enterprise standards:
    - Comprehensive error handling with proper exit codes
    - Structured logging with [INFO], [WARN], [ERROR] prefixes
    - Complete documentation headers with purpose, usage, requirements, platform support
    - Consistent code style (English-only comments and output)
  - Updated all documentation references to reflect script changes
  - Improved script quality from 5/10 to 8-9/10 average score
  - Removed scripts: `build_cmake_windows.bat`, `build_cmake_linux.sh`, `build_linux.sh`, `build_macos.sh`, `build.py`, `build_all_windows.bat`, `test_shared_windows.bat`, `test_all_windows.bat`, `test_shared_linux.sh`, `test_ci_locally.sh`, `run_benchmarks.sh`, `run_onnx_benchmarks.bat`, `run_onnx_benchmarks.sh`, `aggregate_benchmarks.py`
  - Remaining scripts: `build_windows.bat`, `build_native.py`, `clean_windows.bat`, `setup_onnx.py`, `download_model.py`
  - All scripts now support `--quiet` and `--force` flags where applicable
  - All scripts now have proper error messages with actionable suggestions

### Changed

- **BREAKING CHANGE:** Default embedding dimension changed from 768 to 128
  - Improves performance (~0.01-0.05ms for 128D vs ~0.05-0.15ms for 768D)
  - Maintains good quality for most use cases
  - For BERT compatibility, explicitly specify dimension=768
  - Migration: Update code that relies on default 768D to specify dimension explicitly

- **Performance Improvements:**
  - Square Root normalization provides better quality with simpler implementation
  - 128D default dimension improves throughput
  - Quality improvement: 0.35 typo similarity (vs 0.09 linear), 0.38 reorder (vs -0.03 linear)

- **Version Consistency:**
  - All bindings updated to version 1.0.1 (Node.js, Python, C#, Java)

### Fixed

- Version number consistency across all language bindings
- Missing C# test suite (now comprehensive test coverage)
- XML documentation comments for FastEmbedException
- **Security (2025-01-15):**
  - Fixed use-after-free vulnerability in `fastembed_napi.cc` (moved `free()` calls after `snprintf`)
- **Build System (2025-01-15):**
  - Fixed Java JAR build failures on all platforms (Linux, Windows, macOS)
  - Fixed Maven `javah` phase execution issues
  - Fixed build-artifacts workflow packaging failures
  - Added ONNX Runtime linking to Windows build script
  - Fixed artifact naming (replaced slashes in ref_name)
- **macOS ARM64 (2025-01-15):**
  - Implemented native ARM64 NEON assembly for Apple Silicon (replaces C-only fallback)
  - Fixed Mach-O section syntax for ARM64 assembly files
  - Improved performance on macOS ARM64 (native SIMD instead of C fallback)
- **CI/CD (2025-01-15):**
  - Fixed CI fail-fast behavior (added `fail-fast: false` to all matrix strategies)
  - Fixed C# macOS TextSimilarity precision test expectations
  - Fixed Java test expectations for C-only implementation
- **Test Suite Fixes (2025-01-15):**
  - **Node.js**: Fixed missing ONNX Runtime headers on Windows and macOS by adding explicit `include_dirs` to `binding.gyp`
  - **Python**: Fixed `ModuleNotFoundError` by adding post-build copy step in `setup.py` for `--inplace` builds
  - **C#**: Fixed `DllNotFoundException` by updating `.csproj` files with correct DLL paths (`shared/lib/`) and correct DLL names (`fastembed_native.dll`, `libfastembed.so`)
  - **Java**: Fixed file naming mismatch by removing duplicate `test_java_native.java` and updating CI workflow to use `TestFastEmbedJava.java`
  - All test suites should now pass on all platforms (Linux, Windows, macOS) and all language versions

### Security

- Fixed use-after-free vulnerability in Node.js N-API binding (`fastembed_napi.cc:242`)

---

## [1.0.0] - 2024-11-01

### Added

- **Core Features:**
  - Hash-based text embedding generation (768-dimensional vectors)
  - SIMD-optimized vector operations (dot product, cosine similarity, L2 norm, normalization, addition)
  - Assembly implementation (x86-64, SSE4/AVX2)
  - System V ABI compliance

- **Language Bindings:**
  - **Node.js:** N-API binding with `FastEmbedNativeClient` class
  - **Python:** pybind11 binding with `FastEmbedNative` class
  - **C#:** P/Invoke binding with `FastEmbedClient` class
  - **Java:** JNI binding with `FastEmbed` class
  - All bindings support ONNX Runtime 1.23.2 for semantic embeddings

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

| Version | Date       | Highlights                                                                                                    |
| ------- | ---------- | ------------------------------------------------------------------------------------------------------------- |
| 1.0.1   | 2025-01-16 | Improved hash algorithm, C# tests, ONNX support, ARM64 NEON, security fixes, breaking change: default 768→128 |
| 1.0.0   | 2024-11-01 | Full multi-language support (4 bindings), ABI fix                                                             |
| 0.2.0   | 2024-10-25 | C# and Java bindings, Weaviate integration                                                                    |
| 0.1.0   | 2024-10-15 | Initial release (Node.js, Python, C library)                                                                  |

---

## Links

- [GitHub Repository](https://github.com/shuanat/fastembed-native)
- [Issue Tracker](https://github.com/shuanat/fastembed-native/issues)
- [Documentation](docs/)
