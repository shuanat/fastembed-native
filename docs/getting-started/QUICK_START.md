# Quick Start

**Complete quick start guide for FastEmbed - from building to integration.**

---

## 🚀 Building FastEmbed

### Prerequisites

**Windows**:

- Visual Studio 2022 Build Tools (with "Desktop development with C++")
- NASM >= 2.14 ([download](https://www.nasm.us/))
- Node.js 18+ (for Node.js binding)
- Python 3.7+ (for Python binding)
- .NET SDK 8.0+ (for C# binding)
- JDK 17+ and Maven (for Java binding)

**Linux/macOS**:

- NASM (assembler) >= 2.14
- C/C++ compiler (GCC 7+, Clang, or MSVC)
- Make

### Build Shared Native Library

**Windows**:

```batch
# Build shared library
python scripts\build_native.py

# Or use batch script
scripts\build_windows.bat
```

**Linux/macOS**:

```bash
# Clone repository
git clone https://github.com/shuanat/fastembed-native.git
cd fastembed-native

# Build shared C/Assembly library
make shared

# Or manually
cd bindings/shared
make all
make shared
cd ../..
```

**macOS** (alternative):

```bash
# Use Makefile (recommended)
make shared

# Or use cross-platform build script
python scripts/build_native.py
```

### Build All Language Bindings

**Windows**:

```batch
# Build shared library first
scripts\build_windows.bat

# Then build all bindings using Makefile
make all

# Or build individually:
cd bindings\nodejs && npm install && npm run build
cd ..\python && python setup.py build_ext --inplace
cd ..\csharp\src && dotnet build
cd ..\..\java\java && mvn compile
```

**Linux/macOS**:

```bash
# Build all bindings
make all

# Or build individually (see language sections below)
```

### Choose Your Language

#### Node.js

**Windows**:

```batch
cd bindings\nodejs
npm install
npm run build
node test-native.js
```

**Linux/macOS**:

```bash
cd bindings/nodejs
npm install
npm run build
node test-native.js
```

**Usage**:

```javascript
const { FastEmbedNativeClient } = require('./lib/fastembed-native');

const client = new FastEmbedNativeClient(768);
const embedding = client.generateEmbedding("machine learning");
console.log(embedding); // Float32Array[768]
```

#### Python

**Windows**:

```batch
REM Build shared native library first (required on Windows)
REM This produces embedding_lib.obj and embedding_generator.obj in bindings\shared\build\
scripts\build_windows.bat
REM Alternatively: python scripts\build_native.py

cd bindings\python
pip install pybind11 numpy
python setup.py build_ext --inplace
python test_python_native.py
```

**Note (Windows)**: the Python extension links against precompiled assembly objects from
`bindings\shared\build\embedding_lib.obj` and `bindings\shared\build\embedding_generator.obj`.
If they are missing, build the shared library first using `scripts\build_windows.bat`
or `python scripts\build_native.py`.

**Linux/macOS**:

```bash
cd bindings/python
pip install pybind11 numpy
python setup.py build_ext --inplace
python test_python_native.py
```

**Usage**:

```python
from fastembed_native import FastEmbedNative

client = FastEmbedNative(768)
embedding = client.generate_embedding("machine learning")
print(embedding.shape)  # (768,)
```

#### C #

**Windows**:

```batch
cd bindings\csharp\src
dotnet build FastEmbed.csproj
cd ..\tests
dotnet test
```

**Linux/macOS**:

```bash
cd bindings/csharp/src
dotnet build FastEmbed.csproj
cd ../tests
dotnet test
```

**Usage**:

```csharp
using FastEmbed;

var client = new FastEmbedClient(dimension: 768);
float[] embedding = client.GenerateEmbedding("machine learning");
```

#### Java

**Windows**:

```batch
cd bindings\java\java
mvn compile
cd ..
java -Djava.library.path=target\lib -cp "target\classes;target\lib\*" com.fastembed.FastEmbedBenchmark
```

**Linux/macOS**:

```bash
cd bindings/java/java
mvn compile
cd ..
java -Djava.library.path=target/lib -cp target/classes:target/lib/* com.fastembed.FastEmbedBenchmark
```

**Usage**:

```java
import com.fastembed.FastEmbed;

FastEmbed client = new FastEmbed(768);
float[] embedding = client.generateEmbedding("machine learning");
```

---

## 💻 Usage Examples

### Vector Similarity

```python
# Python example
from fastembed_native import FastEmbedNative

client = FastEmbedNative(768)
emb1 = client.generate_embedding("artificial intelligence")
emb2 = client.generate_embedding("machine learning")

similarity = client.cosine_similarity(emb1, emb2)
print(f"Similarity: {similarity:.4f}")  # 0.9500+
```

### Batch Processing

```javascript
// Node.js example
const { FastEmbedNativeClient } = require('./lib/fastembed-native');

const client = new FastEmbedNativeClient(768);
const texts = ["AI", "ML", "NLP", "Computer Vision"];

const embeddings = texts.map(text => 
  client.generateEmbedding(text)
);

console.log(`Generated ${embeddings.length} embeddings`);
```

---

## 📚 Basic API Reference

### Core Functions

#### `generateEmbedding(text, dimension)`

Generate embedding from text.

- **Parameters**:
  - `text` (string) - Input text
  - `dimension` (int) - Embedding dimension (e.g., 768)
- **Returns**: Float array/vector

#### `cosineSimilarity(vec1, vec2)`

Calculate cosine similarity between two vectors.

- **Returns**: `float` - Similarity score (-1 to 1)

#### `dotProduct(vec1, vec2)`

Calculate dot product of two vectors.

#### `vectorNorm(vec)`

Calculate L2 norm of a vector.

#### `normalizeVector(vec)`

Normalize vector to unit length (L2 normalization).

#### `addVectors(vec1, vec2)`

Element-wise vector addition.

See [complete API reference](../api-reference/API.md) for detailed documentation.

---

## 📦 Using Built Artifacts in Your Projects

**Quick guide for integrating FastEmbed built artifacts into your projects.**

---

## 📦 Artifact Locations

After building FastEmbed, artifacts are located in:

```
bindings/shared/build/
├── libfastembed_native.so    # Linux shared library
├── libfastembed_native.dylib  # macOS shared library
├── fastembed_native.dll       # Windows DLL
└── *.o / *.obj                # Object files (for linking)
```

**Language bindings** are in respective directories:

- **Node.js**: `bindings/nodejs/build/Release/fastembed_native.node`
- **Python**: `bindings/python/fastembed_native.*.so` (or `.pyd` on Windows)
- **C#**: `bindings/csharp/src/bin/Release/net8.0/FastEmbed.dll`
- **Java**: `bindings/java/java/target/libfastembed_jni.so`

---

## 🚀 Quick Integration

### Node.js

**1. Copy artifacts to your project:**

```bash
# Copy shared library
cp bindings/shared/build/libfastembed_native.so ./libs/
# Copy Node.js binding
cp bindings/nodejs/build/Release/fastembed_native.node ./libs/
```

**2. Use in your code:**

```javascript
const path = require('path');
const { FastEmbedNativeClient } = require('./libs/fastembed-native');

// Set library path if needed
process.env.LD_LIBRARY_PATH = path.join(__dirname, 'libs');

const client = new FastEmbedNativeClient();
const embedding = client.generateEmbedding("Hello, world!", 256);
```

**3. Package.json (optional):**

```json
{
  "scripts": {
    "postinstall": "cp ../bindings/nodejs/build/Release/fastembed_native.node ./libs/"
  }
}
```

---

### Python

**1. Copy artifacts:**

```bash
# Copy shared library
cp bindings/shared/build/libfastembed_native.so ./libs/
# Copy Python extension
cp bindings/python/fastembed_native*.so ./libs/
```

**2. Use in your code:**

```python
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'libs'))

# Set library path
os.environ['LD_LIBRARY_PATH'] = os.path.join(os.path.dirname(__file__), 'libs')

from fastembed_native import FastEmbedNative

client = FastEmbedNative(dimension=256)
embedding = client.generate_embedding("Hello, world!")
```

**3. setup.py (for distribution):**

```python
from setuptools import setup, find_packages

setup(
    name="my-project",
    packages=find_packages(),
    package_data={
        '': ['libs/*.so', 'libs/*.dll', 'libs/*.dylib']
    },
    include_package_data=True,
)
```

---

### C #

**1. Copy artifacts:**

```bash
# Windows
cp bindings/shared/build/fastembed_native.dll ./libs/
cp bindings/csharp/src/bin/Release/net8.0/FastEmbed.dll ./libs/

# Linux/macOS
cp bindings/shared/build/libfastembed_native.so ./libs/
cp bindings/csharp/src/bin/Release/net8.0/FastEmbed.dll ./libs/
```

**2. Reference in .csproj:**

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
  
  <ItemGroup>
    <Reference Include="FastEmbed">
      <HintPath>libs/FastEmbed.dll</HintPath>
    </Reference>
  </ItemGroup>
  
  <ItemGroup>
    <None Include="libs/*.dll" CopyToOutputDirectory="PreserveNewest" />
    <None Include="libs/*.so" CopyToOutputDirectory="PreserveNewest" />
    <None Include="libs/*.dylib" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>
</Project>
```

**3. Use in your code:**

```csharp
using FastEmbed;

var client = new FastEmbedClient(dimension: 256);
float[] embedding = client.GenerateEmbedding("Hello, world!");
```

---

### Java

**1. Copy artifacts:**

```bash
# Copy shared library
cp bindings/shared/build/libfastembed_native.so ./libs/
# Copy JNI library
cp bindings/java/java/build/libfastembed_jni.so ./libs/
# Copy JAR
cp bindings/java/java/target/fastembed-*.jar ./libs/
```

**2. Use in your code:**

```java
import com.fastembed.FastEmbed;

public class MyApp {
    static {
        // Load native library
        System.loadLibrary("fastembed_jni");
        // Or load from path:
        // System.load("/path/to/libs/libfastembed_jni.so");
    }
    
    public static void main(String[] args) {
        FastEmbed client = new FastEmbed(256);
        float[] embedding = client.generateEmbedding("Hello, world!");
    }
}
```

**3. Maven pom.xml:**

```xml
<dependencies>
    <dependency>
        <groupId>com.fastembed</groupId>
        <artifactId>fastembed</artifactId>
        <version>1.0.1</version>
        <scope>system</scope>
        <systemPath>${project.basedir}/libs/fastembed-1.0.1.jar</systemPath>
    </dependency>
</dependencies>

<build>
    <resources>
        <resource>
            <directory>libs</directory>
            <includes>
                <include>*.so</include>
                <include>*.dll</include>
                <include>*.dylib</include>
            </includes>
        </resource>
    </resources>
</build>
```

---

## 🔧 Platform-Specific Notes

### Linux

- **Library path**: Set `LD_LIBRARY_PATH` or use `rpath`
- **File extension**: `.so`
- **Example**: `export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./libs`

### Windows

- **Library path**: DLLs must be in PATH or same directory as executable
- **File extension**: `.dll`
- **Example**: Add `libs` folder to system PATH or copy DLLs to executable directory

### macOS

- **Library path**: Set `DYLD_LIBRARY_PATH` or use `@rpath`
- **File extension**: `.dylib`
- **Example**: `export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:./libs`

---

## 📋 Common Patterns

### Pattern 1: Local Development

```bash
# Project structure
my-project/
├── src/
├── libs/              # Copy artifacts here
│   ├── *.so / *.dll
│   └── language-binding.*
└── your-code.*
```

### Pattern 2: Package Distribution

Include artifacts in your package:

- **Node.js**: Use `package.json` `files` field
- **Python**: Use `MANIFEST.in` or `package_data`
- **C#**: Use `.csproj` `CopyToOutputDirectory`
- **Java**: Include in JAR or use Maven resources

### Pattern 3: System-Wide Installation

Install to system library paths:

- **Linux**: `/usr/local/lib`
- **Windows**: `C:\Windows\System32` or add to PATH
- **macOS**: `/usr/local/lib`

---

## ⚠️ Troubleshooting

### "Library not found" errors

**Linux/macOS:**

```bash
# Check library path
echo $LD_LIBRARY_PATH  # Linux
echo $DYLD_LIBRARY_PATH  # macOS

# Add to path
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/libs
```

**Windows:**

- Ensure DLL is in same directory as executable
- Or add directory to system PATH
- Check with `where fastembed_native.dll`

### Architecture mismatch

Ensure artifacts match your system:

- **x86-64**: Most common
- **ARM64**: Apple Silicon (M1/M2)
- **x86**: Legacy (rare)

### Missing dependencies

FastEmbed requires:

- **ONNX Runtime** (if using ONNX features): Download from [ONNX Runtime releases](https://github.com/microsoft/onnxruntime/releases)
- **C++ runtime**: Usually included with OS

---

## 🔗 Next Steps

- **[API Reference](../api-reference/API.md)** - Complete API documentation
- **[Use Cases](USE_CASES.md)** - Real-world examples
- **[Build Guides](../building/)** - Build from source if needed

---

## 📝 Quick Checklist

- [ ] Artifacts built successfully
- [ ] Artifacts copied to project `libs/` directory
- [ ] Library path configured (LD_LIBRARY_PATH / PATH / DYLD_LIBRARY_PATH)
- [ ] Language binding imported/required correctly
- [ ] Test with simple example
- [ ] Package artifacts for distribution (if needed)

---

**Last Updated**: 2025-01-16  
**Version**: 1.0.1
