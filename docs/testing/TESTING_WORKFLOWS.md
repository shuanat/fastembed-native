# Testing GitHub Actions Workflows

**Date**: 2025-01-14  
**Purpose**: Guide for testing build workflows before release

---

## 🎯 Quick Start: Test Build Workflow

### Method 1: Manual Workflow Dispatch (Recommended)

**Advantages**:

- ✅ Does not create a tag
- ✅ Does not create a release
- ✅ Can select platform for testing
- ✅ Artifacts stored for 7 days

**Steps**:

1. **Commit and push test workflow**:

```bash
cd G:\GitHub\KAG-workspace\FastEmbed

# Ensure files are added
git add .github/workflows/test-build-artifacts.yml
git add docs/TESTING_WORKFLOWS.md
git commit -m "Add test build artifacts workflow"
git push origin release/1.0.1
```

2. **Run via GitHub UI**:
   - Go to: `https://github.com/YOUR_USERNAME/FastEmbed/actions`
   - Select workflow: **"Test Build Artifacts (No Release)"**
   - Click: **"Run workflow"**
   - Select platform:
     - `all` - all platforms (Linux, Windows, macOS)
     - `linux` - Linux only
     - `windows` - Windows only
     - `macos` - macOS only
   - Click: **"Run workflow"** (green button)

3. **Monitor progress**:
   - Workflow will start immediately
   - You'll see:
     - ✅ Test Build Linux
     - ✅ Test Build Windows
     - ✅ Test Build macOS
     - ✅ Test Summary

4. **Check artifacts**:
   - At the bottom of the workflow run page, you'll see **"Artifacts"**
   - Download:
     - `test-fastembed-linux-x64` (Linux .tar.gz)
     - `test-fastembed-windows-x64` (Windows .zip)
     - `test-fastembed-macos-x64` (macOS .tar.gz)

---

### Method 2: Test with Temporary Tag

**Advantages**:

- ✅ Full production workflow verification
- ✅ Creates release (can be deleted later)

**Disadvantages**:

- ⚠️ Creates a real GitHub Release
- ⚠️ Need to delete tag and release after testing

**Steps**:

1. **Create test tag**:

```bash
cd G:\GitHub\KAG-workspace\FastEmbed

# Create tag with -test suffix
git tag -a v1.0.1-test -m "Test build artifacts workflow"

# Push tag
git push origin v1.0.1-test
```

2. **Check GitHub Actions**:
   - Go to: `https://github.com/YOUR_USERNAME/FastEmbed/actions`
   - You'll see workflow: **"Build Release Artifacts"**
   - It will start automatically

3. **Check GitHub Release**:
   - Go to: `https://github.com/YOUR_USERNAME/FastEmbed/releases`
   - You'll see draft release: **"FastEmbed 1.0.1-test"**
   - Verify artifacts are attached

4. **Delete test release and tag**:

```bash
# Delete release via GitHub UI:
# 1. Go to Releases
# 2. Click on release "FastEmbed 1.0.1-test"
# 3. Click "Delete"

# Delete local tag
git tag -d v1.0.1-test

# Delete remote tag
git push origin :refs/tags/v1.0.1-test
```

---

### Method 3: Local Build Test (Fastest)

**Advantages**:

- ✅ Fast local test
- ✅ Does not require GitHub Actions
- ✅ Full control

**Disadvantages**:

- ⚠️ Only for your platform (Windows)
- ⚠️ Does not verify CI/CD integration

**Steps for Windows**:

```powershell
cd G:\GitHub\KAG-workspace\FastEmbed

# 1. Build shared library
cd bindings\shared
.\scripts\build_windows.bat

# 2. Verify outputs
dir build\

# Should see:
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

**Archive Verification**:

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

**Cause**: Workflow file was not pushed to repository

**Solution**:

```bash
git add .github/workflows/test-build-artifacts.yml
git commit -m "Add test workflow"
git push origin release/1.0.1
```

Wait 1-2 minutes, then refresh the Actions page.

---

### Issue 2: "ONNX Runtime download fails"

**Cause**: Network issues or version does not exist

**Solution**: Check available versions:

- <https://github.com/microsoft/onnxruntime/releases>

Update `ONNX_VERSION` in workflow if needed.

---

### Issue 3: "Build fails - NASM not found"

**Cause**: NASM not installed in runner

**Solution**: Check "Install dependencies" or "Setup NASM" step in workflow.

---

### Issue 4: "Artifacts empty or missing"

**Cause**: Build failed or files were not copied

**Solution**: Check "Verify build outputs" step in workflow logs.

---

### Issue 5: "Permission denied in Windows build"

**Cause**: MSVC not found or incorrect permissions

**Solution**: Check "Setup MSVC" step in workflow.

---

## ✅ Pre-Release Checklist

After successful testing:

- [ ] **Test workflow passed** (all platforms ✅)
- [ ] **Artifacts downloaded and verified**:
  - [ ] Linux: .so file is correct
  - [ ] Windows: .dll file is correct
  - [ ] macOS: .dylib file is correct
- [ ] **File sizes are reasonable** (~100-500 KB)
- [ ] **Exports verified** (functions visible)
- [ ] **Headers included** (fastembed.h)

**Now ready for production release!**

---

## 🚀 Production Release

After successful testing:

```bash
# 1. Create production tag
git tag -a v1.0.1 -m "Release 1.0.1"

# 2. Push production tag
git push origin v1.0.1

# 3. Workflow will start automatically
# 4. GitHub Release will be created with artifacts
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
