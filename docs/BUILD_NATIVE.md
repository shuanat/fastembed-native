# Building FastEmbed Native N-API Module

FastEmbed теперь использует нативный N-API модуль вместо FFI для максимальной производительности и надёжности на Windows.

## Требования

### Windows

1. **Visual Studio Build Tools 2022** (или полная Visual Studio)
   - Скачайте: <https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022>
   - Установите рабочую нагрузку: "Desktop development with C++"
   - Включает: MSVC, Windows SDK, MSBuild

2. **NASM** (Netwide Assembler)
   - Установите NASM и добавьте в PATH
   - Или используйте скрипт `build_windows.bat` для автоматической сборки ассемблерных файлов

3. **Python 3.x**
   - Для node-gyp
   - Скачайте: <https://www.python.org/downloads/>

4. **Node.js** (v16+)

### Linux/macOS

1. **GCC/Clang** (обычно уже установлен)
2. **NASM** (для ассемблерных файлов)

   ```bash
   # Ubuntu/Debian
   sudo apt install nasm
   
   # macOS
   brew install nasm
   ```

3. **Python 3.x**
4. **Node.js** (v16+)

## Сборка

### Автоматическая сборка (рекомендуется)

```bash
npm install
```

Это автоматически:

1. Установит зависимости (`node-gyp`, `node-addon-api`)
2. Соберёт нативный модуль
3. При ошибке использует CLI fallback

### Ручная сборка

#### Windows

1. **Соберите ассемблерные объектные файлы:**

   ```cmd
   build_windows.bat
   ```

   Это создаст `build/embedding_lib.obj` и `build/embedding_generator.obj`

2. **Соберите нативный модуль:**

   ```cmd
   npm run build
   ```

#### Linux/macOS

```bash
# Соберите shared library (опционально для CLI)
make shared

# Соберите нативный модуль
npm run build
```

### Debug сборка

```bash
npm run build:debug
```

## Проверка сборки

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

Или через TypeScript:

```typescript
import { FastEmbedNativeClient } from './lib/fastembed-native';

const client = new FastEmbedNativeClient(768);

if (client.isAvailable()) {
  const embedding = await client.generateEmbedding('test text');
  console.log('Embedding:', embedding);
}
```

## Архитектура

### N-API vs FFI

| Аспект                 | N-API (Нативный)        | FFI                   |
| ---------------------- | ----------------------- | --------------------- |
| **Производительность** | Максимальная (нативная) | Средняя (overhead)    |
| **Сборка**             | Требует компиляции      | Не требует компиляции |
| **Совместимость**      | ABI-стабильная          | Проблемы на Windows   |
| **Поддержка**          | Официальная Node.js     | Сторонняя библиотека  |
| **Типы**               | Прямое преобразование   | Требует ref-napi      |

### Структура

```
FastEmbed/
├── addon/
│   └── fastembed_napi.cc       # N-API C++ обёртка
├── lib/
│   └── fastembed-native.ts     # TypeScript интерфейс
├── src/
│   ├── embedding_lib.asm       # Оптимизированные SIMD функции
│   ├── embedding_generator.asm # Hash-based генератор
│   └── embedding_lib_c.c       # C функции-обёртки
├── binding.gyp                 # node-gyp конфигурация
└── build/
    └── Release/
        └── fastembed_native.node  # Скомпилированный модуль
```

## API

### Экспортируемые функции

```typescript
// Генерация эмбеддингов
generateEmbedding(text: string, dimension?: number): Float32Array

// Векторные операции
cosineSimilarity(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): number
dotProduct(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): number
vectorNorm(vector: Float32Array | number[]): number
normalizeVector(vector: Float32Array | number[]): Float32Array
addVectors(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): Float32Array
```

### FastEmbedNativeClient

Класс-обёртка для удобного использования:

```typescript
const client = new FastEmbedNativeClient(768);

// Проверка доступности
if (client.isAvailable()) {
  // Генерация
  const embedding = await client.generateEmbedding('text');
  
  // Векторные операции
  const similarity = client.cosineSimilarity(vec1, vec2);
  const dot = client.dotProduct(vec1, vec2);
  const norm = client.vectorNorm(vec1);
}
```

## Troubleshooting

### Windows: "MSBuild failed"

Убедитесь, что установлены Visual Studio Build Tools:

```cmd
npm config set msvs_version 2022
npm run build
```

### Windows: "NASM not found"

Запустите `build_windows.bat` сначала, или добавьте NASM в PATH.

### Linux/macOS: "nasm: command not found"

```bash
sudo apt install nasm  # Ubuntu/Debian
brew install nasm      # macOS
```

### "Native module not found"

Модуль не собран или сборка не удалась. Используется CLI fallback автоматически.

## Производительность

**Measured Performance** (Nov 2025):

- **N-API**: 0.014-0.049 ms per embedding (native speed, measured)
- **FFI**: Legacy/not recommended (use N-API instead)
- **CLI**: ~50ms per embedding (process startup overhead)

N-API provides **1000x speedup** compared to CLI for multiple calls.

See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for complete benchmark data.

## Fallback Chain

FastEmbed автоматически использует лучший доступный метод:

1. **Native N-API** (fastest) ← по умолчанию
2. **CLI mode** (fallback) ← если N-API не доступен

FFI больше не используется из-за проблем на Windows.
