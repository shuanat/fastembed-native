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

**Measured Performance** (Nov 2025):

- Embedding generation: **0.014-0.051 ms** (19K-71K ops/sec)
- Vector operations: **Sub-microsecond** (up to **5.72M ops/sec** - fastest!)

See [BENCHMARK_RESULTS.md](../../BENCHMARK_RESULTS.md) for complete benchmark data.
