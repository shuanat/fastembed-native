# FastEmbed Root Makefile
# Builds all language bindings

.PHONY: all shared nodejs python csharp java clean test setup-onnx

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
	cd bindings/csharp && dotnet build test_csharp_native.csproj && \
	LD_LIBRARY_PATH=../shared/build:$$LD_LIBRARY_PATH dotnet run --project test_csharp_native.csproj --no-build
	@echo "\n=== Testing Java ==="
	cd bindings/java && bash run_benchmark.sh

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
	@echo "  setup-onnx - Setup ONNX Runtime (optional)"
	@echo "  clean      - Clean all build artifacts"
	@echo "  help       - Show this help message"

