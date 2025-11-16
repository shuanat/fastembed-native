# FastEmbed Examples

Usage examples demonstrating FastEmbed integration in different programming languages.

---

## 📁 Available Examples

### Native Bindings (Production-Ready)

**Recommended for production use:**

| Language    | Location                                                                          | Type     | Status   |
| ----------- | --------------------------------------------------------------------------------- | -------- | -------- |
| **Node.js** | [bindings/nodejs/test-native.js](../bindings/nodejs/test-native.js)               | N-API    | ✅ Stable |
| **Python**  | [bindings/python/test_python_native.py](../bindings/python/test_python_native.py) | pybind11 | ✅ Stable |
| **C#**      | [bindings/csharp/tests/](../bindings/csharp/tests/) (xUnit suite, 49+ tests)      | P/Invoke | ✅ Stable |
| **Java**    | [bindings/java/test_java_native.java](../bindings/java/test_java_native.java)     | JNI      | ✅ Stable |

**Performance:** See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for detailed performance data. Python achieves **0.012-0.048 ms** per embedding generation and **sub-microsecond** vector operations.

### FFI/Direct API Examples (Educational)

**For learning and experimentation:**

| Language    | Location                           | Description                  |
| ----------- | ---------------------------------- | ---------------------------- |
| **C**       | [c/basic.c](c/basic.c)             | Direct C API usage           |
| **C++**     | [cpp/basic.cpp](cpp/basic.cpp)     | C++ wrapper around C API     |
| **Python**  | [python/basic.py](python/basic.py) | Python ctypes FFI example    |
| **Node.js** | [nodejs/basic.js](nodejs/basic.js) | Node.js FFI (legacy) example |

---

## 🚀 Quick Start

### C Example

```bash
# Build shared library first
cd bindings/shared
make all

# Compile and run C example
cd ../../examples/c
gcc -o basic basic.c -L../../bindings/shared/build -lfastembed -lm -I../../bindings/shared/include
LD_LIBRARY_PATH=../../bindings/shared/build ./basic
```

### C++ Example

```bash
# Build shared library first
cd bindings/shared
make all

# Compile and run C++ example
cd ../../examples/cpp
g++ -o basic basic.cpp -L../../bindings/shared/build -lfastembed -lm -I../../bindings/shared/include
LD_LIBRARY_PATH=../../bindings/shared/build ./basic
```

### Python Example (ctypes)

```bash
# Build shared library first
cd bindings/shared
make all

# Run Python example
cd ../../examples/python
LD_LIBRARY_PATH=../../bindings/shared/build python basic.py
```

### Node.js Example (FFI)

```bash
# Build shared library first
cd bindings/shared
make all

# Run Node.js example
cd ../../examples/nodejs
node basic.js
```

---

## 📝 Example Contents

### C Example ([c/basic.c](c/basic.c))

Demonstrates:

- Embedding generation using `fastembed_generate()`
- Vector operations (dot product, cosine similarity, normalization)
- Direct C API usage

**Key Features:**

- No dependencies (just C standard library)
- Direct memory management
- Minimal overhead

### C++ Example ([cpp/basic.cpp](cpp/basic.cpp))

Demonstrates:

- C++ wrapper around C API
- RAII-style memory management
- Modern C++ patterns (std::vector, std::string)

**Key Features:**

- Type-safe C++ interface
- Exception handling
- STL integration

### Python Example ([python/basic.py](python/basic.py))

Demonstrates:

- Python ctypes FFI
- Dynamic library loading
- numpy integration

**Key Features:**

- Pure Python (no compilation needed)
- Cross-platform
- numpy array support

### Node.js Example ([nodejs/basic.js](nodejs/basic.js))

Demonstrates:

- Node.js FFI using ffi-napi
- TypeScript type definitions
- Async/Promise patterns

**Key Features:**

- No native compilation needed
- Cross-platform
- Modern JavaScript/TypeScript

---

## 🔧 Native Bindings Examples

For production use, we recommend using the **native bindings** instead of FFI:

### Node.js (N-API)

```javascript
const { FastEmbedNativeClient } = require('fastembed-native');

const client = new FastEmbedNativeClient(768);
const embedding = client.generateEmbedding("Hello, world!");
```

See: [bindings/nodejs/test-native.js](../bindings/nodejs/test-native.js)

### Python (pybind11)

```python
from fastembed_native import FastEmbedNative

client = FastEmbedNative(768)
embedding = client.generate_embedding("Hello, world!")
```

See: [bindings/python/test_python_native.py](../bindings/python/test_python_native.py)

### C# (P/Invoke)

```csharp
using FastEmbed;

var client = new FastEmbedClient(dimension: 768);
float[] embedding = client.GenerateEmbedding("Hello, world!");
```

See: [bindings/csharp/tests/](../bindings/csharp/tests/) - Comprehensive xUnit test suite with 49+ tests

### Java (JNI)

```java
import com.fastembed.FastEmbed;

FastEmbed client = new FastEmbed(768);
float[] embedding = client.generateEmbedding("Hello, world!");
```

See: [bindings/java/test_java_native.java](../bindings/java/test_java_native.java)

---

## 📚 Additional Resources

- **[Main README](../README.md)** - Project overview
- **[API Documentation](../docs/API.md)** - Complete API reference
- **[Build Guides](../docs/)** - Language-specific build instructions
- **[Architecture](../docs/ARCHITECTURE.md)** - System design and internals

---

## 🤝 Contributing Examples

Want to add more examples? See [CONTRIBUTING.md](../CONTRIBUTING.md).

### Example Guidelines

- **Clear and simple** - Focus on one concept per example
- **Well-commented** - Explain what each section does
- **Self-contained** - Include build/run instructions
- **Cross-platform** - Work on Linux, macOS, and Windows (via WSL)
- **Error handling** - Show proper error handling patterns

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/shuanat/fastembed-native/issues)
- **Documentation**: [docs/](../docs/)

---

**Last updated:** November 1, 2024
