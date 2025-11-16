# FastEmbed Release Guide

**Version**: 1.0.1  
**Date**: 2025-01-14

---

## Quick Release Checklist

- [ ] All tests passing (run `make test`)
- [ ] CHANGELOG.md updated with new version
- [ ] Version numbers updated in all bindings
- [ ] Documentation reviewed and updated
- [ ] Breaking changes documented (if any)
- [ ] Git repository is clean (`git status`)

---

## Release Process

### 1. Pre-Release Validation

```bash
# Ensure you're on the release branch
git checkout release/1.0.1

# Verify all tests pass
make test

# Verify version numbers
grep -r "1.0.1" bindings/*/package.json bindings/*/setup.py bindings/*/*.csproj bindings/*/pom.xml

# Verify CHANGELOG is updated
cat CHANGELOG.md | grep "## \[1.0.1\]"
```

### 2. Create and Push Tag

```bash
# Create annotated tag
git tag -a v1.0.1 -m "Release 1.0.1

## Highlights
- Improved hash-based algorithm (Square Root normalization)
- C# comprehensive test suite (49 tests)
- ONNX Runtime integration
- Cross-platform CI/CD (Linux, Windows, macOS)
- Breaking change: Default dimension 768→128

See CHANGELOG.md for full details."

# Push tag to GitHub
git push origin v1.0.1
```

**Note**: Pushing the tag automatically triggers the `build-artifacts.yml` workflow, which builds:

- Native libraries (`.so`, `.dll`, `.dylib`, `.a`)
- Node.js package (`.tgz`)
- Python wheel (`.whl`)
- C# NuGet package (`.nupkg`)
- Java JAR (`.jar`)

All artifacts are packaged into platform-specific archives and attached to the GitHub Release.

### 3. Monitor GitHub Actions

1. Go to: `https://github.com/YOUR_USERNAME/FastEmbed/actions`
2. Watch the "Build Release Artifacts" workflow
3. Verify all jobs succeed:
   - ✅ build-linux
   - ✅ build-windows
   - ✅ build-macos
   - ✅ create-release

### 4. Verify GitHub Release

1. Go to: `https://github.com/YOUR_USERNAME/FastEmbed/releases`
2. Verify release `v1.0.1` was created
3. Check artifacts are attached:
   - `fastembed-linux-x64-v1.0.1.tar.gz` (includes native libs + Node.js + Python + C# + Java)
   - `fastembed-windows-x64-v1.0.1.zip` (includes native libs + Node.js + Python + C# + Java)
   - `fastembed-macos-x64-v1.0.1.tar.gz` (includes native libs + Node.js + Python + C# + Java)

### 5. Publish to Package Registries

#### Node.js (npm)

```bash
cd bindings/nodejs
npm login
npm publish
```

**Verification**: `npm view fastembed-native version`

#### Python (PyPI)

```bash
cd bindings/python

# Build distributions
python setup.py sdist bdist_wheel

# Upload to PyPI (requires PyPI account and token)
pip install twine
twine upload dist/*
```

**Verification**: `pip show fastembed-native`

#### C# (NuGet)

```bash
cd bindings/csharp

# Pack the project
dotnet pack src/FastEmbed.csproj --configuration Release

# Push to NuGet (requires NuGet API key)
dotnet nuget push src/bin/Release/FastEmbed.*.nupkg --api-key YOUR_API_KEY --source https://api.nuget.org/v3/index.json
```

**Verification**: Search for "FastEmbed" on nuget.org

#### Java (Maven Central)

```bash
cd bindings/java/java

# Deploy to Maven Central (requires Maven Central account)
mvn clean deploy -P release
```

**Verification**: Search for "com.fastembed:fastembed-native" on search.maven.org

---

## Manual Artifact Building (Alternative)

If you prefer to build artifacts manually:

### Build Scripts

FastEmbed provides platform-specific build scripts for manual building:

- **Windows**: `scripts/build_windows.ps1` (PowerShell, enterprise-grade)
- **Cross-platform**: `scripts/build_native.py` (Python, supports Linux/Windows/macOS)
- **Linux/macOS**: `Makefile` (standard make-based build)

### Linux

```bash
# Option 1: Using Makefile (recommended)
cd bindings/shared
make all

# Option 2: Using Python script
python scripts/build_native.py

# Package artifacts
mkdir -p artifacts/linux
cp lib/*.so artifacts/linux/
cp lib/*.a artifacts/linux/
cp include/*.h artifacts/linux/
cd artifacts
tar -czf fastembed-linux-x64-v1.0.1.tar.gz linux/
```

### Windows

```powershell
# Build using PowerShell script (recommended)
.\scripts\build_windows.ps1

# Package artifacts
New-Item -ItemType Directory -Force -Path artifacts\windows
Copy-Item -Path bindings\shared\lib\* -Destination artifacts\windows\ -Include *.dll, *.lib
Copy-Item -Path bindings\shared\include\*.h -Destination artifacts\windows\
cd artifacts
Compress-Archive -Path windows\* -DestinationPath fastembed-windows-x64-v1.0.1.zip
```

**Note**: The PowerShell script (`build_windows.ps1`) has replaced the old batch script with:

- Automatic Visual Studio Build Tools detection
- Structured logging (INFO, SUCCESS, WARNING, ERROR, DEBUG)
- ONNX Runtime integration
- Standardized error messages

### macOS

```bash
# Option 1: Using Makefile (recommended)
cd bindings/shared
make all

# Option 2: Using Python script
python scripts/build_native.py

# Package artifacts
mkdir -p artifacts/macos
cp lib/*.dylib artifacts/macos/
cp lib/*.a artifacts/macos/
cp include/*.h artifacts/macos/
cd artifacts
tar -czf fastembed-macos-x64-v1.0.1.tar.gz macos/
```

**macOS arm64 Note**: The build system automatically uses native ARM64 NEON assembly for macOS arm64 (Apple Silicon) for optimal performance. The Makefile detects arm64 and compiles ARM64 assembly files using `as -arch arm64`.

### Upload to GitHub Release (Manual)

1. Go to: `https://github.com/YOUR_USERNAME/FastEmbed/releases/new`
2. Tag: `v1.0.1`
3. Title: `FastEmbed 1.0.1`
4. Description: Copy from `CHANGELOG.md` (v1.0.1 section)
5. Attach files:
   - `fastembed-linux-x64-v1.0.1.tar.gz`
   - `fastembed-windows-x64-v1.0.1.zip`
   - `fastembed-macos-x64-v1.0.1.tar.gz`
6. Click "Publish release"

---

## Post-Release

### 1. Announce Release

- Update project README.md with new version
- Update documentation site (if any)
- Notify users via social media / blog

### 2. Monitor for Issues

- Watch GitHub Issues for bug reports
- Monitor package registry download counts
- Check CI/CD for any failures

### 3. Prepare Next Version

```bash
# Create new branch for next version
git checkout -b develop/1.0.2

# Add "Unreleased" section to CHANGELOG
cat << 'EOF' >> CHANGELOG.md.tmp
## [Unreleased]

### Added

- (Future improvements will be listed here)

---

EOF
cat CHANGELOG.md >> CHANGELOG.md.tmp
mv CHANGELOG.md.tmp CHANGELOG.md

git add CHANGELOG.md
git commit -m "Prepare for v1.0.2 development"
```

---

## Rollback Procedure

If critical issues are found after release:

### 1. Delete Release and Tag

```bash
# Delete GitHub release (via web UI)
# Go to releases, click release, click "Delete"

# Delete local tag
git tag -d v1.0.1

# Delete remote tag
git push origin :refs/tags/v1.0.1
```

### 2. Unpublish Packages (if possible)

- **npm**: `npm unpublish fastembed-native@1.0.1` (within 72 hours)
- **PyPI**: Contact PyPI admins (cannot self-unpublish)
- **NuGet**: Can unlist but not delete
- **Maven Central**: Cannot delete (requires new version)

### 3. Create Hotfix

```bash
# Create hotfix branch
git checkout -b hotfix/1.0.1-fix

# Fix critical issue
# ...

# Update version to 1.0.1-fix or 1.0.2
# Commit, tag, and release as v1.0.1-fix or v1.0.2
```

---

## Troubleshooting

### "GitHub Actions workflow not triggering"

- **Cause**: Tag not pushed or workflow file has errors
- **Solution**:

  ```bash
  git push origin v1.0.1
  # Check workflow file: .github/workflows/build-artifacts.yml
  ```

### "Build artifacts missing from release"

- **Cause**: Build job failed or upload step failed
- **Solution**:
  - Check GitHub Actions logs
  - Re-run failed jobs
  - Upload artifacts manually if needed

### "Package publish fails"

- **Cause**: Authentication issues or version conflicts
- **Solution**:
  - Verify API keys/tokens
  - Check if version already exists
  - Review package registry logs

### "ONNX Runtime download fails"

- **Cause**: Network issues or version not available
- **Solution**:
  - Verify ONNX_VERSION env variable
  - Check ONNX Runtime releases page
  - Use local ONNX Runtime installation

### "Build fails with 'NASM not found'" (Windows)

- **Cause**: NASM assembler not installed or not in PATH
- **Solution**:
  - Install NASM: `choco install nasm` or download from <https://www.nasm.us/>
  - Add to PATH: `C:\Program Files\NASM`
  - Restart terminal

### "Build fails with 'Visual Studio Build Tools not found'" (Windows)

- **Cause**: MSVC compiler not installed
- **Solution**:
  - Install Visual Studio 2022 Build Tools
  - Select "Desktop development with C++" workload
  - Restart terminal

---

## Version Numbering

FastEmbed follows [Semantic Versioning](https://semver.org/):

- **Major** (X.0.0): Breaking changes
- **Minor** (1.X.0): New features (backward compatible)
- **Patch** (1.0.X): Bug fixes (backward compatible)

**Examples**:

- `1.0.0` → `1.0.1`: Bug fixes
- `1.0.1` → `1.1.0`: New features (e.g., new ONNX models)
- `1.1.0` → `2.0.0`: Breaking changes (e.g., API redesign)

---

## Release Artifacts Contents

### Linux Artifacts (`fastembed-linux-x64-v1.0.1.tar.gz`)

```
linux/
├── fastembed.so          # Shared library
├── libfastembed.a        # Static library
└── fastembed.h           # Header file
```

### Windows Artifacts (`fastembed-windows-x64-v1.0.1.zip`)

```
windows/
├── fastembed_native.dll  # Dynamic library
├── fastembed_native.lib  # Import library
└── fastembed.h           # Header file
```

### macOS Artifacts (`fastembed-macos-x64-v1.0.1.tar.gz`)

```
macos/
├── libfastembed.dylib    # Dynamic library
├── libfastembed.a        # Static library
└── fastembed.h           # Header file
```

---

## Support

For questions or issues with the release process:

- Open an issue: `https://github.com/YOUR_USERNAME/FastEmbed/issues`

---

**Last Updated**: 2025-01-14  
**FastEmbed Version**: 1.0.1
