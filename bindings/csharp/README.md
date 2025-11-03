# FastEmbed C# Binding

Native C# binding using P/Invoke for ultra-fast embeddings and vector operations.

## Installation

```bash
dotnet build src/FastEmbed.csproj
```

## Usage

```csharp
using FastEmbed;

var client = new FastEmbedClient(dimension: 256);

// Generate embedding
float[] embedding = client.GenerateEmbedding("Hello, world!");

// Vector operations
float similarity = client.CosineSimilarity(vec1, vec2);
float norm = client.VectorNorm(embedding);
float[] normalized = client.NormalizeVector(embedding);
```

## API

See main [FastEmbed README](../../README.md) for full API documentation.

## Building

### Prerequisites

- .NET SDK 6.0+
- NASM (for assembly)
- C compiler (MSVC on Windows, GCC/Clang on Linux/macOS)

### Build Commands

```bash
# Build shared library first
cd ../shared && make all

# Build C# library
cd ../csharp
dotnet build src/FastEmbed.csproj

# Run tests
LD_LIBRARY_PATH=../shared/build dotnet run --project test_csharp_native.csproj
```

## Performance

**ONNX Runtime Performance** (Nov 2025):

- ONNX embeddings: **28.5-129.6 ms** (8-35 emb/s depending on text length)
  - Short text (108 chars): **28.5 ms** (35 emb/s)
  - Medium text (460 chars): **54.4 ms** (18 emb/s)
  - Long text (1574 chars): **129.6 ms** (8 emb/s)
- Hash-based embeddings: **~0.01-0.1 ms** (~27,000 emb/s average)
- Vector operations: **Sub-microsecond** latency

See [BENCHMARK_RESULTS.md](../../BENCHMARK_RESULTS.md) for complete benchmark data.
