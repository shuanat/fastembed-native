# Сборка FastEmbed на Windows

Этот гайд описывает актуальный, поддерживаемый процесс сборки и тестирования FastEmbed на Windows для всех биндингов: Node.js (N-API), Python (pybind11), C# (P/Invoke), Java (JNI).

## Предварительные требования

- Visual Studio 2022 Build Tools (Workload: "Desktop development with C++")
- NASM ≥ 2.14 (добавьте `nasm.exe` в PATH)
- Node.js 18+
- Python 3.8+ (рекомендуется) + `pip`
- .NET SDK 8.0+
- JDK 17+ и Maven

## Быстрый старт

### 1) Сборка общей нативной библиотеки

Используйте универсальный скрипт (рекомендуется):

```bat
python scripts\build_native.py
```

Альтернатива (батник, вызывает тот же пайплайн):

```bat
scripts\build_windows.bat
```

Итоговые артефакты появятся в `bindings\shared\build\`:

- `fastembed.dll` (Windows)
- предкомпилированные объектные файлы для Python-сборки: `embedding_lib.obj`, `embedding_generator.obj`

### 2) Сборка всех биндингов и тесты

```bat
scripts\build_all_windows.bat
scripts\test_all_windows.bat
```

## Сборка и проверка по языкам

### Node.js (N-API)

```bat
cd bindings\nodejs
npm install
npm run build
node test-native.js
```

### Python (pybind11)

На Windows расширение ссылается на объектные файлы из `bindings\shared\build`. Если их нет — выполните шаг "Сборка общей нативной библиотеки".

```bat
cd bindings\python
pip install pybind11 numpy
python setup.py build_ext --inplace
python test_python_native.py
```

### C# (P/Invoke)

```bat
cd bindings\csharp
dotnet build src\FastEmbed.csproj
dotnet run --project test_csharp_native.csproj --no-build
```

### Java (JNI)

```bat
cd bindings\java
bash run_benchmark.sh
```

Скрипт соберёт JNI-обёртку и класс-тест, затем запустит бенчмарк/проверку загрузки `fastembed.dll` из `target\lib`.

## Очистка артефактов (Windows)

```bat
make clean  ^  (вызовет scripts\clean_windows.bat)
```

Либо напрямую:

```bat
scripts\clean_windows.bat
```

## Примечания

- Node.js использует N-API (нативный модуль), FFI не применяется.
- Python использует pybind11; на Windows линковка идёт к заранее собранным `.obj` из `bindings\shared\build`.
- C# использует P/Invoke и резолвер `NativeLibrary.SetDllImportResolver`, который сначала ищет `fastembed.dll` рядом с собранными `.dll` биндинга.
- Java использует минимальный JNI-слой; библиотека ищется через `-Djava.library.path`.

## Частые проблемы

- «nasm не найден»: установите NASM и добавьте путь к `nasm.exe` в PATH, либо используйте `bindings\nodejs\nasm_wrapper.bat` (оно вызывается автоматически из `binding.gyp`).
- Ошибка при сборке Python: убедитесь, что выполнен шаг сборки общей библиотеки и присутствуют `.obj` файлы в `bindings\shared\build`.
- Проблемы с очисткой `make clean` под Windows: используйте `scripts\clean_windows.bat` напрямую.
