# FastEmbed Root Makefile
# Builds all language bindings

.PHONY: all shared nodejs python csharp java clean test test-onnx setup-onnx

all: shared nodejs python csharp java

shared:
	$(MAKE) -C bindings/shared all
	$(MAKE) -C bindings/shared shared

nodejs: shared
	cd bindings/nodejs && npm install && npm run build

python: shared
	cd bindings/python && python3 setup.py build_ext --inplace

csharp: shared
	@export PATH="$$HOME/.dotnet:$$PATH" && \
	cd bindings/csharp && dotnet build src/FastEmbed.csproj

java: shared
	cd bindings/java && bash build_benchmark.sh

test:
	@echo "Running tests for all bindings..."
	@echo "\n=== Testing Node.js ==="
	cd bindings/nodejs && node test-native.js
	@echo "\n=== Testing Python ==="
	cd bindings/python && python3 test_python_native.py
	@echo "\n=== Testing C# ==="
	@export PATH="$$HOME/.dotnet:$$PATH" && \
	cd bindings/csharp/tests && dotnet test --no-build || \
	(cd .. && dotnet build tests/FastEmbed.Tests.csproj && \
	LD_LIBRARY_PATH=../shared/build:$$LD_LIBRARY_PATH dotnet test tests/FastEmbed.Tests.csproj)
	@echo "\n=== Testing Java ==="
	cd bindings/java && java -cp "java/target/classes:java/target/test-classes" com.fastembed.test.TestFastEmbedJava || \
	(cd java && javac -cp "target/classes" test_java_native.java && \
	java -cp "target/classes:." test_java_native)

test-onnx:
	@echo "Running ONNX tests for all bindings (conditional)..."
	@echo "\n=== Testing Node.js ONNX ==="
	cd bindings/nodejs && node test-onnx.js || echo "⚠ ONNX tests skipped (model not available)"
	@echo "\n=== Testing Python ONNX ==="
	cd bindings/python && python3 test_onnx.py || echo "⚠ ONNX tests skipped (model not available)"
	@echo "\n=== Testing C# ONNX ==="
	@export PATH="$$HOME/.dotnet:$$PATH" && \
	cd bindings/csharp/tests && dotnet test --filter "FullyQualifiedName~FastEmbedOnnxTests" || \
	echo "⚠ ONNX tests skipped (model not available or tests marked as Skip)"
	@echo "\n=== Testing Java ONNX ==="
	cd bindings/java && javac -cp "java/target/classes" test_onnx.java && \
	java -cp "java/target/classes:." test_onnx || echo "⚠ ONNX tests skipped (model not available)"

ifeq ($(OS),Windows_NT)
clean:
	@echo Cleaning (Windows)...
	@call scripts\clean_windows.bat
else
clean:
	$(MAKE) -C bindings/shared clean
	rm -rf bindings/nodejs/build/
	find bindings/nodejs -name "*.node" -type f -delete 2>/dev/null || true
	rm -rf bindings/python/build/
	find bindings/python -name "*.so" -type f -delete 2>/dev/null || true
	find bindings/python -name "*.cpython-*.so" -type f -delete 2>/dev/null || true
	find bindings/python -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	rm -rf bindings/csharp/bin/ bindings/csharp/obj/
	rm -rf bindings/java/target/
endif

setup-onnx:
	$(MAKE) -C bindings/shared setup-onnx

help:
	@echo "FastEmbed Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all        - Build all language bindings"
	@echo "  shared     - Build shared native library"
	@echo "  nodejs     - Build Node.js binding"
	@echo "  python     - Build Python binding"
	@echo "  csharp     - Build C# binding"
	@echo "  java       - Build Java binding"
	@echo "  test       - Run tests for all bindings"
	@echo "  test-onnx  - Run ONNX tests for all bindings (conditional, skips if ONNX unavailable)"
	@echo "  setup-onnx - Setup ONNX Runtime (optional)"
	@echo "  clean      - Clean all build artifacts"
	@echo "  help       - Show this help message"

