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
