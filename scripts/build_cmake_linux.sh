#!/bin/bash
# CMake build script for Linux/WSL
# Builds FastEmbed library, tests, and CLI tools using CMake

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/bindings/shared/build_cmake"

echo "========================================"
echo "FastEmbed CMake Build (Linux/WSL)"
echo "========================================"
echo

# Check if CMake is installed
if ! command -v cmake &> /dev/null; then
    echo "ERROR: CMake not found. Please install CMake:"
    echo "  Ubuntu/Debian: sudo apt-get install cmake"
    echo "  Fedora/RHEL:   sudo dnf install cmake"
    echo "  macOS:         brew install cmake"
    exit 1
fi

# Check if NASM is installed
if ! command -v nasm &> /dev/null; then
    echo "ERROR: NASM not found. Please install NASM:"
    echo "  Ubuntu/Debian: sudo apt-get install nasm"
    echo "  Fedora/RHEL:   sudo dnf install nasm"
    echo "  macOS:         brew install nasm"
    exit 1
fi

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo
echo "[1/3] Configuring CMake project..."
echo

# Configure CMake
cmake "$PROJECT_ROOT/bindings/shared" \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_CLI_TOOLS=ON \
    -DBUILD_TESTS=ON \
    -DBUILD_BENCHMARKS=ON \
    -DUSE_ONNX_RUNTIME=ON \
    -DCMAKE_BUILD_TYPE=Release

echo
echo "[2/3] Building project..."
echo

# Build the project
cmake --build . --config Release -- -j$(nproc)

echo
echo "[3/3] Build completed successfully!"
echo
echo "========================================"
echo "Build Summary"
echo "========================================"
echo "Build directory: $BUILD_DIR"
echo
echo "Libraries:"
ls -lh "$BUILD_DIR"/libfastembed.* 2>/dev/null || echo "  (none found)"
echo
echo "CLI Tools:"
ls -lh "$BUILD_DIR"/*_cli 2>/dev/null || echo "  (none found)"
echo
echo "Tests:"
ls -lh "$BUILD_DIR"/test_* 2>/dev/null || echo "  (none found)"
echo
echo "Benchmarks:"
ls -lh "$BUILD_DIR"/benchmark_* 2>/dev/null || echo "  (none found)"
echo "========================================"
echo
echo "To run tests:"
echo "  cd $BUILD_DIR"
echo "  ctest --verbose"
echo
echo "Or run individual tests:"
echo "  $BUILD_DIR/test_hash_functions"
echo "  $BUILD_DIR/test_embedding_generation"
echo "  $BUILD_DIR/test_quality_improvement"
echo
echo "To run benchmarks:"
echo "  $BUILD_DIR/benchmark_improved"
echo "========================================"

cd "$PROJECT_ROOT"

