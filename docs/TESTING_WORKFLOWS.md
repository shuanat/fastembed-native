# Testing GitHub Actions Workflows

**Date**: 2025-01-14  
**Purpose**: Guide for testing build workflows before release

---

## 🎯 Quick Start: Test Build Workflow

### Method 1: Manual Workflow Dispatch (Recommended)

**Преимущества**:

- ✅ Не создаёт тег
- ✅ Не создаёт release
- ✅ Можно выбрать платформу для теста
- ✅ Артефакты хранятся 7 дней

**Шаги**:

1. **Commit и push тестовый workflow**:

```bash
cd G:\GitHub\KAG-workspace\FastEmbed

# Убедись, что файлы добавлены
git add .github/workflows/test-build-artifacts.yml
git add docs/TESTING_WORKFLOWS.md
git commit -m "Add test build artifacts workflow"
git push origin release/1.0.1
```

2. **Запусти через GitHub UI**:
   - Зайди: `https://github.com/YOUR_USERNAME/FastEmbed/actions`
   - Выбери workflow: **"Test Build Artifacts (No Release)"**
   - Нажми: **"Run workflow"**
   - Выбери платформу:
     - `all` - все платформы (Linux, Windows, macOS)
     - `linux` - только Linux
     - `windows` - только Windows
     - `macos` - только macOS
   - Нажми: **"Run workflow"** (зелёная кнопка)

3. **Наблюдай за прогрессом**:
   - Workflow запустится немедленно
   - Увидишь:
     - ✅ Test Build Linux
     - ✅ Test Build Windows
     - ✅ Test Build macOS
     - ✅ Test Summary

4. **Проверь артефакты**:
   - Внизу страницы workflow run увидишь **"Artifacts"**
   - Скачай:
     - `test-fastembed-linux-x64` (Linux .tar.gz)
     - `test-fastembed-windows-x64` (Windows .zip)
     - `test-fastembed-macos-x64` (macOS .tar.gz)

---

### Method 2: Test with Temporary Tag

**Преимущества**:

- ✅ Полная проверка production workflow
- ✅ Создаёт release (можно удалить потом)

**Недостатки**:

- ⚠️ Создаёт реальный GitHub Release
- ⚠️ Нужно удалять тег и release после теста

**Шаги**:

1. **Создай тестовый тег**:

```bash
cd G:\GitHub\KAG-workspace\FastEmbed

# Создай тег с суффиксом -test
git tag -a v1.0.1-test -m "Test build artifacts workflow"

# Push тег
git push origin v1.0.1-test
```

2. **Проверь GitHub Actions**:
   - Зайди: `https://github.com/YOUR_USERNAME/FastEmbed/actions`
   - Увидишь workflow: **"Build Release Artifacts"**
   - Он запустится автоматически

3. **Проверь GitHub Release**:
   - Зайди: `https://github.com/YOUR_USERNAME/FastEmbed/releases`
   - Увидишь draft release: **"FastEmbed 1.0.1-test"**
   - Проверь артефакты прикреплены

4. **Удали тестовый release и тег**:

```bash
# Удали release через GitHub UI:
# 1. Зайди в Releases
# 2. Нажми на release "FastEmbed 1.0.1-test"
# 3. Нажми "Delete"

# Удали локальный тег
git tag -d v1.0.1-test

# Удали удалённый тег
git push origin :refs/tags/v1.0.1-test
```

---

### Method 3: Local Build Test (Fastest)

**Преимущества**:

- ✅ Быстрый локальный тест
- ✅ Не требует GitHub Actions
- ✅ Полный контроль

**Недостатки**:

- ⚠️ Только для твоей платформы (Windows)
- ⚠️ Не проверяет CI/CD integration

**Шаги для Windows**:

```powershell
cd G:\GitHub\KAG-workspace\FastEmbed

# 1. Build shared library
cd bindings\shared
.\scripts\build_windows.bat

# 2. Verify outputs
dir build\

# Должен увидеть:
# - fastembed_native.dll
# - fastembed_native.lib

# 3. Package artifacts
New-Item -ItemType Directory -Force -Path ..\..\artifacts\windows
Copy-Item -Path build\*.dll -Destination ..\..\artifacts\windows\
Copy-Item -Path build\*.lib -Destination ..\..\artifacts\windows\
Copy-Item -Path include\*.h -Destination ..\..\artifacts\windows\

cd ..\..\artifacts
Compress-Archive -Path windows\* -DestinationPath fastembed-windows-x64-test.zip

# 4. Verify archive
dir fastembed-windows-x64-test.zip
```

**Проверка архива**:

```powershell
# Extract and inspect
Expand-Archive -Path fastembed-windows-x64-test.zip -DestinationPath test-extract
dir test-extract\
```

---

## 🔍 What to Check in Artifacts

### Linux Artifacts

```bash
# Extract
tar -xzf fastembed-linux-x64-test.tar.gz

# Should contain:
linux/
├── fastembed.so (or libfastembed.so)  # ~100-500 KB
├── libfastembed.a                      # ~100-500 KB
└── fastembed.h                         # ~5-10 KB

# Verify shared library
file linux/fastembed.so
# Should show: ELF 64-bit LSB shared object, x86-64

# Check exports
nm -D linux/fastembed.so | grep fastembed_generate
# Should show exported functions
```

### Windows Artifacts

```powershell
# Extract
Expand-Archive -Path fastembed-windows-x64-test.zip -DestinationPath test

# Should contain:
windows\
├── fastembed_native.dll    # ~100-500 KB
├── fastembed_native.lib    # ~50-100 KB
└── fastembed.h             # ~5-10 KB

# Verify DLL
dumpbin /EXPORTS test\windows\fastembed_native.dll
# Should show exported functions:
# - fastembed_generate
# - fastembed_onnx_generate
# - etc.
```

### macOS Artifacts

```bash
# Extract
tar -xzf fastembed-macos-x64-test.tar.gz

# Should contain:
macos/
├── libfastembed.dylib      # ~100-500 KB
├── libfastembed.a          # ~100-500 KB
└── fastembed.h             # ~5-10 KB

# Verify dylib
file macos/libfastembed.dylib
# Should show: Mach-O 64-bit dynamically linked shared library x86_64

# Check exports
nm -gU macos/libfastembed.dylib | grep fastembed_generate
# Should show exported functions
```

---

## ❌ Common Issues & Fixes

### Issue 1: "Workflow not found"

**Причина**: Workflow файл не был pushed в репозиторий

**Решение**:

```bash
git add .github/workflows/test-build-artifacts.yml
git commit -m "Add test workflow"
git push origin release/1.0.1
```

Подожди 1-2 минуты, затем обнови страницу Actions.

---

### Issue 2: "ONNX Runtime download fails"

**Причина**: Сетевые проблемы или версия не существует

**Решение**: Проверь доступные версии:

- <https://github.com/microsoft/onnxruntime/releases>

Обнови `ONNX_VERSION` в workflow если нужно.

---

### Issue 3: "Build fails - NASM not found"

**Причина**: NASM не установлен в runner

**Решение**: Проверь шаг "Install dependencies" или "Setup NASM" в workflow.

---

### Issue 4: "Artifacts empty or missing"

**Причина**: Build failed или files не скопировались

**Решение**: Проверь шаг "Verify build outputs" в логах workflow.

---

### Issue 5: "Permission denied in Windows build"

**Причина**: MSVC не найден или неправильные права

**Решение**: Проверь шаг "Setup MSVC" в workflow.

---

## ✅ Pre-Release Checklist

После успешного тестирования:

- [ ] **Test workflow пройден** (все платформы ✅)
- [ ] **Артефакты скачаны и проверены**:
  - [ ] Linux: .so файл корректный
  - [ ] Windows: .dll файл корректный
  - [ ] macOS: .dylib файл корректный
- [ ] **Размеры файлов разумные** (~100-500 KB)
- [ ] **Exports проверены** (функции видны)
- [ ] **Headers включены** (fastembed.h)

**Теперь готов к production release!**

---

## 🚀 Production Release

После успешного тестирования:

```bash
# 1. Создай production тег
git tag -a v1.0.1 -m "Release 1.0.1"

# 2. Push production тег
git push origin v1.0.1

# 3. Workflow запустится автоматически
# 4. GitHub Release будет создан с артефактами
```

---

## 📋 Workflow Comparison

| Feature                | Test Workflow              | Production Workflow     |
| ---------------------- | -------------------------- | ----------------------- |
| **Trigger**            | Manual (workflow_dispatch) | Tag push (v*.*.*)       |
| **Creates Release**    | ❌ No                       | ✅ Yes                   |
| **Artifact Retention** | 7 days                     | 90 days                 |
| **Platform Selection** | ✅ Choose specific          | All platforms           |
| **Verification Steps** | ✅ Extra checks             | Standard build          |
| **Can Delete**         | ✅ Easy                     | ⚠️ Requires tag deletion |

---

## 💡 Tips

1. **Test Linux first**: Fastest platform, catches most issues
2. **Test all platforms before release**: Ensure cross-platform compatibility
3. **Keep test artifacts**: Compare with production artifacts
4. **Check logs carefully**: Even if build succeeds, warnings may indicate issues
5. **Test locally first**: Saves GitHub Actions minutes

---

## 📊 GitHub Actions Minutes

**Free tier**: 2000 minutes/month

**Approximate usage**:

- Test build (all platforms): ~30-45 minutes
- Production build (all platforms): ~30-45 minutes

**Recommendation**: Test locally first, then test 1-2 platforms in CI before full test.

---

**Document Updated**: 2025-01-14  
**FastEmbed Version**: 1.0.1
