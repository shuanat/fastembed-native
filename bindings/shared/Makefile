# Makefile for Embedding Library Assembly Project

# Compiler and flags
NASM = nasm
CC = gcc
AR = ar
CFLAGS = -O2 -Wall
LDFLAGS = -shared

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    NASM_FLAGS = -f elf64
    TARGET_LIB = fastembed.a
    TARGET_DLL = fastembed.so
    OBJ_EXT = .o
    BUILD_SHARED = yes
endif
ifeq ($(OS),Windows_NT)
    NASM_FLAGS = -f win64
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
	$(AR) rcs $(BUILD_DIR)/$(TARGET_LIB) $(OBJECTS)
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
$(BUILD_DIR)/%$(OBJ_EXT): $(SRC_DIR)/%.asm
	$(NASM) $(NASM_FLAGS) $< -o $@

# Compile C files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# ONNX Runtime support (optional)
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

# Test targets
TEST_SOURCES = tests/test_basic.c
TEST_TARGET = $(BUILD_DIR)/test_basic$(if $(filter Windows_NT,$(OS)),.exe,)

test-build: $(TEST_TARGET)

$(TEST_TARGET): $(TEST_SOURCES) $(BUILD_DIR)/$(TARGET_LIB)
	$(CC) $(CFLAGS) $(INCLUDES) $(TEST_SOURCES) $(BUILD_DIR)/$(TARGET_LIB) -o $(TEST_TARGET) -lm -L$(BUILD_DIR)
	@echo "Built: $(TEST_TARGET)"

test: $(TEST_TARGET)
	@echo "Running tests..."
	@if [ -f "$(TEST_TARGET)" ]; then \
		LD_LIBRARY_PATH=$(BUILD_DIR) ./$(TEST_TARGET) || true; \
	else \
		echo "Error: Test executable not found. Run 'make test-build' first."; \
		exit 1; \
	fi

# Benchmark targets
BENCHMARK_SOURCES = tests/benchmark.c
BENCHMARK_TARGET = $(BUILD_DIR)/benchmark$(if $(filter Windows_NT,$(OS)),.exe,)

benchmark-build: $(BENCHMARK_TARGET)

$(BENCHMARK_TARGET): $(BENCHMARK_SOURCES) $(BUILD_DIR)/$(TARGET_LIB)
	@echo "Building benchmark..."
	@if [ "$(USE_ONNX)" = "1" ]; then \
		$(CC) $(CFLAGS) $(ONNX_FLAGS) $(BENCHMARK_SOURCES) $(BUILD_DIR)/$(TARGET_LIB) -o $(BENCHMARK_TARGET) -lm -L$(BUILD_DIR) $(ONNX_LIBS); \
	else \
		$(CC) $(CFLAGS) $(INCLUDES) $(BENCHMARK_SOURCES) $(BUILD_DIR)/$(TARGET_LIB) -o $(BENCHMARK_TARGET) -lm -L$(BUILD_DIR); \
	fi
	@echo "Built: $(BENCHMARK_TARGET)"

benchmark: $(BENCHMARK_TARGET)
	@echo "Running benchmarks..."
	@if [ -f "$(BENCHMARK_TARGET)" ]; then \
		LD_LIBRARY_PATH=$(BUILD_DIR):$(ONNX_RUNTIME_PATH)/lib ./$(BENCHMARK_TARGET) || true; \
	else \
		echo "Error: Benchmark executable not found. Run 'make benchmark-build' first."; \
		exit 1; \
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

