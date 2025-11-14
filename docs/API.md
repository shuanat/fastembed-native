# FastEmbed API Reference

Complete API documentation for all language bindings.

## C API (Shared Library)

### Core Functions

#### `fastembed_generate_embedding_hash`

```c
void fastembed_generate_embedding_hash(const char* text, float* output, int dimension);
```

Generate hash-based embedding from text.

**Parameters:**

- `text` - Input text string (null-terminated)
- `output` - Output float array (must be pre-allocated)
- `dimension` - Embedding dimension (e.g., 256, 512, 768)

**Returns:** None (modifies `output` in-place)

---

### Vector Operations

#### `fastembed_dot_product`

```c
float fastembed_dot_product(const float* vec1, const float* vec2, int dimension);
```

Calculate dot product of two vectors.

**Parameters:**

- `vec1`, `vec2` - Input vectors
- `dimension` - Vector dimension

**Returns:** Dot product (float)

---

#### `fastembed_cosine_similarity`

```c
float fastembed_cosine_similarity(const float* vec1, const float* vec2, int dimension);
```

Calculate cosine similarity between two vectors.

**Parameters:**

- `vec1`, `vec2` - Input vectors
- `dimension` - Vector dimension

**Returns:** Cosine similarity (-1.0 to 1.0)

---

#### `fastembed_vector_norm`

```c
float fastembed_vector_norm(const float* vec, int dimension);
```

Calculate L2 norm of a vector.

**Parameters:**

- `vec` - Input vector
- `dimension` - Vector dimension

**Returns:** L2 norm (float)

---

#### `normalize_vector_asm`

```c
void normalize_vector_asm(const float* input, float* output, int dimension);
```

Normalize vector to unit length (L2 normalization).

**Parameters:**

- `input` - Input vector
- `output` - Output vector (must be pre-allocated)
- `dimension` - Vector dimension

**Returns:** None (modifies `output`)

---

#### `fastembed_add_vectors`

```c
void fastembed_add_vectors(const float* vec1, const float* vec2, float* output, int dimension);
```

Element-wise vector addition.

**Parameters:**

- `vec1`, `vec2` - Input vectors
- `output` - Output vector (must be pre-allocated)
- `dimension` - Vector dimension

**Returns:** None (modifies `output`)

---

### ONNX Model Functions

#### `fastembed_onnx_get_model_dimension`

```c
int fastembed_onnx_get_model_dimension(const char* model_path);
```

Get the output dimension of an ONNX embedding model. If the model is already loaded (cached), returns the cached dimension immediately. Otherwise, loads the model to detect the dimension.

**Parameters:**

- `model_path` - Path to .onnx model file (must be readable)

**Returns:**

- Model output dimension on success (positive integer)
- `-1` on error (model not found, invalid model, dimension detection failed, ONNX Runtime not available)

**Notes:**

- The dimension is cached per model path for performance
- Use this function to determine the correct dimension before calling `fastembed_onnx_generate()`
- Returns `-1` if ONNX Runtime is not available (compiled without `USE_ONNX_RUNTIME`)

**Example:**

```c
int dim = fastembed_onnx_get_model_dimension("model.onnx");
if (dim > 0) {
    float *output = malloc(dim * sizeof(float));
    fastembed_onnx_generate("model.onnx", "text", output, dim);
}
```

---

#### `fastembed_onnx_generate`

```c
int fastembed_onnx_generate(const char* model_path, const char* text, float* output, int dimension);
```

Generate embedding using ONNX Runtime model. Loads a trained ONNX embedding model (e.g., BERT-based, nomic-embed-text) and generates embeddings using neural network inference.

**Parameters:**

- `model_path` - Path to .onnx model file (must be readable)
- `text` - Input text to embed (null-terminated string, max 8192 chars)
- `output` - Output array for embedding vector (must be pre-allocated, size >= dimension)
- `dimension` - Requested embedding dimension (must match model output, max 2048). If 0, automatically detects dimension from model.

**Returns:**

- `0` on success
- `-1` on error (file not found, inference failure, dimension mismatch, etc.)

**Notes:**

- Requires ONNX Runtime to be installed and linked at compile time
- Compile with `-DUSE_ONNX_RUNTIME` to enable ONNX support
- Falls back to hash-based embedding if ONNX Runtime unavailable
- Output embedding is L2-normalized (unit vector)
- Model is cached after first load - use `fastembed_onnx_unload()` to free memory
- Dimension is automatically validated against model output
- Use `fastembed_onnx_get_model_dimension()` to get model dimension before calling this function
- If `dimension` is 0, the function automatically detects the dimension from the model

**Example:**

```c
// Auto-detect dimension
int result = fastembed_onnx_generate("model.onnx", "text", output, 0);

// Or specify dimension explicitly (must match model)
int dim = fastembed_onnx_get_model_dimension("model.onnx");
if (dim > 0) {
    float *output = malloc(dim * sizeof(float));
    fastembed_onnx_generate("model.onnx", "text", output, dim);
}
```

---

#### `fastembed_onnx_unload`

```c
int fastembed_onnx_unload(void);
```

Unload cached ONNX model session. Frees the cached ONNX model session from memory.

**Returns:**

- `0` on success
- `-1` if ONNX Runtime not initialized or nothing to unload

**Notes:**

- Safe to call even if no model is loaded (returns 0)
- This function only affects the cached session, not ONNX Runtime itself
- After calling this function, the next call to `fastembed_onnx_generate()` will automatically reload the model

---

#### `fastembed_onnx_get_last_error`

```c
int fastembed_onnx_get_last_error(char* error_buffer, size_t buffer_size);
```

Get last error message from ONNX operations. Returns the last error message that occurred during ONNX operations.

**Parameters:**

- `error_buffer` - Output buffer for error message (must be at least 512 bytes)
- `buffer_size` - Size of error buffer

**Returns:**

- `0` on success (error message copied)
- `-1` if no error message available

**Notes:**

- Only available when compiled with `USE_ONNX_RUNTIME`
- Error message is cleared on each new ONNX operation

---

## Node.js API (N-API)

### Class: `FastEmbedNativeClient`

```javascript
const { FastEmbedNativeClient } = require('./lib/fastembed-native');
const client = new FastEmbedNativeClient(dimension);
```

#### Constructor

```javascript
new FastEmbedNativeClient(dimension)
```

- `dimension` (number) - Embedding dimension (default: 768)

---

#### `generateEmbedding(text)`

```javascript
const embedding = client.generateEmbedding(text);
```

Generate embedding from text.

- **Parameters:**
  - `text` (string) - Input text
- **Returns:** `Float32Array` - Embedding vector

---

#### `cosineSimilarity(vec1, vec2)`

```javascript
const similarity = client.cosineSimilarity(vec1, vec2);
```

Calculate cosine similarity.

- **Parameters:**
  - `vec1`, `vec2` (Float32Array) - Input vectors
- **Returns:** `number` - Similarity (-1 to 1)

---

#### `dotProduct(vec1, vec2)`

```javascript
const dotProd = client.dotProduct(vec1, vec2);
```

Calculate dot product.

- **Parameters:**
  - `vec1`, `vec2` (Float32Array) - Input vectors
- **Returns:** `number` - Dot product

---

#### `vectorNorm(vec)`

```javascript
const norm = client.vectorNorm(vec);
```

Calculate L2 norm.

- **Parameters:**
  - `vec` (Float32Array) - Input vector
- **Returns:** `number` - L2 norm

---

#### `normalizeVector(vec)`

```javascript
const normalized = client.normalizeVector(vec);
```

Normalize vector to unit length.

- **Parameters:**
  - `vec` (Float32Array) - Input vector
- **Returns:** `Float32Array` - Normalized vector

---

#### `addVectors(vec1, vec2)`

```javascript
const sum = client.addVectors(vec1, vec2);
```

Element-wise vector addition.

- **Parameters:**
  - `vec1`, `vec2` (Float32Array) - Input vectors
- **Returns:** `Float32Array` - Sum vector

---

## Python API (pybind11)

### Class: `FastEmbedNative`

```python
from fastembed_native import FastEmbedNative
client = FastEmbedNative(dimension)
```

#### Constructor

```python
FastEmbedNative(dimension: int = 768)
```

- `dimension` (int) - Embedding dimension

---

#### `generate_embedding(text)`

```python
embedding = client.generate_embedding(text)
```

Generate embedding from text.

- **Parameters:**
  - `text` (str) - Input text
- **Returns:** `numpy.ndarray` - Embedding vector (dtype=float32)

---

#### `cosine_similarity(vec1, vec2)`

```python
similarity = client.cosine_similarity(vec1, vec2)
```

Calculate cosine similarity.

- **Parameters:**
  - `vec1`, `vec2` (numpy.ndarray) - Input vectors
- **Returns:** `float` - Similarity (-1 to 1)

---

#### `dot_product(vec1, vec2)`

```python
dot_prod = client.dot_product(vec1, vec2)
```

Calculate dot product.

- **Parameters:**
  - `vec1`, `vec2` (numpy.ndarray) - Input vectors
- **Returns:** `float` - Dot product

---

#### `vector_norm(vec)`

```python
norm = client.vector_norm(vec)
```

Calculate L2 norm.

- **Parameters:**
  - `vec` (numpy.ndarray) - Input vector
- **Returns:** `float` - L2 norm

---

#### `normalize_vector(vec)`

```python
normalized = client.normalize_vector(vec)
```

Normalize vector to unit length.

- **Parameters:**
  - `vec` (numpy.ndarray) - Input vector
- **Returns:** `numpy.ndarray` - Normalized vector

---

#### `add_vectors(vec1, vec2)`

```python
sum_vec = client.add_vectors(vec1, vec2)
```

Element-wise vector addition.

- **Parameters:**
  - `vec1`, `vec2` (numpy.ndarray) - Input vectors
- **Returns:** `numpy.ndarray` - Sum vector

---

## C# API (P/Invoke)

### Class: `FastEmbedClient`

```csharp
using FastEmbed;
var client = new FastEmbedClient(dimension);
```

#### Constructor

```csharp
public FastEmbedClient(int dimension = 768)
```

- `dimension` (int) - Embedding dimension

---

#### `GenerateEmbedding(text)`

```csharp
float[] embedding = client.GenerateEmbedding(text);
```

Generate embedding from text.

- **Parameters:**
  - `text` (string) - Input text
- **Returns:** `float[]` - Embedding vector

---

#### `CosineSimilarity(vec1, vec2)`

```csharp
float similarity = client.CosineSimilarity(vec1, vec2);
```

Calculate cosine similarity.

- **Parameters:**
  - `vec1`, `vec2` (float[]) - Input vectors
- **Returns:** `float` - Similarity (-1 to 1)

---

#### `DotProduct(vec1, vec2)`

```csharp
float dotProd = client.DotProduct(vec1, vec2);
```

Calculate dot product.

- **Parameters:**
  - `vec1`, `vec2` (float[]) - Input vectors
- **Returns:** `float` - Dot product

---

#### `VectorNorm(vec)`

```csharp
float norm = client.VectorNorm(vec);
```

Calculate L2 norm.

- **Parameters:**
  - `vec` (float[]) - Input vector
- **Returns:** `float` - L2 norm

---

#### `NormalizeVector(vec)`

```csharp
float[] normalized = client.NormalizeVector(vec);
```

Normalize vector to unit length.

- **Parameters:**
  - `vec` (float[]) - Input vector
- **Returns:** `float[]` - Normalized vector

---

#### `AddVectors(vec1, vec2)`

```csharp
float[] sum = client.AddVectors(vec1, vec2);
```

Element-wise vector addition.

- **Parameters:**
  - `vec1`, `vec2` (float[]) - Input vectors
- **Returns:** `float[]` - Sum vector

---

## Java API (JNI)

### Class: `FastEmbed`

```java
import com.fastembed.FastEmbed;
FastEmbed client = new FastEmbed(dimension);
```

#### Constructor

```java
public FastEmbed(int dimension)
```

- `dimension` (int) - Embedding dimension

---

#### `generateEmbedding(text)`

```java
float[] embedding = client.generateEmbedding(text);
```

Generate embedding from text.

- **Parameters:**
  - `text` (String) - Input text
- **Returns:** `float[]` - Embedding vector

---

#### `cosineSimilarity(vec1, vec2)`

```java
float similarity = client.cosineSimilarity(vec1, vec2);
```

Calculate cosine similarity.

- **Parameters:**
  - `vec1`, `vec2` (float[]) - Input vectors
- **Returns:** `float` - Similarity (-1 to 1)

---

#### `dotProduct(vec1, vec2)`

```java
float dotProd = client.dotProduct(vec1, vec2);
```

Calculate dot product.

- **Parameters:**
  - `vec1`, `vec2` (float[]) - Input vectors
- **Returns:** `float` - Dot product

---

#### `vectorNorm(vec)`

```java
float norm = client.vectorNorm(vec);
```

Calculate L2 norm.

- **Parameters:**
  - `vec` (float[]) - Input vector
- **Returns:** `float` - L2 norm

---

#### `normalizeVector(vec)`

```java
float[] normalized = client.normalizeVector(vec);
```

Normalize vector to unit length.

- **Parameters:**
  - `vec` (float[]) - Input vector
- **Returns:** `float[]` - Normalized vector

---

#### `addVectors(vec1, vec2)`

```java
float[] sum = client.addVectors(vec1, vec2);
```

Element-wise vector addition.

- **Parameters:**
  - `vec1`, `vec2` (float[]) - Input vectors
- **Returns:** `float[]` - Sum vector

---

## Error Handling

### C API

C functions do not throw exceptions. Check return values and `errno` for errors.

### Node.js API

Throws JavaScript `Error` on invalid arguments or internal errors.

```javascript
try {
  const embedding = client.generateEmbedding(text);
} catch (error) {
  console.error('FastEmbed error:', error.message);
}
```

### Python API

Raises Python `RuntimeError` or `ValueError` on errors.

```python
try:
    embedding = client.generate_embedding(text)
except RuntimeError as e:
    print(f'FastEmbed error: {e}')
```

### C# API

Throws `FastEmbedException` on errors.

```csharp
try {
    float[] embedding = client.GenerateEmbedding(text);
} catch (FastEmbedException e) {
    Console.WriteLine($"FastEmbed error: {e.Message}");
}
```

### Java API

Throws `RuntimeException` on errors.

```java
try {
    float[] embedding = client.generateEmbedding(text);
} catch (RuntimeException e) {
    System.err.println("FastEmbed error: " + e.getMessage());
}
```

---

## Performance Tips

1. **Reuse client instances** - Avoid creating multiple clients; reuse one instance across calls.
2. **Batch processing** - Process multiple embeddings in a loop to amortize overhead.
3. **Pre-allocate arrays** (C API) - Reuse output arrays to reduce allocation overhead.
4. **Use SIMD-optimized builds** - Compile with `-O3 -march=native` for maximum performance.
5. **Normalize once** - If comparing many vectors, normalize them once upfront.

---

## See Also

- [Architecture Documentation](ARCHITECTURE.md)
- [Build Guides](BUILD_NATIVE.md)
- [Use Cases](USE_CASES.md)
