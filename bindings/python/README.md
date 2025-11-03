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

**ONNX Runtime Performance** (Nov 2025):

- ONNX embeddings: **28.6-123.0 ms** (8-35 emb/s depending on text length)
  - Short text (108 chars): **28.6 ms** (35 emb/s)
  - Medium text (460 chars): **51.9 ms** (19 emb/s)
  - Long text (1574 chars): **123.0 ms** (8 emb/s)
- Hash-based embeddings: **~0.01-0.1 ms** (~27,000 emb/s average)
- Vector operations: **Sub-microsecond** latency

See [BENCHMARK_RESULTS.md](../../BENCHMARK_RESULTS.md) for complete benchmark data.
