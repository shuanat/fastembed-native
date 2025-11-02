# FastEmbed Scripts

Production-ready utility scripts for FastEmbed setup and builds.

---

## Available Scripts

### `setup_onnx.py`

Download and install ONNX Runtime for FastEmbed (optional - only needed for neural embeddings).

```bash
python scripts/setup_onnx.py
```

**What it does:**

- Detects platform (Linux x64/ARM64, macOS x64/ARM64)
- Downloads appropriate ONNX Runtime build from GitHub releases
- Extracts to `onnxruntime/` directory
- Verifies installation

**Also available via Makefile:**

```bash
make setup-onnx
```

---

### `download_model.py`

Download ONNX embedding model from HuggingFace Hub (optional).

```bash
python scripts/download_model.py
```

**What it does:**

- Downloads `nomic-embed-text-v1` model (768-dimensional embeddings)
- Saves to `models/nomic-embed-text.onnx`

**Requirements:**

- Python 3.6+
- `huggingface-hub` package (installed automatically in virtual environment)

**Also available via Makefile:**

```bash
make setup-model
```

---

### `build.py`

Cross-platform build script (Windows/Linux/macOS).

```bash
python scripts/build.py          # Build all bindings
python scripts/build.py clean    # Clean build artifacts
python scripts/build.py shared   # Build shared library only
```

**Features:**

- **Windows**: Automatically uses WSL if available
- **Linux/macOS**: Runs make directly
- Falls back to manual instructions if WSL not available on Windows

**Also available via Makefile:**

```bash
make all       # Build everything
make clean     # Clean build artifacts
make shared    # Build shared library only
```

---

### `build_windows.bat`

Windows-specific batch script for building the DLL (legacy - use `build.py` instead).

```powershell
.\scripts\build_windows.bat
```

**Features:**

- Compiles Assembly code using NASM
- Links into Windows DLL (`fastembed.dll`)
- Automatically finds NASM in standard locations

**Note**: This script is kept for backwards compatibility. New users should use `build.py` or WSL.

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

# Or using Python script
python scripts/build.py
```

### 3. Test

```bash
# Run all tests
make test

# Or test individual bindings
cd bindings/nodejs && node test-native.js
cd bindings/python && python test_python_native.py
cd bindings/csharp && dotnet run --project test_csharp_native.csproj
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

| Script              | Linux | Windows   | macOS |
| ------------------- | ----- | --------- | ----- |
| `setup_onnx.py`     | ✅     | ✅ (WSL)   | ✅     |
| `download_model.py` | ✅     | ✅         | ✅     |
| `build.py`          | ✅     | ✅ (WSL)   | ✅     |
| `build_windows.bat` | ❌     | ✅ (Native) | ❌     |

**Note**: On Windows, `build.py` automatically uses WSL if available. For native Windows builds, use `build_windows.bat` or install MSYS2/MinGW.

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
- Or download from https://www.nasm.us/

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
- Or install MSYS2/MinGW: https://www.msys2.org/

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
