# Building FastEmbed Java Native Module

**Navigation**: [Documentation Index](README.md) → Build Guides → Java

Java interface for FastEmbed using JNI (Java Native Interface) for maximum performance.

## Requirements

> **Note**: Common requirements (NASM, compiler) are described in [BUILD_WINDOWS.md](BUILD_WINDOWS.md) (Windows) or [BUILD_CMAKE.md](BUILD_CMAKE.md) (Linux/macOS).

### All Platforms

1. **JDK 11+**

   ```bash
   # Check version
   java -version
   javac -version
   ```

2. **Maven 3.6+**

   ```bash
   # Installation
   # Ubuntu/Debian
   sudo apt install maven
   
   # macOS
   brew install maven
   
   # Windows
   winget install Apache.Maven
   ```

### Linux/macOS

1. **GCC/Clang**
2. **NASM**

   ```bash
   # Ubuntu/Debian
   sudo apt install nasm
   
   # macOS
   brew install nasm
   ```

   See details: [BUILD_CMAKE.md](BUILD_CMAKE.md#prerequisites)

### Windows

1. **Visual Studio Build Tools 2022**
   - See details: [BUILD_WINDOWS.md](BUILD_WINDOWS.md#visual-studio-build-tools)
2. **NASM**
   - See details: [BUILD_WINDOWS.md](BUILD_WINDOWS.md#nasm-installation)

## File Structure

```
FastEmbed/
├── java/
│   ├── src/main/java/com/fastembed/
│   │   └── FastEmbed.java           # Java class
│   ├── native/
│   │   └── fastembed_jni.c          # JNI C wrapper
│   ├── pom.xml                       # Maven project
│   └── target/                       # Built files
│       ├── classes/                  # .class files
│       ├── lib/                      # Native libraries
│       └── fastembed-native-1.0.0.jar
└── test_java_native.java             # Test program
```

## Building

### Option 1: Automatic Build via Maven

```bash
cd java
mvn clean compile
```

This automatically:

1. Compiles Java classes
2. Generates JNI headers (`javah`)
3. Compiles C/assembly code
4. Creates `libfastembed_jni.so` (or `.dll`/`.dylib`)
5. Packages everything into JAR

### Option 2: Manual Build (for customization)

#### Step 1: Build Assembly Files

```bash
# Linux/macOS
cd ..
nasm -f elf64 src/embedding_lib.asm -o obj/embedding_lib.o
nasm -f elf64 src/embedding_generator.asm -o obj/embedding_generator.o

# Windows
nasm -f win64 src/embedding_lib.asm -o obj/embedding_lib.obj
nasm -f win64 src/embedding_generator.asm -o obj/embedding_generator.obj
```

#### Step 2: Compile Java Classes

```bash
cd java
javac -d target/classes src/main/java/com/fastembed/FastEmbed.java
```

#### Step 3: Generate JNI Headers

```bash
javac -h target/native/include -d target/classes src/main/java/com/fastembed/FastEmbed.java
```

Or use `javah` (deprecated, but works):

```bash
javah -o target/native/include/com_fastembed_FastEmbed.h -classpath target/classes com.fastembed.FastEmbed
```

#### Step 4: Compile JNI C Code

**Linux**:

```bash
gcc -shared -fPIC -O3 -march=native \
  -I${JAVA_HOME}/include \
  -I${JAVA_HOME}/include/linux \
  -I../include \
  native/fastembed_jni.c \
  ../src/embedding_lib_c.c \
  ../obj/embedding_lib.o \
  ../obj/embedding_generator.o \
  -lm \
  -o target/lib/libfastembed_jni.so
```

**macOS**:

```bash
gcc -shared -fPIC -O3 -march=native \
  -I${JAVA_HOME}/include \
  -I${JAVA_HOME}/include/darwin \
  -I../include \
  native/fastembed_jni.c \
  ../src/embedding_lib_c.c \
  ../obj/embedding_lib.o \
  ../obj/embedding_generator.o \
  -lm \
  -o target/lib/libfastembed_jni.dylib
```

**Windows** (via Visual Studio Command Prompt):

```cmd
cl /LD /O2 /MD ^
  /I"%JAVA_HOME%\include" ^
  /I"%JAVA_HOME%\include\win32" ^
  /I"..\include" ^
  native\fastembed_jni.c ^
  ..\src\embedding_lib_c.c ^
  ..\obj\embedding_lib.obj ^
  ..\obj\embedding_generator.obj ^
  /link /OUT:target\lib\fastembed_jni.dll
```

#### Step 5: Create JAR

```bash
cd target/classes
jar cvf ../fastembed-native-1.0.0.jar com/fastembed/*.class
cd ../..
```

## Running Tests

### Option 1: Direct Execution

```bash
# Compile test
javac -cp java/target/classes test_java_native.java -d .

# Run with native library path specified
java -Djava.library.path=java/target/lib -cp .:java/target/classes com.fastembed.test.TestFastEmbedJava
```

### Option 2: Via Maven

Create `src/test/java/com/fastembed/test/TestFastEmbedJava.java` and run:

```bash
cd java
mvn test
```

### Option 3: Via WSL (if on Windows)

```bash
wsl bash -c "cd /mnt/g/GitHub/KAG-workspace/FastEmbed/java && \
  mvn clean compile && \
  java -Djava.library.path=target/lib -cp target/classes com.fastembed.test.TestFastEmbedJava"
```

## Using in Your Project

### Maven Dependency

After publishing to Maven Central:

```xml
<dependency>
    <groupId>com.fastembed</groupId>
    <artifactId>fastembed-native</artifactId>
    <version>1.0.0</version>
</dependency>
```

### Local Installation

```bash
cd java
mvn install
```

Then in your `pom.xml`:

```xml
<dependency>
    <groupId>com.fastembed</groupId>
    <artifactId>fastembed-native</artifactId>
    <version>1.0.0</version>
</dependency>
```

### Code Example

```java
import com.fastembed.FastEmbed;

public class Example {
    public static void main(String[] args) {
        // Check availability
        if (!FastEmbed.isAvailable()) {
            System.err.println("Native library not available");
            System.exit(1);
        }

        // Initialization
        FastEmbed fastembed = new FastEmbed(768);
        
        // Generate embedding
        String text = "machine learning example";
        float[] embedding = fastembed.generateEmbedding(text);
        
        System.out.println("Embedding shape: " + embedding.length);
        System.out.println("First 5 values: " + Arrays.toString(
            Arrays.copyOfRange(embedding, 0, 5)
        ));
        
        // Vector operations
        String text2 = "deep learning neural networks";
        float[] embedding2 = fastembed.generateEmbedding(text2);
        
        float similarity = fastembed.cosineSimilarity(embedding, embedding2);
        System.out.printf("Cosine similarity: %.4f\n", similarity);
    }
}
```

## API Reference

### FastEmbed Class

#### Constructors

```java
public FastEmbed()                  // dimension=768 (default)
public FastEmbed(int dimension)     // custom dimension
```

#### Static Methods

```java
public static boolean isAvailable()
```

Checks if the native library is loaded.

#### Instance Methods

**generateEmbedding**

```java
public float[] generateEmbedding(String text)
```

Generates a hash-based embedding for text.

- **Parameters**: `text` - input text
- **Returns**: `float[]` - embedding vector
- **Exceptions**: `IllegalArgumentException`, `FastEmbedException`

**cosineSimilarity**

```java
public float cosineSimilarity(float[] vectorA, float[] vectorB)
```

Calculates cosine similarity between two vectors.

- **Parameters**: two vectors of the same dimension
- **Returns**: cosine similarity in range [-1, 1]
- **Exceptions**: `IllegalArgumentException`

**dotProduct**

```java
public float dotProduct(float[] vectorA, float[] vectorB)
```

Calculates dot product of two vectors.

**vectorNorm**

```java
public float vectorNorm(float[] vector)
```

Calculates L2 norm of a vector.

**normalizeVector**

```java
public float[] normalizeVector(float[] vector)
```

Normalizes a vector (L2 normalization). Returns a new array.

**addVectors**

```java
public float[] addVectors(float[] vectorA, float[] vectorB)
```

Adds two vectors element-wise.

**textSimilarity**

```java
public float textSimilarity(String text1, String text2)
```

Calculates semantic similarity between two texts.

**generateEmbeddings**

```java
public float[][] generateEmbeddings(String... texts)
```

Generates embeddings for multiple texts (batch processing).

## Performance

**Measured Performance** (Linux x64, WSL, Nov 2025):

- **Embedding generation**: 0.013-0.048 ms
- **Throughput**: 20,000-78,000 embeddings/sec
- **Vector operations**: Sub-microsecond (up to 1.97M ops/sec)

See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for complete benchmark data.

Thanks to:

- JNI (direct native calls)
- SIMD optimizations in assembly
- `-O3 -march=native` compilation

## Troubleshooting

### "UnsatisfiedLinkError: no fastembed_jni in java.library.path"

**Cause**: Native library not found.

**Solution 1**: Specify library path:

```bash
java -Djava.library.path=/path/to/FastEmbed/java/target/lib -cp ... MainClass
```

**Solution 2**: Copy library to standard directory:

```bash
# Linux
sudo cp java/target/lib/libfastembed_jni.so /usr/lib/

# macOS
sudo cp java/target/lib/libfastembed_jni.dylib /usr/local/lib/
```

**Solution 3**: Add to environment variable:

```bash
# Linux
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/FastEmbed/java/target/lib

# macOS
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/path/to/FastEmbed/java/target/lib
```

### "ClassNotFoundException: com.fastembed.FastEmbed"

**Cause**: Java classes not compiled or not in classpath.

**Solution**:

```bash
cd java
mvn compile
java -cp target/classes:target/fastembed-native-1.0.0.jar com.fastembed.test.TestFastEmbedJava
```

### Maven build fails: "javah: command not found"

**Cause**: `javah` is deprecated in JDK 10+ and removed in JDK 11+.

**Solution**: Maven plugin automatically uses `javac -h` for JDK 9+. Ensure `JAVA_HOME` points to JDK 11+:

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
mvn clean compile
```

### "UnsatisfiedLinkError: ... undefined symbol: fastembed_generate"

**Cause**: JNI library linking did not include FastEmbed functions.

**Solution**: Ensure assembly object files and C code are specified during linking:

```bash
gcc -shared ... \
  native/fastembed_jni.c \
  ../src/embedding_lib_c.c \
  ../obj/embedding_lib.o \
  ../obj/embedding_generator.o \
  -o libfastembed_jni.so
```

## Publishing to Maven Central

### Step 1: Configure `~/.m2/settings.xml`

```xml
<settings>
  <servers>
    <server>
      <id>ossrh</id>
      <username>your-sonatype-username</username>
      <password>your-sonatype-password</password>
    </server>
  </servers>
</settings>
```

### Step 2: Add to `pom.xml`

```xml
<distributionManagement>
  <repository>
    <id>ossrh</id>
    <url>https://oss.sonatype.org/service/local/staging/deploy/maven2/</url>
  </repository>
</distributionManagement>
```

### Step 3: Publish

```bash
mvn clean deploy -P release
```

## Integration with Apache Spark

```java
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.api.java.UDF1;
import org.apache.spark.sql.types.DataTypes;
import com.fastembed.FastEmbed;

public class SparkExample {
    public static void main(String[] args) {
        SparkSession spark = SparkSession.builder()
            .appName("FastEmbed Example")
            .getOrCreate();
        
        FastEmbed fastembed = new FastEmbed(768);
        
        // Register UDF
        spark.udf().register("fastembed", (UDF1<String, float[]>) text -> 
            fastembed.generateEmbedding(text),
            DataTypes.createArrayType(DataTypes.FloatType)
        );
        
        // Use in SQL
        Dataset<Row> df = spark.read().json("texts.json");
        df.createOrReplaceTempView("texts");
        
        Dataset<Row> embeddings = spark.sql(
            "SELECT text, fastembed(text) AS embedding FROM texts"
        );
        
        embeddings.show();
    }
}
```

## Integration with Spring Boot

```java
import org.springframework.stereotype.Service;
import com.fastembed.FastEmbed;

@Service
public class EmbeddingService {
    private final FastEmbed fastembed;
    
    public EmbeddingService() {
        this.fastembed = new FastEmbed(768);
    }
    
    public float[] embed(String text) {
        return fastembed.generateEmbedding(text);
    }
    
    public float similarity(String text1, String text2) {
        return fastembed.textSimilarity(text1, text2);
    }
}
```

## Gradle Build

If you prefer Gradle instead of Maven, create `build.gradle`:

```groovy
plugins {
    id 'java'
}

group = 'com.fastembed'
version = '1.0.0'

sourceCompatibility = 11
targetCompatibility = 11

repositories {
    mavenCentral()
}

dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter:5.9.3'
}

task compileJNI(type: Exec) {
    commandLine 'gcc', '-shared', '-fPIC', '-O3',
        "-I${System.getenv('JAVA_HOME')}/include",
        "-I${System.getenv('JAVA_HOME')}/include/linux",
        '-Iinclude',
        'native/fastembed_jni.c',
        'src/embedding_lib_c.c',
        '-o', 'build/libs/libfastembed_jni.so'
}

compileJava.dependsOn compileJNI
```

## Next Steps

1. **Publish to Maven Central**
2. **CI/CD for automated builds**
3. **Android support** (ARM64)
4. **Async API** (CompletableFuture)
5. **GPU acceleration** (CUDA/JCuda)

---

## See Also

### Related Documentation

- **[Architecture Documentation](ARCHITECTURE.md)** - System architecture and build system details
- **[API Reference](API.md)** - Complete API documentation for Java
- **[Use Cases](USE_CASES.md)** - Real-world scenarios and applications

### Other Build Guides

- **[Build CMake](BUILD_CMAKE.md)** - Cross-platform CMake build (recommended)
- **[Build Windows](BUILD_WINDOWS.md)** - Windows-specific build instructions
- **[Build Native](BUILD_NATIVE.md)** - Node.js N-API module build
- **[Build Python](BUILD_PYTHON.md)** - Python pybind11 module build
- **[Build C#](BUILD_CSHARP.md)** - C# P/Invoke module build

### Additional Resources

- **[Documentation Index](README.md)** - Complete documentation overview
- **[Main README](../README.md)** - Project overview and quick start

---

**Created**: November 1, 2025  
**Status**: ✓ Ready for use  
**Performance**: ★★★★★ (native JNI speed)
