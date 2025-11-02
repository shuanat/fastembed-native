# Building FastEmbed C# Native Module

C# интерфейс для FastEmbed с использованием P/Invoke для прямых вызовов нативных функций.

## Требования

### Windows

1. **.NET SDK 6.0+**

   ```powershell
   winget install Microsoft.DotNet.SDK.6
   ```

2. **Visual Studio Build Tools 2022** (для сборки нативной библиотеки)
3. **NASM** (если еще не установлен)

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

## Структура файлов

```
FastEmbed/
├── csharp/
│   ├── FastEmbed.cs              # Высокоуровневый API
│   ├── FastEmbedNative.cs        # P/Invoke декларации
│   └── FastEmbed.csproj          # .NET проект
├── test_csharp_native.cs         # Тестовая программа
└── build/                        # Нативные библиотеки
    ├── fastembed.dll             # Windows
    ├── libfastembed.so           # Linux
    └── libfastembed.dylib        # macOS
```

## Сборка

### Шаг 1: Соберите нативную библиотеку

#### Windows

```cmd
REM Соберите DLL
build_windows.bat

REM Скопируйте в директорию build
mkdir build
copy fastembed.dll build\
```

#### Linux/macOS

```bash
# Соберите shared library
make shared

# Скопируйте в директорию build
mkdir -p build
cp libfastembed.so build/    # Linux
cp libfastembed.dylib build/ # macOS
```

### Шаг 2: Соберите C# проект

```bash
cd csharp
dotnet build
```

Или для Release build:

```bash
cd csharp
dotnet build -c Release
```

## Запуск тестов

### Вариант 1: Прямой запуск тестовой программы

```bash
# Скомпилируйте тест
dotnet build test_csharp_native.cs /r:csharp/bin/Debug/net6.0/FastEmbed.dll

# Запустите
dotnet test_csharp_native.dll
```

### Вариант 2: Через WSL (если на Windows)

```bash
wsl bash -c "cd /mnt/g/GitHub/KAG-workspace/FastEmbed && \
  cd csharp && dotnet build && cd .. && \
  dotnet run --project test_csharp_native.cs"
```

## Использование в своем проекте

### Вариант 1: Ссылка на DLL

```bash
dotnet add reference path/to/FastEmbed/csharp/bin/Release/net6.0/FastEmbed.dll
```

### Вариант 2: NuGet пакет (после публикации)

```bash
dotnet add package FastEmbed.Native
```

### Пример кода

```csharp
using FastEmbed;

class Program
{
    static void Main()
    {
        // Инициализация
        var fastembed = new FastEmbedClient(dimension: 768);
        
        // Генерация эмбеддинга
        string text = "machine learning example";
        float[] embedding = fastembed.GenerateEmbedding(text);
        
        Console.WriteLine($"Embedding shape: {embedding.Length}");
        Console.WriteLine($"First 5 values: [{string.Join(", ", embedding.Take(5))}]");
        
        // Векторные операции
        string text2 = "deep learning neural networks";
        float[] embedding2 = fastembed.GenerateEmbedding(text2);
        
        float similarity = fastembed.CosineSimilarity(embedding, embedding2);
        Console.WriteLine($"Cosine similarity: {similarity:F4}");
    }
}
```

## API Reference

### Класс FastEmbedClient

#### Конструктор

```csharp
public FastEmbedClient(int dimension = 768)
```

Создает новый клиент FastEmbed с указанной размерностью эмбеддингов.

#### Методы

**GenerateEmbedding**

```csharp
public float[] GenerateEmbedding(string text)
```

Генерирует hash-based эмбеддинг для текста.

- **Параметры**: `text` - входной текст
- **Возвращает**: `float[]` - вектор эмбеддинга
- **Исключения**: `ArgumentNullException`, `FastEmbedException`

**CosineSimilarity**

```csharp
public float CosineSimilarity(float[] vectorA, float[] vectorB)
```

Вычисляет косинусное сходство между двумя векторами.

- **Параметры**: два вектора одинаковой размерности
- **Возвращает**: `float` - косинусное сходство в диапазоне [-1, 1]
- **Исключения**: `ArgumentException`

**DotProduct**

```csharp
public float DotProduct(float[] vectorA, float[] vectorB)
```

Вычисляет скалярное произведение двух векторов.

**VectorNorm**

```csharp
public float VectorNorm(float[] vector)
```

Вычисляет L2 норму вектора.

**NormalizeVector**

```csharp
public float[] NormalizeVector(float[] vector)
```

Нормализует вектор (L2 нормализация). Возвращает новый массив.

**AddVectors**

```csharp
public float[] AddVectors(float[] vectorA, float[] vectorB)
```

Складывает два вектора поэлементно.

**TextSimilarity**

```csharp
public float TextSimilarity(string text1, string text2)
```

Вычисляет семантическую схожесть между двумя текстами (генерирует эмбеддинги и вычисляет косинусное сходство).

**GenerateEmbeddings**

```csharp
public float[][] GenerateEmbeddings(params string[] texts)
```

Генерирует эмбеддинги для множества текстов (batch processing).

## Производительность

**Measured Performance** (Linux/WSL, Nov 2025):

- **Embedding generation**: 0.014-0.051 ms
- **Throughput**: 19,000-71,000 embeddings/sec
- **Vector operations**: Sub-microsecond (up to **5.72M ops/sec** - fastest of all bindings!)

See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for complete benchmark data.

Благодаря:

- P/Invoke (direct native calls, minimal overhead)
- SIMD оптимизации в assembly
- `-O3 -march=native` компиляция

## Troubleshooting

### "DllNotFoundException: Unable to load DLL 'fastembed'"

**Причина**: Нативная библиотека не найдена в PATH или рядом с .exe/.dll.

**Решение**:

1. Убедитесь, что `fastembed.dll` (Windows) или `libfastembed.so` (Linux) скомпилирована:

   ```bash
   # Windows
   build_windows.bat
   
   # Linux
   make shared
   ```

2. Скопируйте библиотеку в директорию с исполняемым файлом:

   ```bash
   cp build/fastembed.dll csharp/bin/Debug/net6.0/
   ```

3. Или добавьте `build/` в PATH:

   ```bash
   # Windows
   set PATH=%PATH%;G:\GitHub\KAG-workspace\FastEmbed\build
   
   # Linux
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/FastEmbed/build
   ```

### "BadImageFormatException: An attempt was made to load a program with an incorrect format"

**Причина**: Несоответствие архитектуры (x86 vs x64).

**Решение**: Убедитесь, что .NET проект и нативная библиотека собраны для одной архитектуры (обычно x64).

```xml
<!-- В .csproj -->
<PropertyGroup>
  <PlatformTarget>x64</PlatformTarget>
</PropertyGroup>
```

### "FileNotFoundException: Could not load file or assembly 'FastEmbed'"

**Причина**: Не найдена сборка FastEmbed.dll (.NET).

**Решение**:

```bash
cd csharp
dotnet build
```

Затем добавьте ссылку на сборку в свой проект.

## Публикация NuGet пакета

### Шаг 1: Создайте .nuspec

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

### Шаг 2: Упакуйте и опубликуйте

```bash
cd csharp
dotnet pack -c Release
dotnet nuget push bin/Release/FastEmbed.Native.1.0.0.nupkg --source https://api.nuget.org/v3/index.json --api-key YOUR_API_KEY
```

## Интеграция с ML.NET

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

        // Создайте данные
        var data = new[]
        {
            new TextData { Text = "machine learning" },
            new TextData { Text = "deep learning" }
        };

        var dataView = mlContext.Data.LoadFromEnumerable(data);

        // Добавьте эмбеддинги
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

## Следующие шаги

1. **Публикация на NuGet**
2. **CI/CD для автоматической сборки**
3. **Поддержка .NET Framework 4.x**
4. **Async API** (Task-based)
5. **GPU acceleration** (CUDA)

---

**Создано**: 1 ноября 2025  
**Статус**: ✓ Готово к использованию  
**Производительность**: ★★★★★ (native P/Invoke speed)
