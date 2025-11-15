# Contributing to FastEmbed

Thank you for your interest in contributing to FastEmbed! We welcome contributions from the community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)

---

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md) to ensure a welcoming environment for all contributors.

---

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected vs. actual behavior**
- **Environment details** (OS, compiler, language binding)
- **Code samples** or test cases (if applicable)

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md).

---

### Requesting Features

For feature requests:

- **Describe the feature** and its use case
- **Explain why** it would be useful
- **Provide examples** of how it would be used

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md).

---

### Contributing Code

1. **Fork** the repository
2. **Create a branch** for your feature (`git checkout -b feature/my-feature`)
3. **Make changes** and add tests
4. **Run tests** to ensure they pass
5. **Commit** with clear messages (`git commit -m "Add feature X"`)
6. **Push** to your fork (`git push origin feature/my-feature`)
7. **Open a Pull Request** to the `main` branch

---

## Development Setup

### Prerequisites

- **NASM** (≥ 2.14)
- **GCC/Clang/MSVC** (modern toolchain)
- **Make**
- **Language-specific tools**:
  - Node.js 18+ (node-gyp installed by npm)
  - Python 3.8+ (pybind11, numpy)
  - .NET SDK 8.0+
  - JDK 17+, Maven 3.6+

### Build Instructions

```bash
# Clone repository
git clone https://github.com/shuanat/fastembed-native.git
cd fastembed-native

# Build all bindings
make all

# Or build specific binding
make shared   # C/Assembly library
make nodejs   # Node.js binding
make python   # Python binding
make csharp   # C# binding
make java     # Java binding
```

See [docs/BUILD_NATIVE.md](docs/BUILD_NATIVE.md) for detailed build instructions.

---

## Build Scripts

FastEmbed uses several build scripts to support different platforms and workflows:

### `build_windows.ps1` (Windows)

PowerShell build script for Windows with enterprise-grade features:

```powershell
# Basic build
.\scripts\build_windows.ps1

# Clean build
.\scripts\build_windows.ps1 -Clean
```

**Features**:

- Automatic Visual Studio Build Tools detection
- NASM assembler validation
- Structured logging (INFO, SUCCESS, WARNING, ERROR, DEBUG)
- Standardized error messages with solutions
- ONNX Runtime integration

**Requirements**:

- Visual Studio Build Tools 2022 (with "Desktop development with C++")
- NASM (≥ 2.14)

### `build_native.py` (Cross-platform)

Python build script supporting Windows, Linux, and macOS:

```bash
# Build native library
python scripts/build_native.py

# Verbose output
python scripts/build_native.py -v
```

**Features**:

- Cross-platform compilation
- Automatic ONNX Runtime detection
- macOS arm64 C-only fallback (no assembly)
- Comprehensive error messages

### `docker-test.ps1` / `docker-test.sh` (Local Docker Testing)

Test builds in Docker containers matching CI environment:

```powershell
# Windows
.\scripts\docker-test.ps1 all      # Test all platforms
.\scripts\docker-test.ps1 ubuntu   # Test Ubuntu only
.\scripts\docker-test.ps1 clean    # Clean containers

# Linux/macOS
./scripts/docker-test.sh all
./scripts/docker-test.sh ubuntu
./scripts/docker-test.sh clean
```

**Features**:

- Matches GitHub Actions environment
- Auto-detects `docker compose` vs `docker-compose`
- Pre-pulls images to avoid credential issues

---

## Local Testing

### Quick Test Workflow

```bash
# 1. Clean previous builds
make clean

# 2. Build all bindings
make all

# 3. Run tests
make test

# 4. (Optional) Test in Docker
./scripts/docker-test.sh all
```

### Platform-Specific Testing

**Windows**:

```powershell
# Build
.\scripts\build_windows.ps1 -Clean

# Test Node.js binding
cd bindings\nodejs
npm test

# Test Python binding
cd bindings\python
python test_python_native.py
```

**Linux/macOS**:

```bash
# Build
make clean && make shared

# Test Node.js binding
cd bindings/nodejs && npm test

# Test Python binding
cd bindings/python && python test_python_native.py
```

### CI Testing

GitHub Actions runs comprehensive tests on every push:

- **Platforms**: Linux, Windows, macOS
- **Language Bindings**: Node.js (16/18/20), Python (3.8-3.13), C# (6.0/7.0/8.0), Java (11/17/21)
- **Workflows**: `.github/workflows/ci.yml`

Trigger manual workflow run:

```bash
gh workflow run ci.yml --ref your-branch
```

---

## Troubleshooting

### Common Build Errors

#### Error: `NASM not found in PATH` (Windows)

**Problem**: NASM assembler not installed or not in PATH

**Solution**:

```powershell
# Option 1: Install via Chocolatey
choco install nasm

# Option 2: Download from https://www.nasm.us/
# Then add to PATH: C:\Program Files\NASM
```

#### Error: `Visual Studio Build Tools not found` (Windows)

**Problem**: MSVC compiler not installed

**Solution**:

1. Install [Visual Studio 2022 Build Tools](https://visualstudio.microsoft.com/downloads/)
2. Select "Desktop development with C++" workload
3. Restart terminal to refresh environment variables

#### Error: `error C2491: 'fastembed_generate': definition of dllimport function not allowed`

**Problem**: Missing `FASTEMBED_BUILDING_LIB` preprocessor definition during compilation

**Solution**: This should be handled automatically by build scripts. If it persists:

- For `build_windows.ps1`: Ensure latest version (v2.0+)
- For `build_native.py`: Ensure latest version with `/DFASTEMBED_BUILDING_LIB` flag
- For manual builds: Add `-DFASTEMBED_BUILDING_LIB` to compiler flags

#### Error: `Undefined symbols for architecture arm64` (macOS)

**Problem**: Assembly functions not available for macOS arm64

**Solution**: Build system automatically uses C-only fallback for macOS arm64. Ensure you're using latest Makefile:

```bash
cd bindings/shared
make clean && make
```

The Makefile detects arm64 and compiles with `-DUSE_ONLY_C` flag.

#### Error: `docker: command not found` (Local Docker Testing)

**Problem**: Docker not installed or not in PATH

**Solution**:

- **Windows**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- **Linux**: Install Docker Engine: `sudo apt-get install docker.io docker-compose`
- **macOS**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

After installation, restart terminal and verify: `docker --version`

#### Error: `Cannot find module './build/Release/fastembed_native.node'` (Node.js)

**Problem**: Node.js addon not built correctly

**Solution**:

```bash
cd bindings/nodejs
npm install  # Automatically runs node-gyp rebuild
node test-native.js
```

If still failing, rebuild manually:

```bash
npx node-gyp rebuild --verbose
```

### Getting Help

If you encounter an error not listed here:

1. **Check Build Logs**: Look for `::error::` messages with details and solutions
2. **Search Issues**: [GitHub Issues](https://github.com/shuanat/fastembed-native/issues)
3. **Ask in Discussions**: [GitHub Discussions](https://github.com/shuanat/fastembed-native/discussions)
4. **Open an Issue**: Include:
   - OS and version
   - Compiler and version
   - Full error message and stack trace
   - Build command used

---

## Pull Request Process

### Before Submitting

1. **Ensure all tests pass**:

   ```bash
   make test
   ```

2. **Follow coding guidelines** (see below)

3. **Update documentation** if needed

4. **Add tests** for new features

5. **Rebase** on latest `main` branch:

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

### PR Requirements

- **Clear title** describing the change
- **Description** explaining what and why
- **Reference issues** (e.g., "Fixes #123")
- **All CI checks pass** (GitHub Actions)
- **Code review approval** from maintainers

### Review Process

- Maintainers will review within 3-5 business days
- Address review comments promptly
- Once approved, maintainers will merge

---

## Coding Guidelines

### C/Assembly Code

- **Follow System V ABI** (save callee-saved registers, 16-byte stack alignment)
- **Use meaningful variable names** (`vec1`, `vec2`, not `v1`, `v2`)
- **Add comments** for complex logic
- **Optimize for performance** (SIMD, cache locality)
- **Test on multiple platforms** (Linux, Windows, macOS)

**Example:**

```asm
dot_product_asm:
    push rbx            ; Save callee-saved register
    movaps xmm0, [rdi]  ; Load vec1 into xmm0
    mulps xmm0, [rsi]   ; Multiply by vec2
    ; ... (rest of implementation)
    pop rbx             ; Restore register
    ret
```

---

### Node.js Code

- **Use N-API** (not legacy NAN)
- **Handle errors** gracefully (throw `Error` with descriptive messages)
- **Validate arguments** (type checks, dimension checks)
- **Use TypeScript** for type safety (if applicable)

**Example:**

```cpp
Napi::Value GenerateEmbedding(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "String expected").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string text = info[0].As<Napi::String>();
    // ... (generate embedding)
    return Napi::Float32Array::New(env, dimension);
}
```

---

### Python Code

- **Follow PEP 8** style guide
- **Use type hints** (Python 3.5+)
- **Handle exceptions** (raise `ValueError`, `RuntimeError`)
- **Use `numpy` arrays** for vector data

**Example:**

```python
def generate_embedding(self, text: str) -> np.ndarray:
    if not isinstance(text, str):
        raise ValueError("text must be a string")
    
    embedding = np.zeros(self.dimension, dtype=np.float32)
    self._native.generate_embedding(text, embedding)
    return embedding
```

---

### C# Code

- **Follow .NET conventions** (PascalCase for public members)
- **Use XML comments** for public APIs
- **Throw `FastEmbedException`** for errors
- **Use `float[]`** for vector data

**Example:**

```csharp
/// <summary>
/// Generate embedding from text.
/// </summary>
/// <param name="text">Input text</param>
/// <returns>Embedding vector</returns>
public float[] GenerateEmbedding(string text)
{
    if (string.IsNullOrEmpty(text))
        throw new ArgumentException("text cannot be null or empty");
    
    float[] embedding = new float[_dimension];
    // ... (call native function)
    return embedding;
}
```

---

### Java Code

- **Follow Java conventions** (camelCase for methods)
- **Use JavaDoc** for public APIs
- **Throw `RuntimeException`** for errors
- **Use `float[]`** for vector data

**Example:**

```java
/**
 * Generate embedding from text.
 * @param text Input text
 * @return Embedding vector
 */
public float[] generateEmbedding(String text) {
    if (text == null || text.isEmpty()) {
        throw new IllegalArgumentException("text cannot be null or empty");
    }
    
    float[] embedding = new float[dimension];
    // ... (call native function)
    return embedding;
}
```

---

## Testing

### Unit Tests

All new features must include tests:

- **Node.js:** `bindings/nodejs/test-native.js`
- **Python:** `bindings/python/test_python_native.py`
- **C#:** `bindings/csharp/tests/FastEmbed.Tests.csproj` (xUnit test suite)
- **Java:** `bindings/java/TestFastEmbedJava.java`

### Running Tests

```bash
# All tests
make test

# Specific binding
cd bindings/nodejs && node test-native.js
cd bindings/python && python test_python_native.py
cd bindings/csharp/tests && dotnet test
cd bindings/java && mvn test
```

**Note for C#**: The `dotnet test` command automatically builds and runs the xUnit test suite in `bindings/csharp/tests/FastEmbed.Tests.csproj`.

### Test Coverage

Ensure tests cover:

- **Happy path** (valid inputs)
- **Edge cases** (empty text, zero vectors, large dimensions)
- **Error handling** (invalid arguments, null pointers)
- **Performance** (benchmark critical operations)

---

## Documentation

### Code Comments

- **C/Assembly:** Comment complex algorithms, register usage, ABI considerations
- **Bindings:** Document public APIs with clear parameter descriptions
- **Examples:** Add usage examples in docstrings

### Markdown Docs

- **Update README.md** if adding major features
- **Update docs/API.md** if changing API
- **Update docs/ARCHITECTURE.md** if changing internals
- **Add use cases** to docs/USE_CASES.md (if applicable)

---

## License

By contributing, you agree that your contributions will be licensed under the project's open-source license: [AGPL-3.0](LICENSE). Commercial licensing is available for end users; see [LICENSING.md](LICENSING.md).

---

## Questions?

- **GitHub Issues:** [Open an issue](https://github.com/shuanat/fastembed-native/issues)
- **GitHub Discussions:** [Join discussions](https://github.com/shuanat/fastembed-native/discussions)

---

Thank you for contributing to FastEmbed! 🚀
