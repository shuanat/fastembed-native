# FastEmbed Node.js Binding

Native Node.js binding using N-API for ultra-fast embeddings and vector operations.

## Installation

```bash
npm install
npm run build
```

## Usage

```javascript
const { FastEmbedNativeClient } = require('./lib/fastembed-native');

const client = new FastEmbedNativeClient();

// Generate embedding
const embedding = client.generateEmbedding("Hello, world!", 256);

// Vector operations
const similarity = client.cosineSimilarity(vec1, vec2);
const norm = client.vectorNorm(embedding);
const normalized = client.normalizeVector(embedding);
```

## API

See main [FastEmbed README](../../README.md) for full API documentation.

## Building

### Prerequisites

- Node.js 14+
- node-gyp
- NASM (for assembly)
- C++ compiler (MSVC on Windows, GCC/Clang on Linux/macOS)

### Build Commands

```bash
npm install        # Install dependencies
npm run build      # Build native module
npm run rebuild    # Clean rebuild
npm test          # Run tests
```

## Performance

**Measured Performance** (Nov 2025):

- Embedding generation: **0.014-0.049 ms** (20K-71K ops/sec)
- Vector operations: **Sub-microsecond** (up to **2.73M ops/sec**)

See [BENCHMARK_RESULTS.md](../../BENCHMARK_RESULTS.md) for complete benchmark data.
