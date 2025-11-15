# Building FastEmbed C# Native Module

C# interface for FastEmbed using P/Invoke for direct native function calls.

## Requirements

> **Note**: Common requirements (NASM, compiler) are described in [BUILD_WINDOWS.md](BUILD_WINDOWS.md) (Windows) or [BUILD_CMAKE.md](BUILD_CMAKE.md) (Linux/macOS).

### Windows

1. **.NET SDK 6.0+**

   ```powershell
   winget install Microsoft.DotNet.SDK.6
   ```

2. **Visual Studio Build Tools 2022** (for building native library)
   - See details: [BUILD_WINDOWS.md](BUILD_WINDOWS.md#visual-studio-build-tools)
3. **NASM** (if not already installed)
   - See details: [BUILD_WINDOWS.md](BUILD_WINDOWS.md#nasm-installation)

### Linux/macOS

1. **.NET SDK 6.0+**

   ```bash
   # Ubuntu/Debian
   sudo apt install dotnet-sdk-6.0
   
   # macOS
   brew install dotnet-sdk
   ```

2. **GCC/Clang**
3. **NASM**
   - See details: [BUILD_CMAKE.md](BUILD_CMAKE.md#prerequisites)

## File Structure

```
FastEmbed/
├── csharp/
│   ├── FastEmbed.cs              # High-level API
│   ├── FastEmbedNative.cs        # P/Invoke declarations
│   └── FastEmbed.csproj          # .NET project
├── tests/                        # xUnit test suite (49+ tests)
│   ├── FastEmbed.Tests.csproj
│   ├── FastEmbedClientTests.cs
│   ├── FastEmbedIntegrationTests.cs
│   ├── FastEmbedOnnxTests.cs
│   └── FastEmbedPerformanceTests.cs
└── build/                        # Native libraries
    ├── fastembed.dll             # Windows
    ├── libfastembed.so           # Linux
    └── libfastembed.dylib        # macOS
```

## Building

### Step 1: Build Native Library

#### Windows

```cmd
REM Build DLL
build_windows.bat

REM Copy to build directory
mkdir build
copy fastembed.dll build\
```

#### Linux/macOS

```bash
# Build shared library
make shared

# Copy to build directory
mkdir -p build
cp libfastembed.so build/    # Linux
cp libfastembed.dylib build/ # macOS
```

### Step 2: Build C# Project

```bash
cd csharp
dotnet build
```

Or for Release build:

```bash
cd csharp
dotnet build -c Release
```

## Running Tests

### Option 1: Direct Test Execution

```bash
# Run test suite
cd tests
dotnet test
```

**Test Suite**: Comprehensive xUnit test suite with 49+ tests covering unit, integration, ONNX, and performance scenarios.

### Option 2: Via WSL (if on Windows)

```bash
wsl bash -c "cd /mnt/g/GitHub/KAG-workspace/FastEmbed && \
  cd bindings/csharp && dotnet build src/FastEmbed.csproj && \
  cd tests && dotnet test"
```

## Using in Your Project

### Option 1: Reference DLL

```bash
dotnet add reference path/to/FastEmbed/csharp/bin/Release/net6.0/FastEmbed.dll
```

### Option 2: NuGet Package (after publication)

```bash
dotnet add package FastEmbed.Native
```

### Code Example

```csharp
using FastEmbed;

class Program
{
    static void Main()
    {
        // Initialization
        var fastembed = new FastEmbedClient(dimension: 768);
        
        // Generate embedding
        string text = "machine learning example";
        float[] embedding = fastembed.GenerateEmbedding(text);
        
        Console.WriteLine($"Embedding shape: {embedding.Length}");
        Console.WriteLine($"First 5 values: [{string.Join(", ", embedding.Take(5))}]");
        
        // Vector operations
        string text2 = "deep learning neural networks";
        float[] embedding2 = fastembed.GenerateEmbedding(text2);
        
        float similarity = fastembed.CosineSimilarity(embedding, embedding2);
        Console.WriteLine($"Cosine similarity: {similarity:F4}");
    }
}
```

## API Reference

### FastEmbedClient Class

#### Constructor

```csharp
public FastEmbedClient(int dimension = 768)
```

Creates a new FastEmbed client with the specified embedding dimension.

#### Methods

**GenerateEmbedding**

```csharp
public float[] GenerateEmbedding(string text)
```

Generates a hash-based embedding for text.

- **Parameters**: `text` - input text
- **Returns**: `float[]` - embedding vector
- **Exceptions**: `ArgumentNullException`, `FastEmbedException`

**CosineSimilarity**

```csharp
public float CosineSimilarity(float[] vectorA, float[] vectorB)
```

Calculates cosine similarity between two vectors.

- **Parameters**: two vectors of the same dimension
- **Returns**: `float` - cosine similarity in range [-1, 1]
- **Exceptions**: `ArgumentException`

**DotProduct**

```csharp
public float DotProduct(float[] vectorA, float[] vectorB)
```

Calculates dot product of two vectors.

**VectorNorm**

```csharp
public float VectorNorm(float[] vector)
```

Calculates L2 norm of a vector.

**NormalizeVector**

```csharp
public float[] NormalizeVector(float[] vector)
```

Normalizes a vector (L2 normalization). Returns a new array.

**AddVectors**

```csharp
public float[] AddVectors(float[] vectorA, float[] vectorB)
```

Adds two vectors element-wise.

**TextSimilarity**

```csharp
public float TextSimilarity(string text1, string text2)
```

Calculates semantic similarity between two texts (generates embeddings and calculates cosine similarity).

**GenerateEmbeddings**

```csharp
public float[][] GenerateEmbeddings(params string[] texts)
```

Generates embeddings for multiple texts (batch processing).

## Performance

**Measured Performance** (Linux/WSL, Nov 2025):

- **Embedding generation**: 0.014-0.051 ms
- **Throughput**: 19,000-71,000 embeddings/sec
- **Vector operations**: Sub-microsecond (up to **5.72M ops/sec** - fastest of all bindings!)

See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for complete benchmark data.

Thanks to:

- P/Invoke (direct native calls, minimal overhead)
- SIMD optimizations in assembly
- `-O3 -march=native` compilation

## Troubleshooting

### "DllNotFoundException: Unable to load DLL 'fastembed'"

**Cause**: Native library not found in PATH or next to .exe/.dll.

**Solution**:

1. Ensure `fastembed.dll` (Windows) or `libfastembed.so` (Linux) is compiled:

   ```bash
   # Windows
   build_windows.bat
   
   # Linux
   make shared
   ```

2. Copy library to the executable directory:

   ```bash
   cp build/fastembed.dll csharp/bin/Debug/net6.0/
   ```

3. Or add `build/` to PATH:

   ```bash
   # Windows
   set PATH=%PATH%;G:\GitHub\KAG-workspace\FastEmbed\build
   
   # Linux
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/FastEmbed/build
   ```

### "BadImageFormatException: An attempt was made to load a program with an incorrect format"

**Cause**: Architecture mismatch (x86 vs x64).

**Solution**: Ensure .NET project and native library are built for the same architecture (usually x64).

```xml
<!-- In .csproj -->
<PropertyGroup>
  <PlatformTarget>x64</PlatformTarget>
</PropertyGroup>
```

### "FileNotFoundException: Could not load file or assembly 'FastEmbed'"

**Cause**: FastEmbed.dll (.NET) assembly not found.

**Solution**:

```bash
cd csharp
dotnet build
```

Then add a reference to the assembly in your project.

## Publishing NuGet Package

### Step 1: Create .nuspec

```xml
<?xml version="1.0"?>
<package>
  <metadata>
    <id>FastEmbed.Native</id>
    <version>1.0.0</version>
    <authors>FastEmbed Team</authors>
    <description>High-performance hash-based text embedding library</description>
    <license type="AGPL-3.0">https://www.gnu.org/licenses/agpl-3.0.html</license>
  </metadata>
  <files>
    <file src="bin/Release/net6.0/FastEmbed.dll" target="lib/net6.0" />
    <file src="../build/fastembed.dll" target="runtimes/win-x64/native" />
    <file src="../build/libfastembed.so" target="runtimes/linux-x64/native" />
    <file src="../build/libfastembed.dylib" target="runtimes/osx-x64/native" />
  </files>
</package>
```

### Step 2: Pack and Publish

```bash
cd csharp
dotnet pack -c Release
dotnet nuget push bin/Release/FastEmbed.Native.1.0.0.nupkg --source https://api.nuget.org/v3/index.json --api-key YOUR_API_KEY
```

## Integration with ML.NET

```csharp
using Microsoft.ML;
using Microsoft.ML.Data;
using FastEmbed;

class Program
{
    public class TextData
    {
        public string Text { get; set; }
    }

    public class EmbeddingData
    {
        [VectorType(768)]
        public float[] Embedding { get; set; }
    }

    static void Main()
    {
        var mlContext = new MLContext();
        var fastembed = new FastEmbedClient(768);

        // Create data
        var data = new[]
        {
            new TextData { Text = "machine learning" },
            new TextData { Text = "deep learning" }
        };

        var dataView = mlContext.Data.LoadFromEnumerable(data);

        // Add embeddings
        var pipeline = mlContext.Transforms.CustomMapping<TextData, EmbeddingData>(
            (input, output) => {
                output.Embedding = fastembed.GenerateEmbedding(input.Text);
            },
            contractName: "FastEmbedTransform"
        );

        var transformedData = pipeline.Fit(dataView).Transform(dataView);
    }
}
```

## Next Steps

1. **Publish to NuGet**
2. **CI/CD for automated builds**
3. **.NET Framework 4.x support**
4. **Async API** (Task-based)
5. **GPU acceleration** (CUDA)

---

**Created**: November 1, 2025  
**Status**: ✓ Ready for use  
**Performance**: ★★★★★ (native P/Invoke speed)
