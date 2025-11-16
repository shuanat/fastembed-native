# Building FastEmbed on Windows

**Navigation**: [Documentation Index](README.md) → Build Guides → Windows

This guide describes the current, supported build and testing process for FastEmbed on Windows for all bindings: Node.js (N-API), Python (pybind11), C# (P/Invoke), Java (JNI).

## Prerequisites

- Visual Studio 2022 Build Tools (Workload: "Desktop development with C++")
- NASM ≥ 2.14 (add `nasm.exe` to PATH)
- Node.js 18+
- Python 3.8+ (recommended) + `pip`
- .NET SDK 8.0+
- JDK 17+ and Maven

## Quick Start

### 1) Build Shared Native Library

Use the universal script (recommended):

```bat
python scripts\build_native.py
```

Alternative (batch file, calls the same pipeline):

```bat
scripts\build_windows.bat
```

Final artifacts will appear in `bindings\shared\build\`:

- `fastembed.dll` (Windows)
- Pre-compiled object files for Python build: `embedding_lib.obj`, `embedding_generator.obj`

### 2) Build All Bindings and Tests

```bat
REM Build shared library first
scripts\build_windows.bat

REM Then build all bindings using Makefile
make all

REM Run tests
make test
```

## Building and Testing by Language

### Node.js (N-API)

```bat
cd bindings\nodejs
npm install
npm run build
node test-native.js
```

### Python (pybind11)

On Windows, the extension links to object files from `bindings\shared\build`. If they don't exist, run the "Build Shared Native Library" step first.

```bat
cd bindings\python
pip install pybind11 numpy
python setup.py build_ext --inplace
python test_python_native.py
```

### C# (P/Invoke)

```bat
cd bindings\csharp
dotnet build src\FastEmbed.csproj
cd tests
dotnet test
```

**Test Suite**: The C# binding includes a comprehensive xUnit test suite with 49+ tests.

### Java (JNI)

```bat
cd bindings\java
bash run_benchmark.sh
```

The script will build the JNI wrapper and test class, then run a benchmark/verification to load `fastembed.dll` from `target\lib`.

## Cleaning Artifacts (Windows)

```bat
make clean  ^  (will call scripts\clean_windows.bat)
```

Or directly:

```bat
scripts\clean_windows.bat
```

## Notes

- Node.js uses N-API (native module), FFI is not used.
- Python uses pybind11; on Windows, linking goes to pre-built `.obj` files from `bindings\shared\build`.
- C# uses P/Invoke and `NativeLibrary.SetDllImportResolver`, which first looks for `fastembed.dll` next to the built `.dll` binding.
- Java uses a minimal JNI layer; the library is found via `-Djava.library.path`.

## Common Issues

- "nasm not found": Install NASM and add the path to `nasm.exe` to PATH, or use `bindings\nodejs\nasm_wrapper.bat` (it's called automatically from `binding.gyp`).
- Python build error: Ensure the shared library build step is completed and `.obj` files are present in `bindings\shared\build`.
- Issues with `make clean` on Windows: Use `scripts\clean_windows.bat` directly.

---

## See Also

### Related Documentation

- **[Architecture Documentation](ARCHITECTURE.md)** - System architecture and build system details
- **[API Reference](API.md)** - Complete API documentation
- **[Use Cases](USE_CASES.md)** - Real-world scenarios and applications

### Other Build Guides

- **[Build CMake](BUILD_CMAKE.md)** - Cross-platform CMake build (recommended)
- **[Build Native](BUILD_NATIVE.md)** - Node.js N-API module build
- **[Build Python](BUILD_PYTHON.md)** - Python pybind11 module build
- **[Build C#](BUILD_CSHARP.md)** - C# P/Invoke module build
- **[Build Java](BUILD_JAVA.md)** - Java JNI module build

### Additional Resources

- **[Documentation Index](README.md)** - Complete documentation overview
- **[Main README](../README.md)** - Project overview and quick start
