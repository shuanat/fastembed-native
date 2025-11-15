# FastEmbed Scripts

Production-ready utility scripts for FastEmbed setup and builds.

**Last Updated**: 2025-01-14  
**Total Scripts**: 5 (down from 19 after refactoring)

---

## Overview

This directory contains essential build and setup scripts for FastEmbed. All scripts have been refactored to meet enterprise standards with:

- ✅ Comprehensive error handling
- ✅ Structured logging with log levels
- ✅ Complete documentation
- ✅ Consistent code style
- ✅ English-only comments and output

---

## Available Scripts

### `setup_onnx.py`

Download and install ONNX Runtime for FastEmbed (optional - only needed for neural embeddings).

```bash
python scripts/setup_onnx.py
python scripts/setup_onnx.py --force  # Force reinstall
```

**What it does:**

- Detects platform (Linux x64/ARM64, macOS x64/ARM64, Windows x64)
- Downloads appropriate ONNX Runtime build from GitHub releases
- Extracts to `onnxruntime/` directory
- Verifies installation
- Skips download if already installed (unless `--force` is used)

**Features:**

- ✅ Comprehensive error handling
- ✅ Progress indicators for downloads
- ✅ Platform detection and validation
- ✅ Installation verification

**Also available via Makefile:**

```bash
make setup-onnx
```

---

### `download_model.py`

Download ONNX embedding model from HuggingFace Hub (optional).

```bash
python scripts/download_model.py
python scripts/download_model.py --force  # Force re-download
python scripts/download_model.py --quiet  # Minimal output
```

**What it does:**

- Downloads `nomic-embed-text-v1` model (768-dimensional embeddings)
- Saves to `models/nomic-embed-text.onnx`
- Skips download if model already exists (unless `--force` is used)

**Features:**

- ✅ Comprehensive error handling with detailed messages
- ✅ Structured logging with [INFO], [WARN], [ERROR] prefixes
- ✅ `--quiet` flag for minimal output
- ✅ `--force` flag to re-download existing model
- ✅ File verification after download
- ✅ Keyboard interrupt handling (Ctrl+C)

**Requirements:**

- Python 3.6+
- `huggingface-hub` package (installed automatically in virtual environment)

**Exit Codes:**

- `0` - Success
- `1` - Error (missing dependency, download failure, etc.)
- `130` - Interrupted by user (Ctrl+C)

**Also available via Makefile:**

```bash
make setup-model
```

---

### `build_windows.bat`

Windows-specific batch script for building the shared library DLL.

```powershell
.\scripts\build_windows.bat
```

**Features:**

- Compiles Assembly code using NASM
- Links into Windows DLL (`fastembed_native.dll`)
- Automatically finds NASM in standard locations
- Detects and uses ONNX Runtime if available
- Comprehensive error handling with detailed messages
- Structured logging with [INFO], [WARN], [ERROR] prefixes
- Validates all dependencies before building
- Used by CI/CD workflows

**Requirements:**

- Visual Studio Build Tools 2022 (with "Desktop development with C++")
- NASM (>= 2.14) - Assembly compiler
- Windows OS (x64)

**Exit Codes:**

- `0` - Success
- `1` - Error (missing dependencies, compilation failure, etc.)

**Also available via Makefile:**

```bash
make shared    # Build shared library only
```

---

### `build_native.py`

Universal build script for native library (Windows/Linux/macOS).

```bash
python scripts/build_native.py
```

**Features:**

- Cross-platform support (Windows, Linux, macOS)
- Automatic platform detection
- NASM detection and validation
- Comprehensive error handling

**Note**: Alternative to `build_windows.bat` on Windows, or use Makefile.

---

### `clean_windows.bat`

Clean build artifacts on Windows.

```powershell
.\scripts\clean_windows.bat
```

**What it does:**

- Removes all build artifacts and compiled files
- Cleans shared library build directory
- Cleans Node.js, Python, C#, and Java build artifacts
- Removes `.node`, `.pyd`, `.so` files
- Removes `__pycache__` directories

**Features:**

- ✅ Comprehensive error handling
- ✅ Structured logging with [INFO], [WARN], [ERROR] prefixes
- ✅ Graceful handling of locked files
- ✅ Summary message at completion

**Exit Codes:**

- `0` - Success
- `1` - Warning (some files may be in use)

**Also available via Makefile:**

```bash
make clean     # Clean build artifacts
```

---

## Quick Start

### 1. Setup (Optional - for ONNX/neural embeddings)

```bash
# Setup ONNX Runtime + model
make setup

# Or separately:
python scripts/setup_onnx.py      # ONNX Runtime
python scripts/download_model.py  # Embedding model
```

### 2. Build

```bash
# Using Makefile (recommended)
make all

# Or using platform-specific scripts
# Windows:
scripts\build_windows.bat

# Cross-platform:
python scripts/build_native.py
```

### 3. Test

```bash
# Run all tests
make test

# Or test individual bindings
cd bindings/nodejs && node test-native.js
cd bindings/python && python test_python_native.py
cd bindings/csharp/tests && dotnet test
cd bindings/java && mvn test
```

---

## Requirements

**All scripts require:**

- **Python 3.6+** (usually pre-installed on Linux/macOS)
- **Standard library only** (no external dependencies, except `download_model.py`)

**For `download_model.py`:**

- `huggingface-hub` package (installed automatically in `.venv/`)

**For building:**

- NASM (>= 2.14) - Assembly compiler
- GCC/Clang (>= 7.0) or MSVC - C compiler
- Make - Build system
- Language-specific tools (Node.js, Python, .NET SDK, JDK) - for bindings

---

## Platform Support

| Script              | Linux | Windows    | macOS |
| ------------------- | ----- | ---------- | ----- |
| `setup_onnx.py`     | ✅     | ✅          | ✅     |
| `download_model.py` | ✅     | ✅          | ✅     |
| `build_native.py`   | ✅     | ✅          | ✅     |
| `build_windows.bat` | ❌     | ✅ (Native) | ❌     |
| `clean_windows.bat` | ❌     | ✅ (Native) | ❌     |

**Note**: On Windows, use `build_windows.bat` for native builds, or `build_native.py` for cross-platform builds. For Linux/macOS, use Makefile or `build_native.py`.

---

## Troubleshooting

### NASM not found

**Linux/Ubuntu:**

```bash
sudo apt-get install nasm
```

**macOS:**

```bash
brew install nasm
```

**Windows:**

- Install via Chocolatey: `choco install nasm -y`
- Or download from <https://www.nasm.us/>

### GCC not found

**Linux/Ubuntu:**

```bash
sudo apt-get install gcc make
```

**macOS:**

```bash
xcode-select --install
```

**Windows:**

- Use WSL (recommended): `wsl --install`
- Or install MSYS2/MinGW: <https://www.msys2.org/>

### WSL not available on Windows

If WSL is not installed:

1. **Install WSL:**

   ```powershell
   wsl --install
   ```

2. **Restart computer**

3. **Install dependencies in WSL:**

   ```bash
   sudo apt-get update
   sudo apt-get install nasm gcc make
   ```

---

## See Also

- [Main README](../README.md) - Project overview
- [Build Guides](../docs/BUILD_NATIVE.md) - Detailed build instructions
- [Contributing](../CONTRIBUTING.md) - Contribution guidelines
