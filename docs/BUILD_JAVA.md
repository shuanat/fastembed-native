# Building FastEmbed Java Native Module

Java интерфейс для FastEmbed с использованием JNI (Java Native Interface) для максимальной производительности.

## Требования

### Все платформы

1. **JDK 11+**

   ```bash
   # Проверьте версию
   java -version
   javac -version
   ```

2. **Maven 3.6+**

   ```bash
   # Установка
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

### Windows

1. **Visual Studio Build Tools 2022**
2. **NASM**

## Структура файлов

```
FastEmbed/
├── java/
│   ├── src/main/java/com/fastembed/
│   │   └── FastEmbed.java           # Java класс
│   ├── native/
│   │   └── fastembed_jni.c          # JNI C wrapper
│   ├── pom.xml                       # Maven проект
│   └── target/                       # Собранные файлы
│       ├── classes/                  # .class файлы
│       ├── lib/                      # Нативные библиотеки
│       └── fastembed-native-1.0.0.jar
└── test_java_native.java             # Тестовая программа
```

## Сборка

### Вариант 1: Автоматическая сборка через Maven

```bash
cd java
mvn clean compile
```

Это автоматически:

1. Скомпилирует Java классы
2. Сгенерирует JNI заголовки (`javah`)
3. Скомпилирует C/assembly код
4. Создаст `libfastembed_jni.so` (или `.dll`/`.dylib`)
5. Упакует все в JAR

### Вариант 2: Ручная сборка (для кастомизации)

#### Шаг 1: Соберите ассемблерные файлы

```bash
# Linux/macOS
cd ..
nasm -f elf64 src/embedding_lib.asm -o obj/embedding_lib.o
nasm -f elf64 src/embedding_generator.asm -o obj/embedding_generator.o

# Windows
nasm -f win64 src/embedding_lib.asm -o obj/embedding_lib.obj
nasm -f win64 src/embedding_generator.asm -o obj/embedding_generator.obj
```

#### Шаг 2: Скомпилируйте Java классы

```bash
cd java
javac -d target/classes src/main/java/com/fastembed/FastEmbed.java
```

#### Шаг 3: Сгенерируйте JNI заголовки

```bash
javac -h target/native/include -d target/classes src/main/java/com/fastembed/FastEmbed.java
```

Или используйте `javah` (устаревший, но работает):

```bash
javah -o target/native/include/com_fastembed_FastEmbed.h -classpath target/classes com.fastembed.FastEmbed
```

#### Шаг 4: Скомпилируйте JNI C код

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

**Windows** (через Visual Studio Command Prompt):

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

#### Шаг 5: Создайте JAR

```bash
cd target/classes
jar cvf ../fastembed-native-1.0.0.jar com/fastembed/*.class
cd ../..
```

## Запуск тестов

### Вариант 1: Прямой запуск

```bash
# Скомпилируйте тест
javac -cp java/target/classes test_java_native.java -d .

# Запустите с указанием пути к нативной библиотеке
java -Djava.library.path=java/target/lib -cp .:java/target/classes com.fastembed.test.TestFastEmbedJava
```

### Вариант 2: Через Maven

Создайте `src/test/java/com/fastembed/test/TestFastEmbedJava.java` и запустите:

```bash
cd java
mvn test
```

### Вариант 3: Через WSL (если на Windows)

```bash
wsl bash -c "cd /mnt/g/GitHub/KAG-workspace/FastEmbed/java && \
  mvn clean compile && \
  java -Djava.library.path=target/lib -cp target/classes com.fastembed.test.TestFastEmbedJava"
```

## Использование в своем проекте

### Maven dependency

После публикации в Maven Central:

```xml
<dependency>
    <groupId>com.fastembed</groupId>
    <artifactId>fastembed-native</artifactId>
    <version>1.0.0</version>
</dependency>
```

### Локальная установка

```bash
cd java
mvn install
```

Затем в своем `pom.xml`:

```xml
<dependency>
    <groupId>com.fastembed</groupId>
    <artifactId>fastembed-native</artifactId>
    <version>1.0.0</version>
</dependency>
```

### Пример кода

```java
import com.fastembed.FastEmbed;

public class Example {
    public static void main(String[] args) {
        // Проверьте доступность
        if (!FastEmbed.isAvailable()) {
            System.err.println("Native library not available");
            System.exit(1);
        }

        // Инициализация
        FastEmbed fastembed = new FastEmbed(768);
        
        // Генерация эмбеддинга
        String text = "machine learning example";
        float[] embedding = fastembed.generateEmbedding(text);
        
        System.out.println("Embedding shape: " + embedding.length);
        System.out.println("First 5 values: " + Arrays.toString(
            Arrays.copyOfRange(embedding, 0, 5)
        ));
        
        // Векторные операции
        String text2 = "deep learning neural networks";
        float[] embedding2 = fastembed.generateEmbedding(text2);
        
        float similarity = fastembed.cosineSimilarity(embedding, embedding2);
        System.out.printf("Cosine similarity: %.4f\n", similarity);
    }
}
```

## API Reference

### Класс FastEmbed

#### Конструкторы

```java
public FastEmbed()                  // dimension=768 (default)
public FastEmbed(int dimension)     // custom dimension
```

#### Статические методы

```java
public static boolean isAvailable()
```

Проверяет, загружена ли нативная библиотека.

#### Методы экземпляра

**generateEmbedding**

```java
public float[] generateEmbedding(String text)
```

Генерирует hash-based эмбеддинг для текста.

- **Параметры**: `text` - входной текст
- **Возвращает**: `float[]` - вектор эмбеддинга
- **Исключения**: `IllegalArgumentException`, `FastEmbedException`

**cosineSimilarity**

```java
public float cosineSimilarity(float[] vectorA, float[] vectorB)
```

Вычисляет косинусное сходство между двумя векторами.

- **Параметры**: два вектора одинаковой размерности
- **Возвращает**: косинусное сходство в диапазоне [-1, 1]
- **Исключения**: `IllegalArgumentException`

**dotProduct**

```java
public float dotProduct(float[] vectorA, float[] vectorB)
```

Вычисляет скалярное произведение двух векторов.

**vectorNorm**

```java
public float vectorNorm(float[] vector)
```

Вычисляет L2 норму вектора.

**normalizeVector**

```java
public float[] normalizeVector(float[] vector)
```

Нормализует вектор (L2 нормализация). Возвращает новый массив.

**addVectors**

```java
public float[] addVectors(float[] vectorA, float[] vectorB)
```

Складывает два вектора поэлементно.

**textSimilarity**

```java
public float textSimilarity(String text1, String text2)
```

Вычисляет семантическую схожесть между двумя текстами.

**generateEmbeddings**

```java
public float[][] generateEmbeddings(String... texts)
```

Генерирует эмбеддинги для множества текстов (batch processing).

## Производительность

**Measured Performance** (Linux x64, WSL, Nov 2025):

- **Embedding generation**: 0.013-0.048 ms
- **Throughput**: 20,000-78,000 embeddings/sec
- **Vector operations**: Sub-microsecond (up to 1.97M ops/sec)

See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for complete benchmark data.

Благодаря:

- JNI (direct native calls)
- SIMD оптимизации в assembly
- `-O3 -march=native` компиляция

## Troubleshooting

### "UnsatisfiedLinkError: no fastembed_jni in java.library.path"

**Причина**: Нативная библиотека не найдена.

**Решение 1**: Укажите путь к библиотеке:

```bash
java -Djava.library.path=/path/to/FastEmbed/java/target/lib -cp ... MainClass
```

**Решение 2**: Скопируйте библиотеку в стандартную директорию:

```bash
# Linux
sudo cp java/target/lib/libfastembed_jni.so /usr/lib/

# macOS
sudo cp java/target/lib/libfastembed_jni.dylib /usr/local/lib/
```

**Решение 3**: Добавьте в переменную окружения:

```bash
# Linux
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/FastEmbed/java/target/lib

# macOS
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/path/to/FastEmbed/java/target/lib
```

### "ClassNotFoundException: com.fastembed.FastEmbed"

**Причина**: Java классы не скомпилированы или не в classpath.

**Решение**:

```bash
cd java
mvn compile
java -cp target/classes:target/fastembed-native-1.0.0.jar com.fastembed.test.TestFastEmbedJava
```

### Maven build fails: "javah: command not found"

**Причина**: `javah` устарел в JDK 10+ и удален в JDK 11+.

**Решение**: Maven плагин автоматически использует `javac -h` для JDK 9+. Убедитесь, что `JAVA_HOME` указывает на JDK 11+:

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
mvn clean compile
```

### "UnsatisfiedLinkError: ... undefined symbol: fastembed_generate"

**Причина**: Линковка JNI библиотеки не включила FastEmbed функции.

**Решение**: Убедитесь, что при линковке указаны объектные файлы assembly и C код:

```bash
gcc -shared ... \
  native/fastembed_jni.c \
  ../src/embedding_lib_c.c \
  ../obj/embedding_lib.o \
  ../obj/embedding_generator.o \
  -o libfastembed_jni.so
```

## Публикация в Maven Central

### Шаг 1: Настройте `~/.m2/settings.xml`

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

### Шаг 2: Добавьте в `pom.xml`

```xml
<distributionManagement>
  <repository>
    <id>ossrh</id>
    <url>https://oss.sonatype.org/service/local/staging/deploy/maven2/</url>
  </repository>
</distributionManagement>
```

### Шаг 3: Опубликуйте

```bash
mvn clean deploy -P release
```

## Интеграция с Apache Spark

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
        
        // Регистрируйте UDF
        spark.udf().register("fastembed", (UDF1<String, float[]>) text -> 
            fastembed.generateEmbedding(text),
            DataTypes.createArrayType(DataTypes.FloatType)
        );
        
        // Используйте в SQL
        Dataset<Row> df = spark.read().json("texts.json");
        df.createOrReplaceTempView("texts");
        
        Dataset<Row> embeddings = spark.sql(
            "SELECT text, fastembed(text) AS embedding FROM texts"
        );
        
        embeddings.show();
    }
}
```

## Интеграция с Spring Boot

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

## Gradle build

Если предпочитаете Gradle вместо Maven, создайте `build.gradle`:

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

## Следующие шаги

1. **Публикация на Maven Central**
2. **CI/CD для автоматической сборки**
3. **Поддержка Android** (ARM64)
4. **Async API** (CompletableFuture)
5. **GPU acceleration** (CUDA/JCuda)

---

**Создано**: 1 ноября 2025  
**Статус**: ✓ Готово к использованию  
**Производительность**: ★★★★★ (native JNI speed)
