# Building FastEmbed Native N-API Module

**Navigation**: [Documentation Index](README.md) → Build Guides → Node.js

FastEmbed now uses a native N-API module instead of FFI for maximum performance and reliability on Windows.

## Requirements

> **Note**: Common requirements (NASM, compiler) are described in [BUILD_WINDOWS.md](BUILD_WINDOWS.md) (Windows) or [BUILD_CMAKE.md](BUILD_CMAKE.md) (Linux/macOS).

### Windows

1. **Visual Studio Build Tools 2022** (or full Visual Studio)
   - Download: <https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022>
   - Install workload: "Desktop development with C++"
   - Includes: MSVC, Windows SDK, MSBuild

2. **NASM** (Netwide Assembler)
   - Install NASM and add to PATH
   - Or use `build_windows.bat` script for automatic assembly file compilation
   - See details: [BUILD_WINDOWS.md](BUILD_WINDOWS.md#nasm-installation)

3. **Python 3.x**
   - For node-gyp
   - Download: <https://www.python.org/downloads/>

4. **Node.js** (v16+)

### Linux/macOS

1. **GCC/Clang** (usually already installed)
2. **NASM** (for assembly files)

   ```bash
   # Ubuntu/Debian
   sudo apt install nasm
   
   # macOS
   brew install nasm
   ```

   See details: [BUILD_CMAKE.md](BUILD_CMAKE.md#prerequisites)

3. **Python 3.x**
4. **Node.js** (v16+)

## Building

### Automatic Build (Recommended)

```bash
npm install
```

This automatically:

1. Installs dependencies (`node-gyp`, `node-addon-api`)
2. Builds the native module
3. Uses CLI fallback on error

### Manual Build

#### Windows

1. **Build assembly object files:**

   ```cmd
   build_windows.bat
   ```

   This creates `build/embedding_lib.obj` and `build/embedding_generator.obj`

2. **Build the native module:**

   ```cmd
   npm run build
   ```

#### Linux/macOS

```bash
# Build shared library (optional for CLI)
make shared

# Build the native module
npm run build
```

### Debug Build

```bash
npm run build:debug
```

## Verifying Build

```javascript
const { loadNativeModule, generateEmbedding } = require('./lib/fastembed-native');

if (loadNativeModule()) {
  console.log('✓ Native module loaded successfully!');
  
  const embedding = generateEmbedding('test text', 768);
  console.log('✓ Embedding generated:', embedding.length, 'dimensions');
} else {
  console.log('✗ Native module not available, using CLI fallback');
}
```

Or via TypeScript:

```typescript
import { FastEmbedNativeClient } from './lib/fastembed-native';

const client = new FastEmbedNativeClient(768);

if (client.isAvailable()) {
  const embedding = await client.generateEmbedding('test text');
  console.log('Embedding:', embedding);
}
```

## Architecture

### N-API vs FFI

| Aspect            | N-API (Native)       | FFI                   |
| ----------------- | -------------------- | --------------------- |
| **Performance**   | Maximum (native)     | Medium (overhead)     |
| **Build**         | Requires compilation | No compilation needed |
| **Compatibility** | ABI-stable           | Issues on Windows     |
| **Support**       | Official Node.js     | Third-party library   |
| **Types**         | Direct conversion    | Requires ref-napi     |

### Structure

```
FastEmbed/
├── addon/
│   └── fastembed_napi.cc       # N-API C++ wrapper
├── lib/
│   └── fastembed-native.ts     # TypeScript interface
├── src/
│   ├── embedding_lib.asm       # Optimized SIMD functions
│   ├── embedding_generator.asm # Hash-based generator
│   └── embedding_lib_c.c       # C function wrappers
├── binding.gyp                 # node-gyp configuration
└── build/
    └── Release/
        └── fastembed_native.node  # Compiled module
```

## API

### Exported Functions

```typescript
// Embedding generation
generateEmbedding(text: string, dimension?: number): Float32Array

// Vector operations
cosineSimilarity(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): number
dotProduct(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): number
vectorNorm(vector: Float32Array | number[]): number
normalizeVector(vector: Float32Array | number[]): Float32Array
addVectors(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): Float32Array
```

### FastEmbedNativeClient

Wrapper class for convenient usage:

```typescript
const client = new FastEmbedNativeClient(768);

// Check availability
if (client.isAvailable()) {
  // Generation
  const embedding = await client.generateEmbedding('text');
  
  // Vector operations
  const similarity = client.cosineSimilarity(vec1, vec2);
  const dot = client.dotProduct(vec1, vec2);
  const norm = client.vectorNorm(vec1);
}
```

## Troubleshooting

### Windows: "MSBuild failed"

Ensure Visual Studio Build Tools are installed:

```cmd
npm config set msvs_version 2022
npm run build
```

### Windows: "NASM not found"

Run `build_windows.bat` first, or add NASM to PATH.

### Linux/macOS: "nasm: command not found"

```bash
sudo apt install nasm  # Ubuntu/Debian
brew install nasm      # macOS
```

### "Native module not found"

Module not built or build failed. CLI fallback is used automatically.

## Performance

**Measured Performance** (Nov 2025):

- **N-API**: 0.014-0.049 ms per embedding (native speed, measured)
- **FFI**: Legacy/not recommended (use N-API instead)
- **CLI**: ~50ms per embedding (process startup overhead)

N-API provides **1000x speedup** compared to CLI for multiple calls.

See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for complete benchmark data.

## Fallback Chain

FastEmbed automatically uses the best available method:

1. **Native N-API** (fastest) ← default
2. **CLI mode** (fallback) ← if N-API is not available

FFI is no longer used due to issues on Windows.

---

## See Also

### Related Documentation

- **[Architecture Documentation](ARCHITECTURE.md)** - System architecture and build system details
- **[API Reference](API.md)** - Complete API documentation for Node.js
- **[Use Cases](USE_CASES.md)** - Real-world scenarios and applications

### Other Build Guides

- **[Build CMake](BUILD_CMAKE.md)** - Cross-platform CMake build (recommended)
- **[Build Windows](BUILD_WINDOWS.md)** - Windows-specific build instructions
- **[Build Python](BUILD_PYTHON.md)** - Python pybind11 module build
- **[Build C#](BUILD_CSHARP.md)** - C# P/Invoke module build
- **[Build Java](BUILD_JAVA.md)** - Java JNI module build

### Additional Resources

- **[Documentation Index](README.md)** - Complete documentation overview
- **[Main README](../README.md)** - Project overview and quick start
