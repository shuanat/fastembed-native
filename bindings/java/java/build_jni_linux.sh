#!/bin/bash
# Build script for FastEmbed Java JNI shared library (.so) on Linux with ONNX Runtime support
# Requires: JDK, GCC, NASM, ONNX Runtime C/C++ package

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
SHARED_DIR="$PROJECT_ROOT/bindings/shared"
# Check multiple ONNX Runtime locations (workflow renames to "onnxruntime")
ONNX_RUNTIME_DIR="${ONNX_RUNTIME_PATH:-$PROJECT_ROOT/bindings/onnxruntime}"
# Fallback to versioned name if exists
if [ ! -d "$ONNX_RUNTIME_DIR" ]; then
  ONNX_RUNTIME_DIR="$PROJECT_ROOT/bindings/onnxruntime-linux-x64-1.23.2"
fi

echo "========================================"
echo "FastEmbed Java JNI Build Script (Linux)"
echo "========================================"
echo

# Check for Java
if [ -z "$JAVA_HOME" ]; then
    # Try common Java locations
    JAVA_PATHS=(
        "/usr/lib/jvm/java-17-openjdk-amd64"
        "/usr/lib/jvm/java-17-openjdk"
        "/usr/lib/jvm/java-11-openjdk-amd64"
        "/usr/lib/jvm/java-11-openjdk"
    )
    
    for jpath in "${JAVA_PATHS[@]}"; do
        if [ -d "$jpath/include" ]; then
            JAVA_HOME="$jpath"
            echo "Auto-detected JAVA_HOME: $JAVA_HOME"
            break
        fi
    done
    
    if [ -z "$JAVA_HOME" ]; then
        echo "❌ ERROR: JAVA_HOME not set and could not auto-detect"
        echo "Please set JAVA_HOME manually or install JDK"
        exit 1
    fi
fi

if [ ! -d "$JAVA_HOME/include" ]; then
    echo "❌ ERROR: JAVA_HOME/include not found: $JAVA_HOME/include"
    exit 1
fi

echo "JAVA_HOME: $JAVA_HOME"
echo

# Check for GCC
if ! command -v gcc &> /dev/null; then
    echo "❌ ERROR: GCC not found!"
    exit 1
fi
echo "Using compiler: $(which gcc)"

# Check for ONNX Runtime
if [ ! -d "$ONNX_RUNTIME_DIR" ] || [ ! -f "$ONNX_RUNTIME_DIR/include/onnxruntime_c_api.h" ]; then
    echo "❌ ERROR: ONNX Runtime not found at $ONNX_RUNTIME_DIR"
    echo "Checked locations:"
    echo "  - $PROJECT_ROOT/bindings/onnxruntime"
    echo "  - $PROJECT_ROOT/bindings/onnxruntime-linux-x64-1.23.2"
    echo "Please set ONNX_RUNTIME_PATH or ensure ONNX Runtime is downloaded"
    exit 1
fi
echo "Found ONNX Runtime at: $ONNX_RUNTIME_DIR"
echo

# Create build directory
BUILD_DIR="$SCRIPT_DIR/build"
mkdir -p "$BUILD_DIR"

echo "========================================"
echo "Compiling JNI and C files..."
echo "========================================"

# Compile JNI C source
# Note: fastembed_jni.c uses relative paths, so we need to compile from the correct directory
cd "$SCRIPT_DIR"
gcc -fPIC -O2 -Wall -c \
    -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/linux" \
    -I"$SHARED_DIR/include" -I"$ONNX_RUNTIME_DIR/include" \
    -I"$PROJECT_ROOT/bindings/shared/include" \
    -DUSE_ONNX_RUNTIME -DFASTEMBED_BUILDING_LIB \
    "native/fastembed_jni.c" -o "$BUILD_DIR/fastembed_jni.o"
cd - > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile fastembed_jni.c"
    exit 1
fi

# Compile shared C library sources directly into JNI
gcc -fPIC -O2 -Wall -c \
    -I"$SHARED_DIR/include" -I"$ONNX_RUNTIME_DIR/include" \
    -DUSE_ONNX_RUNTIME -DFASTEMBED_BUILDING_LIB \
    "$SHARED_DIR/src/embedding_lib_c.c" -o "$BUILD_DIR/embedding_lib_c.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_lib_c.c"
    exit 1
fi

gcc -fPIC -O2 -Wall -c \
    -I"$SHARED_DIR/include" -I"$ONNX_RUNTIME_DIR/include" \
    -DUSE_ONNX_RUNTIME -DFASTEMBED_BUILDING_LIB \
    "$SHARED_DIR/src/onnx_embedding_loader.c" -o "$BUILD_DIR/onnx_embedding_loader.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile onnx_embedding_loader.c"
    exit 1
fi

# Compile assembly files if needed
if [ -f "$SHARED_DIR/src/embedding_lib.asm" ]; then
    if ! command -v nasm &> /dev/null; then
        echo "⚠️  WARNING: NASM not found, skipping assembly files"
    else
        nasm -f elf64 "$SHARED_DIR/src/embedding_lib.asm" -o "$BUILD_DIR/embedding_lib.o"
        nasm -f elf64 "$SHARED_DIR/src/embedding_generator.asm" -o "$BUILD_DIR/embedding_generator.o"
    fi
fi

echo
echo "========================================"
echo "Linking JNI shared library..."
echo "========================================"

# Link all objects into the JNI shared library
LINK_OBJECTS="$BUILD_DIR/fastembed_jni.o $BUILD_DIR/embedding_lib_c.o $BUILD_DIR/onnx_embedding_loader.o"
if [ -f "$BUILD_DIR/embedding_lib.o" ]; then
    LINK_OBJECTS="$LINK_OBJECTS $BUILD_DIR/embedding_lib.o"
fi
if [ -f "$BUILD_DIR/embedding_generator.o" ]; then
    LINK_OBJECTS="$LINK_OBJECTS $BUILD_DIR/embedding_generator.o"
fi

gcc -shared -o "$BUILD_DIR/libfastembed_jni.so" \
    $LINK_OBJECTS \
    -L"$ONNX_RUNTIME_DIR/lib" -lonnxruntime -lm

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to link JNI shared library"
    exit 1
fi

# Copy onnxruntime.so to build directory for easier deployment
if [ -f "$ONNX_RUNTIME_DIR/lib/libonnxruntime.so.1.23.2" ]; then
    cp "$ONNX_RUNTIME_DIR/lib/libonnxruntime.so.1.23.2" "$BUILD_DIR/libonnxruntime.so"
elif [ -f "$ONNX_RUNTIME_DIR/lib/libonnxruntime.so" ]; then
    cp "$ONNX_RUNTIME_DIR/lib/libonnxruntime.so" "$BUILD_DIR/libonnxruntime.so"
fi

echo
echo "========================================"
echo "JNI Build successful!"
echo "========================================"
echo
echo "Built: $BUILD_DIR/libfastembed_jni.so"
if [ -f "$BUILD_DIR/libonnxruntime.so" ]; then
    echo "Copied: $BUILD_DIR/libonnxruntime.so"
fi
echo

