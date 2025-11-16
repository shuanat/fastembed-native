# Docker Local Testing Guide

## Overview

Use Docker to test FastEmbed builds locally before pushing to CI. This significantly speeds up development iteration by eliminating wait times for GitHub Actions.

## Quick Start

### Windows (PowerShell)

```powershell
# Test all platforms
.\scripts\docker-test.ps1

# Test specific platform
.\scripts\docker-test.ps1 linux
.\scripts\docker-test.ps1 python

# Interactive debugging
.\scripts\docker-test.ps1 shell

# Clean up
.\scripts\docker-test.ps1 clean
```

### Linux/macOS (Bash)

```bash
# Make script executable (first time only)
chmod +x scripts/docker-test.sh

# Test all platforms
./scripts/docker-test.sh

# Test specific platform
./scripts/docker-test.sh linux
./scripts/docker-test.sh python

# Interactive debugging
./scripts/docker-test.sh shell

# Clean up
./scripts/docker-test.sh clean
```

## Manual Docker Commands

### Build and Test Linux Artifacts

```bash
# Build Docker image
docker-compose build linux-build

# Run build
docker-compose run --rm linux-build

# Check artifacts
docker-compose run --rm linux-shell ls -lh bindings/shared/build/
```

### Build and Test Python Wheel

```bash
# Build Docker image
docker-compose build python-build

# Run build
docker-compose run --rm python-build

# Check wheel
docker-compose run --rm linux-shell ls -lh bindings/python/dist/
```

### Interactive Debugging

```bash
# Start interactive shell
docker-compose run --rm linux-shell

# Inside container:
cd bindings/shared
make clean
make shared
ls -lh build/
```

## Testing Phase 1 Fixes

### Test Linux Python pyproject.toml Fix

```bash
# After editing bindings/python/pyproject.toml
./scripts/docker-test.sh python
```

Expected output:

```
=== Testing Python Wheel Build ===
Processing /workspace/bindings/python
  Installing build dependencies (pybind11>=2.10.0, numpy>=1.19.0)
Successfully built fastembed-x.x.x-py3-none-any.whl
=== Wheel built successfully ===
```

### Test Linux Shared Library Build

```bash
./scripts/docker-test.sh linux
```

Expected output:

```
=== Building Linux Artifacts ===
nasm -f elf64 src/embedding_lib.asm -o build/embedding_lib.o
gcc -c -O2 -Iinclude src/embedding_lib_c.c -o build/embedding_lib_c.o
gcc -shared -o build/fastembed.so build/*.o
=== Artifacts built ===
-rwxr-xr-x 1 root root 19K build/fastembed.so
```

## Advantages Over GitHub Actions Testing

| Aspect        | Docker Local           | GitHub Actions         |
| ------------- | ---------------------- | ---------------------- |
| **Speed**     | 30-60 seconds          | 5-10 minutes           |
| **Cost**      | Free (local resources) | GitHub Actions minutes |
| **Iteration** | Instant retry          | Wait for queue + build |
| **Debugging** | Interactive shell      | Log files only         |
| **Network**   | No dependency          | Internet required      |

## Docker Images

### linux-build

- **Base**: Ubuntu 24.04 (matches GitHub Actions)
- **Size**: ~2GB
- **Includes**: GCC, NASM, Python, Node.js, .NET, Java
- **Purpose**: Full build testing

### python-build

- **Base**: Ubuntu 24.04
- **Size**: ~500MB
- **Includes**: Python, build tools, pybind11
- **Purpose**: Python wheel isolated testing

### linux-shell

- **Base**: Same as linux-build
- **Purpose**: Interactive debugging

## Common Issues

### Docker Not Found

**Error**: `docker: command not found`

**Solution**:

- Windows: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Linux: `sudo apt install docker.io docker-compose`
- macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Permission Denied

**Error**: `permission denied while trying to connect to the Docker daemon socket`

**Solution (Linux)**:

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or:
newgrp docker
```

### Build Fails: "No space left on device"

**Solution**:

```bash
# Clean up unused Docker resources
docker system prune -a --volumes -f
```

### Port Already in Use

**Solution**:

```bash
# Stop all containers
docker-compose down

# Or force remove
docker-compose rm -f
```

## Best Practices

### 1. Test Locally Before Pushing

```bash
# Always test before git push
./scripts/docker-test.sh all

# If passed, then:
git push origin release/1.0.1
```

### 2. Use Interactive Shell for Debugging

```bash
# Start shell
./scripts/docker-test.sh shell

# Inside container, run commands step by step:
cd bindings/shared
make clean
nasm -f elf64 src/embedding_lib.asm -o build/embedding_lib.o
gcc -c -O2 -Iinclude src/embedding_lib_c.c -o build/embedding_lib_c.o
# ... etc
```

### 3. Cache Docker Layers

Docker caches layers, so rebuilds are fast. But if you change dependencies:

```bash
# Force rebuild (no cache)
docker-compose build --no-cache linux-build
```

### 4. Clean Up Regularly

```bash
# Weekly cleanup
./scripts/docker-test.sh clean
```

## Integration with Phase 1 Plan

Update **Task 1.1 (Linux Python)** validation:

```bash
# OLD: Manual test
cd bindings/python && python -m build --wheel

# NEW: Docker test (more reliable)
./scripts/docker-test.sh python
```

Update **Phase 1 Validation Gate**:

```bash
# Quick validation before CI
./scripts/docker-test.sh all

# Expected: Both tests pass
# [SUCCESS] Linux build: PASSED
# [SUCCESS] Python build: PASSED
```

## Limitations

### Cannot Test (Need actual platforms)

- **Windows**: Requires Windows Docker images (Linux containers on Windows can't build Windows .dll)
- **macOS**: Requires macOS hardware (no macOS Docker images)
- **Architecture**: Tests x86_64 only (not arm64)

### For Windows/macOS Testing

- Use local builds (see `CONTRIBUTING.md`)
- Or push to GitHub Actions
- Or use VMs (VirtualBox, VMware, etc.)

## Troubleshooting

### Logs

```bash
# View container logs
docker-compose logs linux-build

# Follow logs in real-time
docker-compose logs -f linux-build
```

### Inspect Artifacts

```bash
# Copy artifacts from container
docker-compose run --rm linux-shell tar -czf /tmp/artifacts.tar.gz bindings/shared/build
docker cp $(docker ps -lq):/tmp/artifacts.tar.gz ./
```

### Check File Permissions

```bash
# Files created in container may have root ownership
docker-compose run --rm linux-shell ls -la bindings/shared/build/

# Fix permissions (Linux/macOS)
docker-compose run --rm linux-shell chown -R $(id -u):$(id -g) bindings/shared/build/
```

## Next Steps

1. Install Docker Desktop (if not already)
2. Test Phase 1 fixes locally:

   ```bash
   ./scripts/docker-test.sh all
   ```

3. Iterate quickly without CI wait times
4. When all local tests pass, push to GitHub

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
