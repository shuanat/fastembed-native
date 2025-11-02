# FastEmbed Architecture

This document describes the internal architecture and design of FastEmbed.

## System Overview

FastEmbed is a multi-layer system designed for maximum performance and cross-platform compatibility:

```
┌──────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│  Node.js │ Python │ C# │ Java │ (Future: Go, Rust, Ruby)     │
└────┬─────┴────┬───┴─────┬─────┴──────────────────────────────┘
     │          │         │         │
     ▼          ▼         ▼         ▼
┌──────────────────────────────────────────────────────────────┐
│                  Language Binding Layer                      │
│  N-API │ pybind11 │ P/Invoke │ JNI                           │
│  (Node.js)  (Python)  (.NET)    (Java)                       │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│                   C API Layer (fastembed.h)                  │
│  - fastembed_generate_embedding_hash()                       │
│  - fastembed_cosine_similarity()                             │
│  - fastembed_dot_product()                                   │
│  - fastembed_vector_norm()                                   │
│  - normalize_vector_asm()                                    │
│  - fastembed_add_vectors()                                   │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│               C Implementation Layer                         │
│  (embedding_lib_c.c)                                         │
│  - Wrapper functions for Assembly routines                   │
│  - Input validation and dimension checks                     │
│  - Fallback C implementations (if Assembly unavailable)      │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│           Assembly Layer (SIMD-optimized)                    │
│  (embedding_lib.asm)                                         │
│  - SIMD instructions (SSE4, AVX2)                            │
│  - Hand-optimized vector operations                          │
│  - System V ABI compliant (callee-saved registers)          │
│  - 16-byte stack alignment                                   │
└──────────────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### 1. Application Layer

**Purpose:** User-facing APIs in native languages (Node.js, Python, C#, Java).

**Responsibilities:**

- Provide idiomatic APIs for each language (e.g., `generate_embedding()` in Python, `generateEmbedding()` in Node.js)
- Handle language-specific data types (numpy arrays, Float32Array, float[], etc.)
- Error handling and exception translation
- Documentation and examples

**Location:** `bindings/nodejs/`, `bindings/python/`, `bindings/csharp/`, `bindings/java/`

---

### 2. Language Binding Layer

**Purpose:** Bridge between high-level languages and the C API.

**Responsibilities:**

- Convert language-native types to C types (strings, arrays, pointers)
- Call C API functions via FFI (Foreign Function Interface)
- Handle memory management (allocation, deallocation, GC integration)
- Ensure thread safety (if applicable)

**Technologies:**

- **Node.js:** N-API (stable ABI across Node versions)
- **Python:** pybind11 (automatic type conversions)
- **C#:** P/Invoke (DllImport for native calls)
- **Java:** JNI (Java Native Interface)

**Location:** `bindings/*/addon/`, `bindings/*/native/`, `bindings/*/src/`

---

### 3. C API Layer

**Purpose:** Universal C interface for all language bindings.

**Responsibilities:**

- Define stable C API with clear function signatures
- Accept C-style arguments (const char*, float*, int)
- Return simple types (float, void) to avoid complex marshaling
- Provide header files (`fastembed.h`, `embedding_lib_c.h`)

**Key Functions:**

- `fastembed_generate_embedding_hash(text, output, dimension)` - Generate embedding
- `fastembed_cosine_similarity(vec1, vec2, dimension)` - Cosine similarity
- `fastembed_dot_product(vec1, vec2, dimension)` - Dot product
- `fastembed_vector_norm(vec, dimension)` - L2 norm
- `normalize_vector_asm(input, output, dimension)` - Normalization
- `fastembed_add_vectors(vec1, vec2, output, dimension)` - Vector addition

**Location:** `bindings/shared/include/`, `bindings/shared/src/embedding_lib_c.c`

---

### 4. C Implementation Layer

**Purpose:** Thin wrapper around Assembly routines, with fallback C implementations.

**Responsibilities:**

- Validate input arguments (null checks, dimension checks)
- Call Assembly functions (e.g., `dot_product_asm`, `cosine_similarity_asm`)
- Provide C fallback implementations if Assembly unavailable (not recommended)
- Handle edge cases (zero-length vectors, NaN/inf values)

**Location:** `bindings/shared/src/embedding_lib_c.c`

---

### 5. Assembly Layer (SIMD-optimized)

**Purpose:** Maximum performance via hand-optimized x86-64 Assembly code.

**Responsibilities:**

- Implement hot-path vector operations using SIMD (SSE4, AVX2)
- Follow System V ABI conventions:
  - Save/restore callee-saved registers (rbx, r12-r15, rbp)
  - Maintain 16-byte stack alignment
  - Use standard calling conventions (rdi, rsi, rdx, rcx for first 4 args)
- Minimize memory allocations and cache misses
- Unroll loops for better CPU pipelining

**Key Functions:**

- `dot_product_asm` - SIMD dot product
- `cosine_similarity_asm` - SIMD cosine similarity
- `vector_norm_asm` - SIMD L2 norm calculation
- `normalize_vector_asm` - SIMD vector normalization
- `add_vectors_asm` - SIMD vector addition
- `generate_hash_embedding_asm` - Hash-based embedding generation

**Location:** `bindings/shared/src/embedding_lib.asm`

---

## Data Flow

### Example: Generate Embedding (Python)

```
1. User calls: client.generate_embedding("machine learning")
   ↓
2. Python binding (pybind11) converts string to const char*
   ↓
3. Calls C API: fastembed_generate_embedding_hash(text, output, 768)
   ↓
4. C implementation validates arguments and calls generate_hash_embedding_asm()
   ↓
5. Assembly code:
   - Hashes text characters using SIMD
   - Combines hashes into 768-dimensional vector
   - Returns via output pointer
   ↓
6. Python binding converts float* to numpy.ndarray
   ↓
7. Returns to user: np.array([0.12, -0.34, ...])
```

---

## Build System

### Multi-Platform Build Strategy

**Linux/macOS:**

- NASM compiles `.asm` → `.o` (object files)
- GCC/Clang links `.o` + `.c` → `.so` (shared library)
- Language bindings link against `.so`

**Windows:**

- NASM compiles `.asm` → `.obj` (object files)
- MSVC links `.obj` + `.c` → `.dll` (dynamic library)
- Language bindings link against `.dll`

### Build Order

```
1. Compile Assembly:
   nasm -f elf64 embedding_lib.asm -o embedding_lib.o

2. Compile C Library:
   gcc -shared -fPIC -O3 -o libfastembed.so embedding_lib.o embedding_lib_c.c

3. Build Language Bindings:
   - Node.js: node-gyp rebuild
   - Python: python setup.py build_ext --inplace
   - C#: dotnet build
   - Java: mvn compile && gcc -shared ... (JNI)
```

### Makefile Hierarchy

```
fastembed/
├── Makefile                    # Root: build all bindings
├── bindings/
│   ├── shared/
│   │   └── Makefile            # Build shared C/Assembly library
│   ├── nodejs/
│   │   ├── package.json        # npm run build (node-gyp)
│   │   └── binding.gyp         # node-gyp configuration
│   ├── python/
│   │   └── setup.py            # python setup.py build
│   ├── csharp/
│   │   └── FastEmbed.csproj    # dotnet build
│   └── java/
│       └── pom.xml             # mvn install
```

---

## Performance Characteristics

> **📊 Detailed Benchmarks:** See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for comprehensive performance data across all language bindings.

### Hash-Based Embedding Generation

**Algorithm:** Deterministic hash combination

- Time complexity: O(n) where n = text length
- Space complexity: O(d) where d = dimension
- No neural network overhead
- **Measured Performance** (all bindings tested):
  - **Python**: 0.012-0.047 ms (20K-84K ops/sec)
  - **Node.js**: 0.014-0.049 ms (20K-71K ops/sec)
  - **Java**: 0.013-0.048 ms (20K-78K ops/sec)
  - **C#**: 0.014-0.051 ms (19K-71K ops/sec)

**Trade-offs:**

- ✅ Ultra-fast (sub-millisecond generation)
- ✅ Deterministic (same text → same embedding)
- ✅ No model loading
- ❌ No semantic understanding (vs. transformer models)

---

### Vector Operations (SIMD)

**Measured Performance** (all bindings, d=768):

| Operation         | Time Complexity | Avg Time       | Throughput Range | Best (Language)   |
| ----------------- | --------------- | -------------- | ---------------- | ----------------- |
| Dot product       | O(d)            | 0.000-0.001 ms | 1.0M-5.6M ops/s  | **5.6M** (C#)     |
| Cosine similarity | O(d)            | 0.001 ms       | 750K-2.0M ops/s  | **2.0M** (C#)     |
| Vector norm (L2)  | O(d)            | 0.000-0.001 ms | 1.4M-5.7M ops/s  | **5.7M** (C#)     |
| Normalization     | O(d)            | 0.001-0.003 ms | 350K-885K ops/s  | **885K** (Python) |
| Vector addition   | O(d)            | 0.003-0.006 ms | 156K-765K ops/s  | **765K** (Python) |

All operations achieve **sub-microsecond** latency across all bindings, confirming SIMD optimizations are active.

**SIMD Instructions Used:**

- SSE4: `movaps`, `mulps`, `addps`, `haddps`, `sqrtss`
- AVX2: `vmulps`, `vaddps`, `vfmadd231ps` (fused multiply-add)

---

## Memory Management

### Allocation Strategy

**C/Assembly Layer:**

- No dynamic allocation (stack-only or caller-provided buffers)
- Caller allocates output arrays (e.g., `float output[768]`)
- Zero-copy operations where possible

**Language Bindings:**

- **Node.js:** Uses N-API `Napi::Float32Array` (GC-managed)
- **Python:** Uses `numpy.ndarray` (reference-counted)
- **C#:** Uses `float[]` (GC-managed)
- **Java:** Uses `float[]` (GC-managed)

### Thread Safety

**Current Status:** Not thread-safe (single-threaded design)

**Future Work:**

- Add thread-local storage for temporary buffers
- Implement lock-free algorithms for read-only operations
- Provide async APIs for concurrent workloads

---

## ABI Compliance (System V x86-64)

**Callee-Saved Registers:** rbx, rbp, r12, r13, r14, r15

- Assembly functions must preserve these via `push`/`pop`

**Stack Alignment:** 16-byte boundary before `call` instructions

- Adjust rsp via `sub rsp, 8` if needed

**Calling Convention:**

- First 6 integer/pointer args: rdi, rsi, rdx, rcx, r8, r9
- First 8 float args: xmm0-xmm7
- Return values: rax (integer), xmm0 (float)

**Reference:** [System V ABI Documentation](https://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf)

---

## Error Handling

### C API

- Return 0 on success, non-zero on error
- No exceptions (C has no exception mechanism)
- Check `errno` for system errors

### Language Bindings

- **Node.js:** Throw JavaScript `Error`
- **Python:** Raise `RuntimeError` or `ValueError`
- **C#:** Throw `FastEmbedException`
- **Java:** Throw `RuntimeException`

---

## Testing Strategy

### Unit Tests

**Location:** Each binding has its own test file

- `bindings/nodejs/test-native.js`
- `bindings/python/test_python_native.py`
- `bindings/csharp/test_csharp_native.csproj`
- `bindings/java/TestFastEmbedJava.java`

**Coverage:**

- Embedding generation
- Vector operations (all functions)
- Edge cases (empty text, zero vectors, dimension mismatches)
- Performance benchmarks (100-1000 iterations)

### Integration Tests

**Location:** `tests/integration/`

- Weaviate integration (semantic search)
- Multi-language interoperability (same embedding across languages)

---

## Future Enhancements

### Phase 1: ONNX Integration

- Load transformer models (nomic-embed-text, sentence-transformers)
- Neural network-based embeddings for semantic understanding
- Fallback to hash-based if model unavailable

### Phase 2: GPU Acceleration

- CUDA support for NVIDIA GPUs
- ROCm support for AMD GPUs
- Automatic fallback to CPU if GPU unavailable

### Phase 3: Async APIs

- Promise-based API (Node.js)
- `async`/`await` support (Python, C#, Java)
- Thread pool for parallel processing

### Phase 4: Additional Languages

- Go binding (via cgo)
- Rust binding (via FFI)
- Ruby binding (via FFI)

---

## References

- [System V ABI x86-64](https://refspecs.linuxbase.org/elf/x86_64-abi-0.99.pdf)
- [Intel SIMD Intrinsics Guide](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html)
- [Node.js N-API Documentation](https://nodejs.org/api/n-api.html)
- [pybind11 Documentation](https://pybind11.readthedocs.io/)
- [P/Invoke Documentation](https://learn.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke)
- [JNI Specification](https://docs.oracle.com/en/java/javase/11/docs/specs/jni/)

---

## See Also

- [API Reference](API.md)
- [Build Instructions](BUILD_NATIVE.md)
- [Use Cases](USE_CASES.md)
