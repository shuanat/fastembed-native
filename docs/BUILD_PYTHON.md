# Building FastEmbed Python Native Module

Python extension module for FastEmbed using pybind11 for maximum performance.

## Requirements

> **Note**: Common requirements (NASM, compiler) are described in [BUILD_WINDOWS.md](BUILD_WINDOWS.md) (Windows) or [BUILD_CMAKE.md](BUILD_CMAKE.md) (Linux/macOS).

### All Platforms

1. **Python 3.7+**
2. **NumPy** (>=1.20.0)
3. **pybind11** (>=2.10.0)
4. **setuptools**

### Windows

1. **Visual Studio Build Tools 2022**
   - Desktop development with C++
   - See details: [BUILD_WINDOWS.md](BUILD_WINDOWS.md#visual-studio-build-tools)
2. **NASM** (for assembly files)
   - See details: [BUILD_WINDOWS.md](BUILD_WINDOWS.md#nasm-installation)
3. Pre-built object files (`obj/embedding_lib.obj`, `obj/embedding_generator.obj`)

### Linux/macOS

1. **GCC/Clang** (C++17 support)
2. **NASM**

   ```bash
   # Ubuntu/Debian
   sudo apt install nasm
   
   # macOS
   brew install nasm
   ```

   See details: [BUILD_CMAKE.md](BUILD_CMAKE.md#prerequisites)

## Installing Dependencies

```bash
pip install numpy pybind11
```

## Building

### Option 1: Automatic Build (Recommended)

```bash
python setup.py build_ext --inplace
```

This automatically:

1. Detects the platform
2. Compiles assembly files (Linux/macOS)
3. Builds the Python extension module
4. Installs in the current directory

### Option 2: Install as Package

```bash
pip install -e .
```

This installs FastEmbed as an editable package.

### Option 3: Build Wheel for Distribution

```bash
python setup.py bdist_wheel
```

Wheel will be in `dist/fastembed_native-1.0.0-*.whl`

## Building on Windows

### Step 1: Prepare Assembly Files

```cmd
REM Build assembly object files
build_windows.bat

REM Move them to obj/
mkdir obj
copy build\embedding_lib.obj obj\
copy build\embedding_generator.obj obj\
```

### Step 2: Build Python Module

```cmd
python setup.py build_ext --inplace
```

## Building on Linux/macOS

```bash
# Build runs automatically
python setup.py build_ext --inplace
```

## Verifying Build

```python
from python import FastEmbed, is_available

if is_available():
    print("✓ Native module available")
    
    fastembed = FastEmbed(768)
    embedding = fastembed.generate_embedding("test text")
    print(f"Embedding shape: {embedding.shape}")
else:
    print("✗ Native module not available")
```

Or run the test script:

```bash
python test_python_native.py
```

## Usage

### Basic Usage

```python
from python import FastEmbed
import numpy as np

# Initialization
fastembed = FastEmbed(dimension=768)

# Generate embedding
text = "machine learning example"
embedding = fastembed.generate_embedding(text)

print(f"Embedding shape: {embedding.shape}")
print(f"Embedding type: {type(embedding)}")  # numpy.ndarray
```

### Vector Operations

```python
# Two embeddings
emb1 = fastembed.generate_embedding("first text")
emb2 = fastembed.generate_embedding("second text")

# Cosine similarity
similarity = fastembed.cosine_similarity(emb1, emb2)
print(f"Cosine similarity: {similarity:.4f}")

# Dot product
dot = fastembed.dot_product(emb1, emb2)
print(f"Dot product: {dot:.4f}")

# Vector norm
norm = fastembed.vector_norm(emb1)
print(f"Vector norm: {norm:.4f}")

# Normalization
normalized = fastembed.normalize_vector(emb1)

# Vector addition
sum_vec = fastembed.add_vectors(emb1, emb2)
```

### Module-level Functions

```python
from python import generate_embedding, is_available

if is_available():
    # Direct call without creating class
    embedding = generate_embedding("text", dimension=768)
```

## API Reference

### FastEmbed Class

```python
class FastEmbed:
    def __init__(self, dimension: int = 768)
    
    def generate_embedding(self, text: str) -> np.ndarray
    
    def cosine_similarity(
        self, 
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> float
    
    def dot_product(
        self,
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> float
    
    def vector_norm(self, vector: Union[np.ndarray, List[float]]) -> float
    
    def normalize_vector(
        self,
        vector: Union[np.ndarray, List[float]]
    ) -> np.ndarray
    
    def add_vectors(
        self,
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> np.ndarray
```

### Module-level Functions

```python
def is_available() -> bool
    """Check if native module is available"""

def generate_embedding(text: str, dimension: int = 768) -> np.ndarray
    """Generate embedding (module-level)"""
```

## File Structure

```
FastEmbed/
├── python/
│   ├── __init__.py              # Python interface
│   └── fastembed_native.cpp     # pybind11 C++ wrapper
├── setup.py                      # Build script
├── test_python_native.py         # Test script
└── obj/                          # Assembly object files (Windows)
    ├── embedding_lib.obj
    └── embedding_generator.obj
```

## Performance

**Measured Performance** (Nov 2025):

- **Embedding generation**: 0.012-0.047 ms (768 dimensions)
- **Throughput**: 20,000-84,000 embeddings/sec
- **Vector operations**: Sub-microsecond (up to 1.48M ops/sec)
- **Native C++ speed** thanks to SIMD optimizations

See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for complete benchmark data.

## Troubleshooting

### "ModuleNotFoundError: No module named 'fastembed_native'"

Module not built. Run:

```bash
python setup.py build_ext --inplace
```

### Windows: "Assembly object files not found"

Build assembly files first:

```cmd
build_windows.bat
mkdir obj
copy build\*.obj obj\
```

### Linux/macOS: "nasm: command not found"

Install NASM:

```bash
sudo apt install nasm      # Ubuntu/Debian
brew install nasm          # macOS
```

### "ImportError: numpy.core.multiarray failed to import"

Update NumPy:

```bash
pip install --upgrade numpy
```

## Comparison with Other Approaches

| Method       | Speed       | Requirements    | Simplicity  |
| ------------ | ----------- | --------------- | ----------- |
| **pybind11** | **Fastest** | C++ compilation | Medium      |
| ctypes/cffi  | Fast        | DLL/SO          | Simple      |
| Python CLI   | Slow        | Subprocess      | Very simple |

pybind11 provides optimal balance of performance and ease of use.

## Integration with ML Frameworks

### PyTorch

```python
import torch
from python import FastEmbed

fastembed = FastEmbed(768)
embedding = fastembed.generate_embedding("text")

# Convert to PyTorch tensor
tensor = torch.from_numpy(embedding)
```

### TensorFlow

```python
import tensorflow as tf
from python import FastEmbed

fastembed = FastEmbed(768)
embedding = fastembed.generate_embedding("text")

# Convert to TensorFlow tensor
tensor = tf.convert_to_tensor(embedding)
```

### Scikit-learn

```python
from sklearn.metrics.pairwise import cosine_similarity
from python import FastEmbed

fastembed = FastEmbed(768)
embeddings = [
    fastembed.generate_embedding(text)
    for text in texts
]

# Use as regular NumPy arrays
similarity_matrix = cosine_similarity(embeddings)
```

## Next Steps

1. Publish wheel packages to PyPI
2. GPU acceleration support (CUDA)
3. Batch processing for multiple texts
4. ONNX model support
