#!/bin/bash
# Build script for FastEmbed macOS dylib
# Requires: Xcode Command Line Tools, NASM

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_DIR="$PROJECT_ROOT/bindings/shared"
SRC_DIR="$SHARED_DIR/src"
INC_DIR="$SHARED_DIR/include"
BUILD_DIR="$SHARED_DIR/build"

echo "========================================"
echo "FastEmbed macOS Build Script"
echo "========================================"
echo

# Check for NASM
if ! command -v nasm &> /dev/null; then
    echo "❌ ERROR: NASM not found!"
    echo
    echo "Install NASM:"
    echo "  brew install nasm"
    exit 1
fi

echo "Found NASM: $(which nasm)"
echo

# Check for compiler
if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
    echo "❌ ERROR: C compiler not found!"
    echo
    echo "Install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

CC="${CC:-$(command -v gcc || command -v clang)}"
echo "Using compiler: $CC"
echo

# Create build directory
mkdir -p "$BUILD_DIR"

echo "========================================"
echo "Compiling Assembly files..."
echo "========================================"

nasm -f macho64 "$SRC_DIR/embedding_lib.asm" -o "$BUILD_DIR/embedding_lib.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_lib.asm"
    exit 1
fi

nasm -f macho64 "$SRC_DIR/embedding_generator.asm" -o "$BUILD_DIR/embedding_generator.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_generator.asm"
    exit 1
fi

echo
echo "========================================"
echo "Compiling C files..."
echo "========================================"

"$CC" -O2 -Wall -c -I"$INC_DIR" "$SRC_DIR/embedding_lib_c.c" -o "$BUILD_DIR/embedding_lib_c.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_lib_c.c"
    exit 1
fi

echo
echo "========================================"
echo "Linking dylib..."
echo "========================================"

"$CC" -shared -o "$BUILD_DIR/libfastembed.dylib" \
    "$BUILD_DIR/embedding_lib.o" \
    "$BUILD_DIR/embedding_generator.o" \
    "$BUILD_DIR/embedding_lib_c.o" \
    -lm

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to link dylib"
    exit 1
fi

echo
echo "========================================"
echo "Build successful!"
echo "========================================"
echo
echo "Built: $BUILD_DIR/libfastembed.dylib"
echo
echo "The native library is ready for use with:"
echo "  - Node.js: Native N-API module (bindings/nodejs)"
echo "  - Python: pybind11 extension (bindings/python)"
echo "  - C#: P/Invoke wrapper (bindings/csharp)"
echo "  - Java: JNI wrapper (bindings/java)"
echo
echo "Alternative: Use universal build script for cross-platform support:"
echo "  python3 scripts/build_native.py"
echo

