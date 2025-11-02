# FastEmbed Python Binding

Native Python extension using pybind11 for ultra-fast embeddings and vector operations.

## Installation

```bash
pip install .
```

Or for development:

```bash
python setup.py build_ext --inplace
```

## Usage

```python
import numpy as np
from fastembed_native import FastEmbedNative

client = FastEmbedNative(dimension=256)

# Generate embedding
embedding = client.generate_embedding("Hello, world!")

# Vector operations
similarity = client.cosine_similarity(vec1, vec2)
norm = client.vector_norm(embedding)
normalized = client.normalize_vector(embedding)
```

## API

See main [FastEmbed README](../../README.md) for full API documentation.

## Building

### Prerequisites

- Python 3.6+
- pybind11
- NASM (for assembly)
- C++ compiler (MSVC on Windows, GCC/Clang on Linux/macOS)

### Build Commands

```bash
pip install pybind11 numpy
python setup.py build_ext --inplace  # Build in-place
python setup.py install               # Install system-wide
```

## Performance

**Measured Performance** (Nov 2025):

- Embedding generation: **0.012-0.047 ms** (20K-84K ops/sec)
- Vector operations: **Sub-microsecond** (up to **1.48M ops/sec**)

See [BENCHMARK_RESULTS.md](../../BENCHMARK_RESULTS.md) for complete benchmark data.
