#!/bin/bash
# Build script for FastEmbed Linux shared library with ONNX Runtime support
# Requires: GCC/Clang, NASM, ONNX Runtime 1.23.2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_DIR="$PROJECT_ROOT/bindings/shared"
SRC_DIR="$SHARED_DIR/src"
INC_DIR="$SHARED_DIR/include"
BUILD_DIR="$SHARED_DIR/build"

echo "========================================"
echo "FastEmbed Linux Build Script (with ONNX)"
echo "========================================"
echo

# Check for NASM
if ! command -v nasm &> /dev/null; then
    echo "❌ ERROR: NASM not found!"
    echo
    echo "Install NASM:"
    echo "  sudo apt-get install nasm  # Debian/Ubuntu"
    echo "  sudo yum install nasm      # RHEL/CentOS"
    exit 1
fi

echo "Found NASM: $(which nasm)"
echo

# Check for compiler
if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
    echo "❌ ERROR: C compiler not found!"
    echo
    echo "Install GCC or Clang:"
    echo "  sudo apt-get install build-essential  # Debian/Ubuntu"
    exit 1
fi

CC="${CC:-$(command -v gcc || command -v clang)}"
echo "Using compiler: $CC"
echo

# Check for ONNX Runtime
ONNX_DIR="$PROJECT_ROOT/bindings/onnxruntime-linux-x64-1.23.2"
if [ ! -d "$ONNX_DIR" ]; then
    echo "⚠️  WARNING: ONNX Runtime not found at: $ONNX_DIR"
    echo
    echo "Download and extract ONNX Runtime:"
    echo "  cd bindings"
    echo "  wget https://github.com/microsoft/onnxruntime/releases/download/v1.23.2/onnxruntime-linux-x64-1.23.2.tgz"
    echo "  tar -xzf onnxruntime-linux-x64-1.23.2.tgz"
    echo
    echo "Alternatively, run setup script:"
    echo "  python3 scripts/setup_onnx.py --platform linux"
    echo
    echo "Building without ONNX Runtime support..."
    USE_ONNX=0
else
    echo "Found ONNX Runtime: $ONNX_DIR"
    USE_ONNX=1
fi
echo

# Create build directory
mkdir -p "$BUILD_DIR"

echo "========================================"
echo "Compiling Assembly files..."
echo "========================================"

nasm -f elf64 "$SRC_DIR/embedding_lib.asm" -o "$BUILD_DIR/embedding_lib.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_lib.asm"
    exit 1
fi

nasm -f elf64 "$SRC_DIR/embedding_generator.asm" -o "$BUILD_DIR/embedding_generator.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_generator.asm"
    exit 1
fi

echo
echo "========================================"
echo "Compiling C files..."
echo "========================================"

# Compile embedding_lib_c.c
ONNX_FLAGS=""
ONNX_INCLUDE=""
ONNX_LIB=""
if [ "$USE_ONNX" -eq 1 ]; then
    ONNX_FLAGS="-DUSE_ONNX_RUNTIME"
    ONNX_INCLUDE="-I$ONNX_DIR/include"
    ONNX_LIB="-L$ONNX_DIR/lib -lonnxruntime"
    echo "Compiling with ONNX Runtime support..."
fi

"$CC" -O3 -Wall -fPIC -c -I"$INC_DIR" $ONNX_INCLUDE $ONNX_FLAGS \
    "$SRC_DIR/embedding_lib_c.c" -o "$BUILD_DIR/embedding_lib_c.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_lib_c.c"
    exit 1
fi

# Compile onnx_embedding_loader.c if ONNX is enabled
if [ "$USE_ONNX" -eq 1 ]; then
    "$CC" -O3 -Wall -fPIC -c -I"$INC_DIR" $ONNX_INCLUDE $ONNX_FLAGS \
        "$SRC_DIR/onnx_embedding_loader.c" -o "$BUILD_DIR/onnx_embedding_loader.o"
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Failed to compile onnx_embedding_loader.c"
        exit 1
    fi
fi

echo
echo "========================================"
echo "Linking shared library..."
echo "========================================"

# Link shared library
if [ "$USE_ONNX" -eq 1 ]; then
    "$CC" -shared -fPIC -o "$BUILD_DIR/libfastembed.so" \
        "$BUILD_DIR/embedding_lib.o" \
        "$BUILD_DIR/embedding_generator.o" \
        "$BUILD_DIR/embedding_lib_c.o" \
        "$BUILD_DIR/onnx_embedding_loader.o" \
        $ONNX_LIB \
        -lm -Wl,-rpath,"$ONNX_DIR/lib"
else
    "$CC" -shared -fPIC -o "$BUILD_DIR/libfastembed.so" \
        "$BUILD_DIR/embedding_lib.o" \
        "$BUILD_DIR/embedding_generator.o" \
        "$BUILD_DIR/embedding_lib_c.o" \
        -lm
fi

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to link shared library"
    exit 1
fi

# Copy ONNX Runtime library if available
if [ "$USE_ONNX" -eq 1 ] && [ -f "$ONNX_DIR/lib/libonnxruntime.so" ]; then
    cp "$ONNX_DIR/lib/libonnxruntime.so" "$BUILD_DIR/" 2>/dev/null || true
    echo "Copied ONNX Runtime library to build directory"
fi

echo
echo "========================================"
echo "✅ Build successful!"
echo "========================================"
echo
echo "Built: $BUILD_DIR/libfastembed.so"
if [ "$USE_ONNX" -eq 1 ]; then
    echo "ONNX Runtime: Enabled"
fi
echo
echo "The native library is ready for use with:"
echo "  - Node.js: Native N-API module (bindings/nodejs)"
echo "  - Python: pybind11 extension (bindings/python)"
echo "  - C#: P/Invoke wrapper (bindings/csharp)"
echo "  - Java: JNI wrapper (bindings/java)"
echo

