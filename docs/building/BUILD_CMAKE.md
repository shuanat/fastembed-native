# Building FastEmbed with CMake

**Navigation**: [Documentation Index](README.md) → Build Guides → CMake

CMake provides a modern, cross-platform build system for FastEmbed. This is the **recommended** build method for all platforms.

## Why CMake?

- ✅ **Cross-platform**: Single configuration for Windows, Linux, macOS
- ✅ **IDE Integration**: Works with Visual Studio, CLion, VS Code
- ✅ **Modern**: Industry-standard build system
- ✅ **Automated**: Handles dependencies, linking, and installation
- ✅ **Flexible**: Easy to customize build options

## Prerequisites

### All Platforms

- **CMake 3.15+**: [Download](https://cmake.org/download/)
- **NASM**: [Download](https://www.nasm.us/) (x86-64 assembler)
- **C Compiler**: GCC, Clang, or MSVC

### Platform-Specific

#### Windows

- Visual Studio 2019+ (Build Tools or full IDE)
- OR MinGW-w64

#### Linux/WSL

```bash
sudo apt-get install cmake nasm build-essential
```

#### macOS

```bash
brew install cmake nasm
```

## Quick Start

### Windows

```batch
REM Use CMake directly (see BUILD_CMAKE.md for instructions)
cd bindings\shared
mkdir build_cmake
cd build_cmake
cmake ..
cmake --build .
```

### Linux/WSL/macOS

```bash
# Use CMake directly (see BUILD_CMAKE.md for instructions)
cd bindings/shared
mkdir -p build_cmake
cd build_cmake
cmake ..
cmake --build .
```

## Manual Build

### 1. Configure

```bash
# Create build directory
cd bindings/shared
mkdir build_cmake
cd build_cmake

# Configure CMake
cmake .. -DCMAKE_BUILD_TYPE=Release
```

**Options:**

- `-DBUILD_SHARED_LIBS=ON/OFF` - Build shared library (.dll/.so)
- `-DBUILD_CLI_TOOLS=ON/OFF` - Build CLI tools
- `-DBUILD_TESTS=ON/OFF` - Build test suite
- `-DBUILD_BENCHMARKS=ON/OFF` - Build benchmarks
- `-DUSE_ONNX_RUNTIME=ON/OFF` - Enable ONNX Runtime support

**Windows with Visual Studio:**

```batch
cmake .. -G "Visual Studio 17 2022" -A x64
```

**Windows with MinGW:**

```batch
cmake .. -G "MinGW Makefiles"
```

### 2. Build

```bash
# Build all targets
cmake --build . --config Release

# Or use native build system
make -j$(nproc)        # Linux/macOS
msbuild FastEmbed.sln  # Windows/MSVC
```

### 3. Run Tests

```bash
# Run all tests
ctest --verbose

# Or run individual tests
./test_hash_functions
./test_embedding_generation
./test_quality_improvement
./test_sqrt_quality
./test_onnx_dimension  # If ONNX Runtime available
./benchmark_improved
```

### 4. Install (Optional)

```bash
# Install to system directories
sudo cmake --install .

# Or specify custom prefix
cmake --install . --prefix /custom/path
```

## Build Targets

### Libraries

- **fastembed_static** - Static library (.a/.lib)
- **fastembed_shared** - Shared library (.so/.dll/.dylib)

### CLI Tools

- **vector_ops_cli** - Vector operations utility
- **embedding_gen_cli** - Embedding generator
- **onnx_cli** - ONNX Runtime embedding tool (if available)

### Tests

- **test_hash_functions** - Hash function unit tests
- **test_embedding_generation** - Embedding generation tests
- **test_quality_improvement** - Quality improvement tests
- **test_sqrt_quality** - Square Root normalization quality metrics
- **test_onnx_dimension** - ONNX dimension auto-detection tests
- **benchmark_improved** - Performance benchmarks

### Benchmarks

- **benchmark_improved** - Performance benchmarks

## Advanced Configuration

### Custom ONNX Runtime Location

```bash
cmake .. -DONNXRUNTIME_DIR=/path/to/onnxruntime
```

### Debug Build

```bash
cmake .. -DCMAKE_BUILD_TYPE=Debug
cmake --build .
```

### Minimal Build (Library Only)

```bash
cmake .. \
    -DBUILD_CLI_TOOLS=OFF \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCHMARKS=OFF
cmake --build .
```

### Build with Ninja (Faster)

```bash
cmake .. -G Ninja
ninja
```

## IDE Integration

### Visual Studio

1. Open Visual Studio
2. **File → Open → CMake...**
3. Select `bindings/shared/CMakeLists.txt`
4. Build from IDE

### CLion

1. Open CLion
2. **File → Open**
3. Select `bindings/shared/` directory
4. CLion auto-detects CMake

### VS Code

1. Install **CMake Tools** extension
2. Open project folder
3. **Ctrl+Shift+P → CMake: Configure**
4. **Ctrl+Shift+P → CMake: Build**

## Troubleshooting

### NASM Not Found

**Windows:**

```batch
# Add NASM to PATH, or install via Chocolatey:
choco install nasm
```

**Linux:**

```bash
sudo apt-get install nasm
```

### CMake Version Too Old

```bash
# Ubuntu 20.04+
sudo apt-get update
sudo apt-get install cmake

# Or download latest from cmake.org
```

### Visual Studio Not Found (Windows)

CMake auto-detects Visual Studio. If it fails:

```batch
# Specify generator explicitly
cmake .. -G "Visual Studio 16 2019" -A x64
```

### ONNX Runtime Not Detected

CMake searches these locations:

1. `<project-root>/onnxruntime/`
2. `<bindings/shared>/onnxruntime/`
3. `/usr/local/`
4. `$ONNXRUNTIME_DIR`

**Solution:**

```bash
# Download ONNX Runtime 1.23.2
# Extract to one of the above locations, or:
export ONNXRUNTIME_DIR=/path/to/onnxruntime
cmake ..
```

### Link Errors (Linux)

If you get `undefined reference to 'exp'` or similar:

```bash
# Make sure libm is linked (CMake does this automatically)
# If issue persists, try:
cmake .. -DCMAKE_EXE_LINKER_FLAGS="-lm"
```

## Comparison: CMake vs Makefile

| Feature             | CMake            | Makefile         |
| ------------------- | ---------------- | ---------------- |
| Cross-platform      | ✅ Yes            | ❌ Unix-only      |
| Windows native      | ✅ MSVC/MinGW     | ⚠️ WSL only       |
| IDE integration     | ✅ Full support   | ⚠️ Limited        |
| Dependency tracking | ✅ Automatic      | ⚠️ Manual         |
| Test integration    | ✅ CTest built-in | ⚠️ Custom scripts |
| Learning curve      | ⚠️ Moderate       | ✅ Simple         |

**Recommendation:** Use **CMake** for production builds, **Makefile** for quick local development.

## Next Steps

- [API Documentation](API.md)
- [Testing Guide](../tests/README_TESTING.md)
- [Benchmarking](BENCHMARKS.md)
- [Contributing](../CONTRIBUTING.md)

---

## See Also

### Related Documentation

- **[Architecture Documentation](ARCHITECTURE.md)** - System architecture and build system details
- **[API Reference](API.md)** - Complete API documentation
- **[Use Cases](USE_CASES.md)** - Real-world scenarios and applications

### Other Build Guides

- **[Build Windows](BUILD_WINDOWS.md)** - Windows-specific build instructions
- **[Build Native](BUILD_NATIVE.md)** - Node.js N-API module build
- **[Build Python](BUILD_PYTHON.md)** - Python pybind11 module build
- **[Build C#](BUILD_CSHARP.md)** - C# P/Invoke module build
- **[Build Java](BUILD_JAVA.md)** - Java JNI module build

### Additional Resources

- **[Documentation Index](README.md)** - Complete documentation overview
- **[Main README](../README.md)** - Project overview and quick start
- **[Contributing](../CONTRIBUTING.md)** - Contribution guidelines
- **[Testing Guide](../tests/README_TESTING.md)** - Testing instructions
