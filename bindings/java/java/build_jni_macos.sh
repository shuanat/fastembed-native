#!/bin/bash
# Build script for FastEmbed Java JNI shared library (.dylib) on macOS with ONNX Runtime support
# Requires: JDK, GCC/Clang, NASM, ONNX Runtime C/C++ package

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
SHARED_DIR="$PROJECT_ROOT/bindings/shared"
# Check multiple ONNX Runtime locations (workflow renames to "onnxruntime")
ONNX_RUNTIME_DIR="${ONNX_RUNTIME_PATH:-$PROJECT_ROOT/bindings/onnxruntime}"
# Fallback to versioned name if exists
if [ ! -d "$ONNX_RUNTIME_DIR" ]; then
  ONNX_RUNTIME_DIR="$PROJECT_ROOT/bindings/onnxruntime-macos-arm64-1.23.2"
fi

echo "========================================"
echo "FastEmbed Java JNI Build Script (macOS)"
echo "========================================"
echo

# Check for Java
if [ -z "$JAVA_HOME" ]; then
    # Try common Java locations on macOS
    JAVA_PATHS=(
        "/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home"
        "/Library/Java/JavaVirtualMachines/jdk-11.jdk/Contents/Home"
        "/usr/libexec/java_home"
    )
    
    for jpath in "${JAVA_PATHS[@]}"; do
        if [ -d "$jpath/include" ]; then
            JAVA_HOME="$jpath"
            echo "Auto-detected JAVA_HOME: $JAVA_HOME"
            break
        fi
    done
    
    # Try java_home command
    if [ -z "$JAVA_HOME" ] && command -v /usr/libexec/java_home &> /dev/null; then
        JAVA_HOME=$(/usr/libexec/java_home)
        echo "Auto-detected JAVA_HOME via java_home: $JAVA_HOME"
    fi
    
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

# Detect architecture
ARCH=$(uname -m)
echo "Architecture: $ARCH"

# Check for compiler (prefer clang on macOS)
if command -v clang &> /dev/null; then
    CC=clang
elif command -v gcc &> /dev/null; then
    CC=gcc
else
    echo "❌ ERROR: No C compiler found (clang or gcc)!"
    exit 1
fi
echo "Using compiler: $(which $CC)"

# Check for ONNX Runtime
if [ ! -d "$ONNX_RUNTIME_DIR" ] || [ ! -f "$ONNX_RUNTIME_DIR/include/onnxruntime_c_api.h" ]; then
    echo "❌ ERROR: ONNX Runtime not found at $ONNX_RUNTIME_DIR"
    echo "Checked locations:"
    echo "  - $PROJECT_ROOT/bindings/onnxruntime"
    echo "  - $PROJECT_ROOT/bindings/onnxruntime-macos-arm64-1.23.2"
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
$CC -fPIC -O2 -Wall -c \
    -I"$JAVA_HOME/include" -I"$JAVA_HOME/include/darwin" \
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
$CC -fPIC -O2 -Wall -c \
    -I"$SHARED_DIR/include" -I"$ONNX_RUNTIME_DIR/include" \
    -DUSE_ONNX_RUNTIME -DFASTEMBED_BUILDING_LIB \
    "$SHARED_DIR/src/embedding_lib_c.c" -o "$BUILD_DIR/embedding_lib_c.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_lib_c.c"
    exit 1
fi

$CC -fPIC -O2 -Wall -c \
    -I"$SHARED_DIR/include" -I"$ONNX_RUNTIME_DIR/include" \
    -DUSE_ONNX_RUNTIME -DFASTEMBED_BUILDING_LIB \
    "$SHARED_DIR/src/onnx_embedding_loader.c" -o "$BUILD_DIR/onnx_embedding_loader.o"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile onnx_embedding_loader.c"
    exit 1
fi

# Compile ARM64 assembly files if needed
if [ "$ARCH" = "arm64" ] && [ -f "$SHARED_DIR/src/embedding_lib_arm64.s" ]; then
    if ! command -v as &> /dev/null; then
        echo "⚠️  WARNING: as (assembler) not found, skipping assembly files"
    else
        as -arch arm64 "$SHARED_DIR/src/embedding_lib_arm64.s" -o "$BUILD_DIR/embedding_lib_arm64.o"
        as -arch arm64 "$SHARED_DIR/src/embedding_generator_arm64.s" -o "$BUILD_DIR/embedding_generator_arm64.o"
    fi
fi

echo
echo "========================================"
echo "Linking JNI shared library..."
echo "========================================"

# Link all objects into the JNI shared library
LINK_OBJECTS="$BUILD_DIR/fastembed_jni.o $BUILD_DIR/embedding_lib_c.o $BUILD_DIR/onnx_embedding_loader.o"
if [ -f "$BUILD_DIR/embedding_lib_arm64.o" ]; then
    LINK_OBJECTS="$LINK_OBJECTS $BUILD_DIR/embedding_lib_arm64.o"
fi
if [ -f "$BUILD_DIR/embedding_generator_arm64.o" ]; then
    LINK_OBJECTS="$LINK_OBJECTS $BUILD_DIR/embedding_generator_arm64.o"
fi

$CC -shared -o "$BUILD_DIR/libfastembed_jni.dylib" \
    $LINK_OBJECTS \
    -L"$ONNX_RUNTIME_DIR/lib" -lonnxruntime -lm

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to link JNI shared library"
    exit 1
fi

# Copy onnxruntime.dylib to build directory for easier deployment
if [ -f "$ONNX_RUNTIME_DIR/lib/libonnxruntime.dylib" ]; then
    cp "$ONNX_RUNTIME_DIR/lib/libonnxruntime.dylib" "$BUILD_DIR/libonnxruntime.dylib"
fi

echo
echo "========================================"
echo "JNI Build successful!"
echo "========================================"
echo
echo "Built: $BUILD_DIR/libfastembed_jni.dylib"
if [ -f "$BUILD_DIR/libonnxruntime.dylib" ]; then
    echo "Copied: $BUILD_DIR/libonnxruntime.dylib"
fi
echo

