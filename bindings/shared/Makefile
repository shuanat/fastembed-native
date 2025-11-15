# Makefile for Embedding Library Assembly Project

# Compiler and flags
# NASM can be overridden from environment (e.g., "arch -arm64 nasm" on macOS)
NASM ?= nasm
CC ?= gcc
AR = ar
CFLAGS = -O2 -Wall
LDFLAGS = -shared

# Detect OS
UNAME_S := $(shell uname -s)

# Use NASM_FLAGS from environment if set (for architecture-specific builds)
# Otherwise set default based on OS
ifndef NASM_FLAGS
    ifeq ($(UNAME_S),Linux)
        NASM_FLAGS = -f elf64
    else ifeq ($(UNAME_S),Darwin)
        NASM_FLAGS = -f macho64
    else ifeq ($(OS),Windows_NT)
        NASM_FLAGS = -f win64
    endif
endif

# Set platform-specific variables
ifeq ($(UNAME_S),Linux)
    TARGET_LIB = fastembed.a
    TARGET_DLL = fastembed.so
    OBJ_EXT = .o
    BUILD_SHARED = yes
endif
ifeq ($(UNAME_S),Darwin)
    TARGET_LIB = fastembed.a
    TARGET_DLL = fastembed.dylib
    OBJ_EXT = .o
    BUILD_SHARED = yes
endif
ifeq ($(OS),Windows_NT)
    TARGET_LIB = fastembed.lib
    TARGET_DLL = fastembed.dll
    OBJ_EXT = .obj
    BUILD_SHARED = yes
endif

# Directories
SRC_DIR = src
INC_DIR = include
BUILD_DIR = build

# Create build directory
$(shell mkdir -p $(BUILD_DIR))

# Source files
ASM_SOURCES = $(SRC_DIR)/embedding_lib.asm $(SRC_DIR)/embedding_generator.asm
C_SOURCES = $(SRC_DIR)/embedding_lib_c.c
OBJECTS = $(BUILD_DIR)/embedding_lib$(OBJ_EXT) $(BUILD_DIR)/embedding_generator$(OBJ_EXT) $(BUILD_DIR)/embedding_lib_c.o
CLI_SOURCES = $(SRC_DIR)/vector_ops_cli.c $(SRC_DIR)/embedding_gen_cli.c
CLI_OBJECTS = $(BUILD_DIR)/vector_ops_cli.o $(BUILD_DIR)/embedding_gen_cli.o
CLI_TARGETS = $(BUILD_DIR)/vector_ops_cli$(if $(filter Windows_NT,$(OS)),.exe,) $(BUILD_DIR)/embedding_gen_cli$(if $(filter Windows_NT,$(OS)),.exe,)

# Include directories
INCLUDES = -I$(INC_DIR)

# Targets
# Build all standard targets (onnx_cli is optional, only if ONNX Runtime is available)
all: $(BUILD_DIR)/$(TARGET_LIB) $(CLI_TARGETS)
	@if [ "$(USE_ONNX)" = "1" ]; then \
		$(MAKE) onnx_cli || echo "⚠️  ONNX CLI skipped (ONNX Runtime not available)"; \
	fi

# Convenience target for library only
fastembed.a: $(BUILD_DIR)/$(TARGET_LIB)
	@echo "Library built: $(BUILD_DIR)/$(TARGET_LIB)"

# Build static library
$(BUILD_DIR)/$(TARGET_LIB): $(OBJECTS)
	@rm -f $(BUILD_DIR)/$(TARGET_LIB)
	$(AR) rcs $(BUILD_DIR)/$(TARGET_LIB) $(OBJECTS)
	@if command -v ranlib >/dev/null 2>&1; then ranlib $(BUILD_DIR)/$(TARGET_LIB); fi
	@echo "Built: $(BUILD_DIR)/$(TARGET_LIB)"

# Build shared library (optional)
shared: $(BUILD_DIR)/$(TARGET_DLL)

$(BUILD_DIR)/$(TARGET_DLL): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $(BUILD_DIR)/$(TARGET_DLL) -lm
	@echo "Built: $(BUILD_DIR)/$(TARGET_DLL)"

# Build CLI tools
$(BUILD_DIR)/vector_ops_cli$(if $(filter Windows_NT,$(OS)),.exe,): $(BUILD_DIR)/vector_ops_cli.o $(BUILD_DIR)/$(TARGET_LIB)
	$(CC) $(CFLAGS) $(BUILD_DIR)/vector_ops_cli.o $(BUILD_DIR)/$(TARGET_LIB) -o $(BUILD_DIR)/vector_ops_cli$(if $(filter Windows_NT,$(OS)),.exe,) -lm
	@echo "Built: $(BUILD_DIR)/vector_ops_cli$(if $(filter Windows_NT,$(OS)),.exe,)"

$(BUILD_DIR)/embedding_gen_cli$(if $(filter Windows_NT,$(OS)),.exe,): $(BUILD_DIR)/embedding_gen_cli.o $(BUILD_DIR)/$(TARGET_LIB)
	$(CC) $(CFLAGS) $(BUILD_DIR)/embedding_gen_cli.o $(BUILD_DIR)/$(TARGET_LIB) -o $(BUILD_DIR)/embedding_gen_cli$(if $(filter Windows_NT,$(OS)),.exe,) -lm
	@echo "Built: $(BUILD_DIR)/embedding_gen_cli$(if $(filter Windows_NT,$(OS)),.exe,)"

# Compile assembly files
# Use $(NASM) variable which can be overridden from environment (e.g., "arch -arm64 nasm")
$(BUILD_DIR)/%$(OBJ_EXT): $(SRC_DIR)/%.asm
	$(NASM) $(NASM_FLAGS) $< -o $@

# Compile C files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# ONNX Runtime support
# Auto-detect ONNX Runtime: first check project root, then current dir, then /usr/local
comma := ,
# Get project root: go up from bindings/shared (two levels)
CURDIR_ABS = $(shell pwd)
PROJECT_ROOT = $(shell dirname $(shell dirname $(CURDIR_ABS)))
ONNX_PROJECT_ROOT = $(PROJECT_ROOT)/onnxruntime
ONNX_LOCAL_PATH = $(CURDIR_ABS)/onnxruntime
ONNX_RUNTIME_PATH ?= $(if $(wildcard $(ONNX_PROJECT_ROOT)/include/onnxruntime_c_api.h),$(ONNX_PROJECT_ROOT),$(if $(wildcard $(ONNX_LOCAL_PATH)/include/onnxruntime_c_api.h),$(ONNX_LOCAL_PATH),/usr/local/onnxruntime))
USE_ONNX ?= $(if $(wildcard $(ONNX_RUNTIME_PATH)/include/onnxruntime_c_api.h),1,0)
ONNX_FLAGS = $(if $(filter 1,$(USE_ONNX)),-DUSE_ONNX_RUNTIME -I$(ONNX_RUNTIME_PATH)/include $(INCLUDES) -I$(SRC_DIR),$(INCLUDES) -I$(SRC_DIR))
ONNX_RPATH = $(if $(filter 1,$(USE_ONNX)),-Wl$(comma)-rpath$(comma)$(ONNX_RUNTIME_PATH)/lib,)
ONNX_LIBS = $(if $(filter 1,$(USE_ONNX)),-L$(ONNX_RUNTIME_PATH)/lib -lonnxruntime $(ONNX_RPATH) -ldl,)

# ONNX sources (optional)
ONNX_SOURCES = $(SRC_DIR)/onnx_embedding_cli.c $(SRC_DIR)/onnx_embedding_loader.c
ONNX_OBJECTS = $(BUILD_DIR)/onnx_embedding_cli.o $(BUILD_DIR)/onnx_embedding_loader.o
ONNX_TARGET = $(BUILD_DIR)/onnx_embedding_cli$(if $(filter Windows_NT,$(OS)),.exe,)

# Build ONNX embedding CLI (optional, requires ONNX Runtime)
onnx_cli: check-onnx $(ONNX_TARGET)

# Check if ONNX Runtime is available, offer to install if not
check-onnx:
	@if [ "$(USE_ONNX)" != "1" ]; then \
		echo ""; \
		echo "⚠️  ONNX Runtime not found!"; \
		echo "   Checked paths:"; \
		echo "   - $(ONNX_PROJECT_ROOT)"; \
		echo "   - $(ONNX_LOCAL_PATH)"; \
		echo "   - /usr/local/onnxruntime"; \
		echo ""; \
		echo "   Run 'make setup-onnx' to download and install ONNX Runtime."; \
		echo "   Or set ONNX_RUNTIME_PATH=/path/to/onnxruntime"; \
		echo ""; \
		echo "   Building onnx_cli with hash-based fallback..."; \
	else \
		echo ""; \
		echo "✅ ONNX Runtime found at: $(ONNX_RUNTIME_PATH)"; \
		echo ""; \
	fi

$(ONNX_TARGET): $(ONNX_OBJECTS) $(BUILD_DIR)/$(TARGET_LIB)
ifeq ($(USE_ONNX),1)
	$(CC) $(CFLAGS) $(ONNX_FLAGS) $(ONNX_OBJECTS) $(BUILD_DIR)/$(TARGET_LIB) $(ONNX_LIBS) -o $(ONNX_TARGET) -lm
	@echo "Built: $(ONNX_TARGET) (with ONNX Runtime)"
else
	$(CC) $(CFLAGS) $(BUILD_DIR)/onnx_embedding_cli.o $(BUILD_DIR)/$(TARGET_LIB) -o $(ONNX_TARGET) -lm
	@echo "Built: $(ONNX_TARGET) (hash-based fallback)"
endif

# Compile ONNX sources
$(BUILD_DIR)/onnx_embedding_cli.o: $(SRC_DIR)/onnx_embedding_cli.c
	$(CC) $(CFLAGS) $(ONNX_FLAGS) -c $< -o $@

$(BUILD_DIR)/onnx_embedding_loader.o: $(SRC_DIR)/onnx_embedding_loader.c
	$(CC) $(CFLAGS) $(ONNX_FLAGS) -c $< -o $@

# Clean
clean:
	rm -rf $(BUILD_DIR)
	rm -f $(SRC_DIR)/*.o $(SRC_DIR)/*.obj test_basic test_basic.exe
	@if [ -d "$(BUILD_DIR)" ]; then rm -rf $(BUILD_DIR); fi
	rm -f test_hash_functions test_hash_functions.exe
	rm -f test_embedding_generation test_embedding_generation.exe
	rm -f test_quality_improvement test_quality_improvement.exe
	rm -f test_onnx_dimension test_onnx_dimension.exe
	rm -f benchmark_improved benchmark_improved.exe

# Test targets
TEST_SOURCES = tests/test_basic.c tests/test_hash_functions.c tests/test_embedding_generation.c tests/test_quality_improvement.c tests/test_onnx_dimension.c
TEST_TARGET = $(BUILD_DIR)/test_basic$(if $(filter Windows_NT,$(OS)),.exe,)
TEST_HASH_TARGET = $(BUILD_DIR)/test_hash_functions$(if $(filter Windows_NT,$(OS)),.exe,)
TEST_EMBEDDING_TARGET = $(BUILD_DIR)/test_embedding_generation$(if $(filter Windows_NT,$(OS)),.exe,)
TEST_QUALITY_TARGET = $(BUILD_DIR)/test_quality_improvement$(if $(filter Windows_NT,$(OS)),.exe,)
TEST_ONNX_TARGET = $(BUILD_DIR)/test_onnx_dimension$(if $(filter Windows_NT,$(OS)),.exe,)

test-build: $(TEST_TARGET) $(TEST_HASH_TARGET) $(TEST_EMBEDDING_TARGET) $(TEST_QUALITY_TARGET) $(TEST_ONNX_TARGET)

$(TEST_TARGET): ../../tests/test_basic.c $(BUILD_DIR)/$(TARGET_LIB)
	$(CC) $(CFLAGS) $(INCLUDES) ../../tests/test_basic.c $(BUILD_DIR)/$(TARGET_LIB) -o $(TEST_TARGET) -lm -L$(BUILD_DIR)
	@echo "Built: $(TEST_TARGET)"

$(TEST_HASH_TARGET): ../../tests/test_hash_functions.c $(BUILD_DIR)/$(TARGET_LIB)
	$(CC) $(CFLAGS) $(INCLUDES) ../../tests/test_hash_functions.c $(BUILD_DIR)/$(TARGET_LIB) -o $(TEST_HASH_TARGET) -lm -L$(BUILD_DIR)
	@echo "Built: $(TEST_HASH_TARGET)"

$(TEST_EMBEDDING_TARGET): ../../tests/test_embedding_generation.c $(BUILD_DIR)/$(TARGET_LIB)
	$(CC) $(CFLAGS) $(INCLUDES) ../../tests/test_embedding_generation.c $(BUILD_DIR)/$(TARGET_LIB) -o $(TEST_EMBEDDING_TARGET) -lm -L$(BUILD_DIR)
	@echo "Built: $(TEST_EMBEDDING_TARGET)"

$(TEST_QUALITY_TARGET): ../../tests/test_quality_improvement.c $(BUILD_DIR)/$(TARGET_LIB)
	$(CC) $(CFLAGS) $(INCLUDES) ../../tests/test_quality_improvement.c $(BUILD_DIR)/$(TARGET_LIB) -o $(TEST_QUALITY_TARGET) -lm -L$(BUILD_DIR)
	@echo "Built: $(TEST_QUALITY_TARGET)"

$(TEST_ONNX_TARGET): ../../tests/test_onnx_dimension.c $(BUILD_DIR)/$(TARGET_LIB)
	@if [ "$(USE_ONNX)" = "1" ]; then \
		$(CC) $(CFLAGS) $(ONNX_FLAGS) $(INCLUDES) ../../tests/test_onnx_dimension.c $(BUILD_DIR)/$(TARGET_LIB) -o $(TEST_ONNX_TARGET) -lm -L$(BUILD_DIR) $(ONNX_LIBS); \
		echo "Built: $(TEST_ONNX_TARGET) (with ONNX support)"; \
	else \
		echo "Skipping $(TEST_ONNX_TARGET) (ONNX Runtime not available)"; \
	fi

test: $(TEST_TARGET) $(TEST_HASH_TARGET) $(TEST_EMBEDDING_TARGET) $(TEST_QUALITY_TARGET)
	@echo "Running all tests..."
ifeq ($(OS),Windows_NT)
	@echo "\n=== Running test_basic ==="
	@if exist "$(TEST_TARGET)" ( \
		cd $(BUILD_DIR) && $(TEST_TARGET) \
	) else ( \
		echo Test not found \
	)
	@echo "\n=== Running test_hash_functions ==="
	@if exist "$(TEST_HASH_TARGET)" ( \
		cd $(BUILD_DIR) && $(TEST_HASH_TARGET) \
	) else ( \
		echo Test not found \
	)
	@echo "\n=== Running test_embedding_generation ==="
	@if exist "$(TEST_EMBEDDING_TARGET)" ( \
		cd $(BUILD_DIR) && $(TEST_EMBEDDING_TARGET) \
	) else ( \
		echo Test not found \
	)
	@echo "\n=== Running test_quality_improvement ==="
	@if exist "$(TEST_QUALITY_TARGET)" ( \
		cd $(BUILD_DIR) && $(TEST_QUALITY_TARGET) \
	) else ( \
		echo Test not found \
	)
	@if exist "$(TEST_ONNX_TARGET)" ( \
		echo "\n=== Running test_onnx_dimension ===" && \
		cd $(BUILD_DIR) && $(TEST_ONNX_TARGET) \
	)
else
	@echo "\n=== Running test_basic ==="
	@if [ -f "$(TEST_TARGET)" ]; then \
		LD_LIBRARY_PATH=$(BUILD_DIR) ./$(TEST_TARGET) || true; \
	fi
	@echo "\n=== Running test_hash_functions ==="
	@if [ -f "$(TEST_HASH_TARGET)" ]; then \
		LD_LIBRARY_PATH=$(BUILD_DIR) ./$(TEST_HASH_TARGET) || true; \
	fi
	@echo "\n=== Running test_embedding_generation ==="
	@if [ -f "$(TEST_EMBEDDING_TARGET)" ]; then \
		LD_LIBRARY_PATH=$(BUILD_DIR) ./$(TEST_EMBEDDING_TARGET) || true; \
	fi
	@echo "\n=== Running test_quality_improvement ==="
	@if [ -f "$(TEST_QUALITY_TARGET)" ]; then \
		LD_LIBRARY_PATH=$(BUILD_DIR) ./$(TEST_QUALITY_TARGET) || true; \
	fi
	@if [ "$(USE_ONNX)" = "1" ] && [ -f "$(TEST_ONNX_TARGET)" ]; then \
		echo "\n=== Running test_onnx_dimension ==="; \
		LD_LIBRARY_PATH=$(BUILD_DIR):$(ONNX_RUNTIME_PATH)/lib ./$(TEST_ONNX_TARGET) || true; \
	fi
endif

# Benchmark targets
BENCHMARK_SOURCES = tests/benchmark.c
BENCHMARK_TARGET = $(BUILD_DIR)/benchmark$(if $(filter Windows_NT,$(OS)),.exe,)
BENCHMARK_IMPROVED_TARGET = $(BUILD_DIR)/benchmark_improved$(if $(filter Windows_NT,$(OS)),.exe,)

benchmark-build: $(BENCHMARK_TARGET) $(BENCHMARK_IMPROVED_TARGET)

$(BENCHMARK_TARGET): $(BENCHMARK_SOURCES) $(BUILD_DIR)/$(TARGET_LIB)
	@echo "Building benchmark..."
	@if [ "$(USE_ONNX)" = "1" ]; then \
		$(CC) $(CFLAGS) $(ONNX_FLAGS) $(BENCHMARK_SOURCES) $(BUILD_DIR)/$(TARGET_LIB) -o $(BENCHMARK_TARGET) -lm -L$(BUILD_DIR) $(ONNX_LIBS); \
	else \
		$(CC) $(CFLAGS) $(INCLUDES) $(BENCHMARK_SOURCES) $(BUILD_DIR)/$(TARGET_LIB) -o $(BENCHMARK_TARGET) -lm -L$(BUILD_DIR); \
	fi
	@echo "Built: $(BENCHMARK_TARGET)"

$(BENCHMARK_IMPROVED_TARGET): ../../tests/benchmark_improved.c $(BUILD_DIR)/$(TARGET_LIB)
	@echo "Building improved benchmark..."
	@if [ "$(USE_ONNX)" = "1" ]; then \
		$(CC) $(CFLAGS) -O2 $(ONNX_FLAGS) $(INCLUDES) ../../tests/benchmark_improved.c $(BUILD_DIR)/$(TARGET_LIB) -o $(BENCHMARK_IMPROVED_TARGET) -lm -L$(BUILD_DIR) $(ONNX_LIBS); \
	else \
		$(CC) $(CFLAGS) -O2 $(INCLUDES) ../../tests/benchmark_improved.c $(BUILD_DIR)/$(TARGET_LIB) -o $(BENCHMARK_IMPROVED_TARGET) -lm -L$(BUILD_DIR); \
	fi
	@echo "Built: $(BENCHMARK_IMPROVED_TARGET)"

benchmark: $(BENCHMARK_TARGET) $(BENCHMARK_IMPROVED_TARGET)
	@echo "Running benchmarks..."
	@echo "\n=== Running original benchmark ==="
	@if [ -f "$(BENCHMARK_TARGET)" ]; then \
		LD_LIBRARY_PATH=$(BUILD_DIR):$(ONNX_RUNTIME_PATH)/lib ./$(BENCHMARK_TARGET) || true; \
	fi
	@echo "\n=== Running improved benchmark ==="
	@if [ -f "$(BENCHMARK_IMPROVED_TARGET)" ]; then \
		LD_LIBRARY_PATH=$(BUILD_DIR):$(ONNX_RUNTIME_PATH)/lib ./$(BENCHMARK_IMPROVED_TARGET) || true; \
	fi

# Setup targets
setup-onnx:
	@echo "Setting up ONNX Runtime..."
	@python3 ../../scripts/setup_onnx.py || \
	(echo "❌ setup_onnx.py failed"; exit 1)

setup-model:
	@echo "Downloading nomic-embed-text model..."
	@mkdir -p models
	@if command -v huggingface-cli >/dev/null 2>&1; then \
		echo "Using huggingface-cli to download model..."; \
		huggingface-cli download nomic-ai/nomic-embed-text-v1 \
			--include "onnx/model.onnx" \
			--local-dir models/nomic-embed-text || \
		(echo "❌ Failed to download model with huggingface-cli"; exit 1); \
		if [ -f "models/nomic-embed-text/onnx/model.onnx" ]; then \
			cp models/nomic-embed-text/onnx/model.onnx models/nomic-embed-text.onnx; \
			echo "✅ Model downloaded to models/nomic-embed-text.onnx"; \
		else \
			echo "❌ Model file not found after download"; \
			exit 1; \
		fi \
	else \
		echo "⚠️  huggingface-cli not found. Setting up virtual environment..."; \
		if ! command -v python3 >/dev/null 2>&1; then \
			echo "❌ python3 not found. Please install Python 3 first."; \
			exit 1; \
		fi; \
		VENV_DIR="$$(pwd)/.venv"; \
		if [ ! -d "$$VENV_DIR" ]; then \
			echo "Creating virtual environment at $$VENV_DIR..."; \
			python3 -m venv "$$VENV_DIR" || \
			(echo "❌ Failed to create virtual environment"; exit 1); \
		fi; \
		echo "Installing huggingface-hub in virtual environment..."; \
		"$$VENV_DIR/bin/pip" install --upgrade --quiet huggingface-hub || \
		(echo "❌ Failed to install huggingface-hub"; exit 1); \
		echo "✅ Downloading model using Python script..."; \
		"$$VENV_DIR/bin/python" scripts/download_model.py || \
		(echo "❌ Failed to download model"; exit 1); \
		if [ ! -f "models/nomic-embed-text.onnx" ]; then \
			echo "❌ Model file not found after download"; \
			exit 1; \
		fi; \
		echo ""; \
		echo "💡 Virtual environment created at .venv/"; \
		echo "   You can reuse it for future downloads or remove it with: rm -rf .venv"; \
	fi

setup: setup-onnx setup-model
	@echo ""
	@echo "✅ Setup complete!"
	@echo "   ONNX Runtime: onnxruntime/"
	@echo "   Model: models/nomic-embed-text.onnx"

.PHONY: all clean test test-build benchmark benchmark-build setup setup-onnx setup-model

