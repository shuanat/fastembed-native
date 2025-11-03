#!/bin/bash
# Build script for FastEmbed Java JNI shared library (Linux)
# Requires: GCC/Clang, Java JDK 17+, ONNX Runtime 1.23.2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
JAVA_DIR="$SCRIPT_DIR"
SHARED_DIR="$PROJECT_ROOT/bindings/shared"
BUILD_DIR="$JAVA_DIR/build"
NATIVE_DIR="$JAVA_DIR/native"

echo "========================================"
echo "Java JNI Linux Build Script"
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
        "/usr/lib/jvm/java-8-openjdk-amd64"
        "/usr/lib/jvm/java-8-openjdk"
    )
    
    for jpath in "${JAVA_PATHS[@]}"; do
        if [ -d "$jpath/include" ]; then
            JAVA_HOME="$jpath"
            echo "Auto-detected JAVA_HOME: $JAVA_HOME"
            break
        fi
    done
    
    # If still not found, try to find from java command
    if [ -z "$JAVA_HOME" ] && command -v java &> /dev/null; then
        JAVA_BIN=$(which java)
        if [ -L "$JAVA_BIN" ]; then
            JAVA_BIN=$(readlink -f "$JAVA_BIN" 2>/dev/null || echo "$JAVA_BIN")
        fi
        JAVA_DIR=$(dirname "$JAVA_BIN")
        JAVA_HOME_CANDIDATE=$(dirname "$JAVA_DIR")
        if [ -d "$JAVA_HOME_CANDIDATE/include" ]; then
            JAVA_HOME="$JAVA_HOME_CANDIDATE"
            echo "Auto-detected JAVA_HOME from java command: $JAVA_HOME"
        fi
    fi
    
    if [ -z "$JAVA_HOME" ]; then
        echo "❌ ERROR: JAVA_HOME not set and could not auto-detect"
        echo
        echo "Please set JAVA_HOME manually:"
        echo "  export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
        echo
        echo "Or install JDK:"
        echo "  sudo apt-get install openjdk-17-jdk"
        exit 1
    fi
fi

if [ ! -d "$JAVA_HOME/include" ]; then
    echo "❌ ERROR: JAVA_HOME/include not found: $JAVA_HOME/include"
    echo "Please set JAVA_HOME to a valid JDK installation"
    echo "Current JAVA_HOME: $JAVA_HOME"
    exit 1
fi

echo "JAVA_HOME: $JAVA_HOME"
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
    echo "❌ ERROR: ONNX Runtime not found at: $ONNX_DIR"
    echo
    echo "Download and extract ONNX Runtime:"
    echo "  cd bindings"
    echo "  wget https://github.com/microsoft/onnxruntime/releases/download/v1.23.2/onnxruntime-linux-x64-1.23.2.tgz"
    echo "  tar -xzf onnxruntime-linux-x64-1.23.2.tgz"
    echo
    echo "Alternatively, run setup script:"
    echo "  python3 scripts/setup_onnx.py --platform linux"
    exit 1
fi

echo "Found ONNX Runtime: $ONNX_DIR"
echo

# Create build directory
mkdir -p "$BUILD_DIR"

echo "========================================"
echo "Compiling JNI wrapper..."
echo "========================================"

# Compile fastembed_jni.c
"$CC" -O3 -fPIC -shared \
    -I"$JAVA_HOME/include" \
    -I"$JAVA_HOME/include/linux" \
    -I"$SHARED_DIR/include" \
    -I"$ONNX_DIR/include" \
    -DUSE_ONNX_RUNTIME \
    -c "$NATIVE_DIR/fastembed_jni.c" \
    -o "$BUILD_DIR/fastembed_jni.o"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile fastembed_jni.c"
    exit 1
fi

echo "Compiling embedding_lib_c.c..."
"$CC" -O3 -fPIC \
    -I"$SHARED_DIR/include" \
    -I"$ONNX_DIR/include" \
    -DUSE_ONNX_RUNTIME \
    -DFASTEMBED_BUILDING_LIB \
    -c "$SHARED_DIR/src/embedding_lib_c.c" \
    -o "$BUILD_DIR/embedding_lib_c.o"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile embedding_lib_c.c"
    exit 1
fi

echo "Compiling onnx_embedding_loader.c..."
"$CC" -O3 -fPIC \
    -I"$SHARED_DIR/include" \
    -I"$ONNX_DIR/include" \
    -DUSE_ONNX_RUNTIME \
    -DFASTEMBED_BUILDING_LIB \
    -c "$SHARED_DIR/src/onnx_embedding_loader.c" \
    -o "$BUILD_DIR/onnx_embedding_loader.o"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to compile onnx_embedding_loader.c"
    exit 1
fi

# Compile shared library assembly objects
echo "Compiling assembly files..."
if [ ! -f "$SHARED_DIR/build/embedding_lib.o" ] || [ ! -f "$SHARED_DIR/build/embedding_generator.o" ]; then
    echo "Building shared library objects first..."
    cd "$PROJECT_ROOT"
    bash scripts/build_linux.sh
    cd "$JAVA_DIR"
fi

echo
echo "========================================"
echo "Linking JNI shared library..."
echo "========================================"

# Link JNI library
"$CC" -shared -fPIC -o "$BUILD_DIR/libfastembed_jni.so" \
    "$BUILD_DIR/fastembed_jni.o" \
    "$BUILD_DIR/embedding_lib_c.o" \
    "$BUILD_DIR/onnx_embedding_loader.o" \
    "$SHARED_DIR/build/embedding_lib.o" \
    "$SHARED_DIR/build/embedding_generator.o" \
    -L"$ONNX_DIR/lib" \
    -lonnxruntime \
    -lm \
    -Wl,-rpath,"$ONNX_DIR/lib"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Failed to link JNI library"
    exit 1
fi

# Copy ONNX Runtime library
if [ -f "$ONNX_DIR/lib/libonnxruntime.so" ]; then
    cp "$ONNX_DIR/lib/libonnxruntime.so" "$BUILD_DIR/" 2>/dev/null || true
    echo "Copied ONNX Runtime library to build directory"
fi

echo
echo "========================================"
echo "✅ Build successful!"
echo "========================================"
echo
echo "Built: $BUILD_DIR/libfastembed_jni.so"
echo
echo "To use the library, set:"
echo "  export LD_LIBRARY_PATH=$BUILD_DIR:\$LD_LIBRARY_PATH"
echo
echo "Or run Java with:"
echo "  java -Djava.library.path=$BUILD_DIR ..."
echo

