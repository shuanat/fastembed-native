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
git clone https://github.com/yourusername/fastembed.git
cd fastembed

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
- **C#:** `bindings/csharp/test_csharp_native.csproj`
- **Java:** `bindings/java/TestFastEmbedJava.java`

### Running Tests

```bash
# All tests
make test

# Specific binding
cd bindings/nodejs && node test-native.js
cd bindings/python && python test_python_native.py
cd bindings/csharp && LD_LIBRARY_PATH=../shared/build dotnet run --project test_csharp_native.csproj
cd bindings/java && mvn test
```

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

- **GitHub Issues:** [Open an issue](https://github.com/yourusername/fastembed/issues)
- **GitHub Discussions:** [Join discussions](https://github.com/yourusername/fastembed/discussions)

---

Thank you for contributing to FastEmbed! 🚀
