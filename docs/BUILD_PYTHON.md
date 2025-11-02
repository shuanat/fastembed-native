# Building FastEmbed Python Native Module

Python extension module для FastEmbed с использованием pybind11 для максимальной производительности.

## Требования

### Все платформы

1. **Python 3.7+**
2. **NumPy** (>=1.20.0)
3. **pybind11** (>=2.10.0)
4. **setuptools**

### Windows

1. **Visual Studio Build Tools 2022**
   - Desktop development with C++
2. **NASM** (для ассемблерных файлов)
3. Предварительно собранные объектные файлы (`obj/embedding_lib.obj`, `obj/embedding_generator.obj`)

### Linux/macOS

1. **GCC/Clang** (C++17 поддержка)
2. **NASM**

   ```bash
   # Ubuntu/Debian
   sudo apt install nasm
   
   # macOS
   brew install nasm
   ```

## Установка зависимостей

```bash
pip install numpy pybind11
```

## Сборка

### Вариант 1: Автоматическая сборка (рекомендуется)

```bash
python setup.py build_ext --inplace
```

Это автоматически:

1. Определит платформу
2. Скомпилирует ассемблерные файлы (Linux/macOS)
3. Соберёт Python extension module
4. Установит в текущую директорию

### Вариант 2: Установка как пакет

```bash
pip install -e .
```

Это установит FastEmbed как editable package.

### Вариант 3: Build wheel для распространения

```bash
python setup.py bdist_wheel
```

Wheel будет в `dist/fastembed_native-1.0.0-*.whl`

## Сборка на Windows

### Шаг 1: Подготовка ассемблерных файлов

```cmd
REM Соберите ассемблерные объектные файлы
build_windows.bat

REM Переместите их в obj/
mkdir obj
copy build\embedding_lib.obj obj\
copy build\embedding_generator.obj obj\
```

### Шаг 2: Сборка Python модуля

```cmd
python setup.py build_ext --inplace
```

## Сборка на Linux/macOS

```bash
# Сборка выполняется автоматически
python setup.py build_ext --inplace
```

## Проверка сборки

```python
from python import FastEmbed, is_available

if is_available():
    print("✓ Native module available")
    
    fastembed = FastEmbed(768)
    embedding = fastembed.generate_embedding("test text")
    print(f"Embedding shape: {embedding.shape}")
else:
    print("✗ Native module not available")
```

Или запустите тестовый скрипт:

```bash
python test_python_native.py
```

## Использование

### Базовое использование

```python
from python import FastEmbed
import numpy as np

# Инициализация
fastembed = FastEmbed(dimension=768)

# Генерация эмбеддинга
text = "machine learning example"
embedding = fastembed.generate_embedding(text)

print(f"Embedding shape: {embedding.shape}")
print(f"Embedding type: {type(embedding)}")  # numpy.ndarray
```

### Векторные операции

```python
# Два эмбеддинга
emb1 = fastembed.generate_embedding("first text")
emb2 = fastembed.generate_embedding("second text")

# Косинусное сходство
similarity = fastembed.cosine_similarity(emb1, emb2)
print(f"Cosine similarity: {similarity:.4f}")

# Скалярное произведение
dot = fastembed.dot_product(emb1, emb2)
print(f"Dot product: {dot:.4f}")

# Норма вектора
norm = fastembed.vector_norm(emb1)
print(f"Vector norm: {norm:.4f}")

# Нормализация
normalized = fastembed.normalize_vector(emb1)

# Сложение векторов
sum_vec = fastembed.add_vectors(emb1, emb2)
```

### Module-level функции

```python
from python import generate_embedding, is_available

if is_available():
    # Прямой вызов без создания класса
    embedding = generate_embedding("text", dimension=768)
```

## API Reference

### Класс FastEmbed

```python
class FastEmbed:
    def __init__(self, dimension: int = 768)
    
    def generate_embedding(self, text: str) -> np.ndarray
    
    def cosine_similarity(
        self, 
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> float
    
    def dot_product(
        self,
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> float
    
    def vector_norm(self, vector: Union[np.ndarray, List[float]]) -> float
    
    def normalize_vector(
        self,
        vector: Union[np.ndarray, List[float]]
    ) -> np.ndarray
    
    def add_vectors(
        self,
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> np.ndarray
```

### Module-level функции

```python
def is_available() -> bool
    """Check if native module is available"""

def generate_embedding(text: str, dimension: int = 768) -> np.ndarray
    """Generate embedding (module-level)"""
```

## Структура файлов

```
FastEmbed/
├── python/
│   ├── __init__.py              # Python интерфейс
│   └── fastembed_native.cpp     # pybind11 C++ обёртка
├── setup.py                      # Сборочный скрипт
├── test_python_native.py         # Тестовый скрипт
└── obj/                          # Ассемблерные объектные файлы (Windows)
    ├── embedding_lib.obj
    └── embedding_generator.obj
```

## Производительность

**Measured Performance** (Nov 2025):

- **Embedding generation**: 0.012-0.047 ms (768 dimensions)
- **Throughput**: 20,000-84,000 embeddings/sec
- **Vector operations**: Sub-microsecond (up to 1.48M ops/sec)
- **Native C++ speed** thanks to SIMD optimizations

See [BENCHMARK_RESULTS.md](../BENCHMARK_RESULTS.md) for complete benchmark data.

## Troubleshooting

### "ModuleNotFoundError: No module named 'fastembed_native'"

Модуль не собран. Запустите:

```bash
python setup.py build_ext --inplace
```

### Windows: "Assembly object files not found"

Сначала соберите ассемблерные файлы:

```cmd
build_windows.bat
mkdir obj
copy build\*.obj obj\
```

### Linux/macOS: "nasm: command not found"

Установите NASM:

```bash
sudo apt install nasm      # Ubuntu/Debian
brew install nasm          # macOS
```

### "ImportError: numpy.core.multiarray failed to import"

Обновите NumPy:

```bash
pip install --upgrade numpy
```

## Сравнение с другими подходами

| Метод        | Скорость    | Требования     | Простота      |
| ------------ | ----------- | -------------- | ------------- |
| **pybind11** | **Fastest** | Компиляция C++ | Средняя       |
| ctypes/cffi  | Fast        | DLL/SO         | Простая       |
| Python CLI   | Slow        | Subprocess     | Очень простая |

pybind11 обеспечивает оптимальный баланс производительности и удобства использования.

## Интеграция с ML фреймворками

### PyTorch

```python
import torch
from python import FastEmbed

fastembed = FastEmbed(768)
embedding = fastembed.generate_embedding("text")

# Конвертация в PyTorch tensor
tensor = torch.from_numpy(embedding)
```

### TensorFlow

```python
import tensorflow as tf
from python import FastEmbed

fastembed = FastEmbed(768)
embedding = fastembed.generate_embedding("text")

# Конвертация в TensorFlow tensor
tensor = tf.convert_to_tensor(embedding)
```

### Scikit-learn

```python
from sklearn.metrics.pairwise import cosine_similarity
from python import FastEmbed

fastembed = FastEmbed(768)
embeddings = [
    fastembed.generate_embedding(text)
    for text in texts
]

# Используйте как обычные NumPy arrays
similarity_matrix = cosine_similarity(embeddings)
```

## Следующие шаги

1. Публикация wheel пакетов на PyPI
2. Поддержка GPU acceleration (CUDA)
3. Batch processing для множественных текстов
4. ONNX model support
