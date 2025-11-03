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

**ONNX Runtime Performance** (Nov 2025):

- ONNX embeddings: **27.1-123.1 ms** (8-37 emb/s depending on text length)
  - Short text (108 chars): **27.1 ms** (37 emb/s)
  - Medium text (460 chars): **53.6 ms** (19 emb/s)
  - Long text (1574 chars): **123.1 ms** (8 emb/s)
- Hash-based embeddings: **~0.01-0.1 ms** (~27,000 emb/s average)
- Vector operations: **Sub-microsecond** latency

See [BENCHMARK_RESULTS.md](../../BENCHMARK_RESULTS.md) for complete benchmark data.
