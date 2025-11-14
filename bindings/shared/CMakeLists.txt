# CMake configuration for FastEmbed Library
# Cross-platform build system supporting Windows (MSVC/MinGW), Linux, macOS

cmake_minimum_required(VERSION 3.15)
project(FastEmbed VERSION 1.0.0 LANGUAGES C ASM_NASM)

# ==============================================================================
# Build Options
# ==============================================================================
option(BUILD_SHARED_LIBS "Build shared library" ON)
option(BUILD_CLI_TOOLS "Build CLI tools" ON)
option(BUILD_TESTS "Build test suite" ON)
option(BUILD_BENCHMARKS "Build benchmarks" ON)
option(USE_ONNX_RUNTIME "Enable ONNX Runtime support" ON)

# ==============================================================================
# Compiler Settings
# ==============================================================================
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Optimization flags
if(MSVC)
    add_compile_options(/W4 /O2)
else()
    add_compile_options(-Wall -O2)
endif()

# ==============================================================================
# NASM Configuration
# ==============================================================================
enable_language(ASM_NASM)

if(WIN32)
    set(CMAKE_ASM_NASM_OBJECT_FORMAT win64)
elseif(APPLE)
    set(CMAKE_ASM_NASM_OBJECT_FORMAT macho64)
else()
    set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
endif()

# NASM flags
set(CMAKE_ASM_NASM_FLAGS "-f ${CMAKE_ASM_NASM_OBJECT_FORMAT}")

# ==============================================================================
# Source Files
# ==============================================================================
set(ASM_SOURCES
    src/embedding_lib.asm
    src/embedding_generator.asm
)

set(C_SOURCES
    src/embedding_lib_c.c
)

set(ONNX_SOURCES
    src/onnx_embedding_loader.c
)

# ==============================================================================
# ONNX Runtime Auto-Detection
# ==============================================================================
set(ONNX_FOUND FALSE)
set(ONNX_INCLUDE_DIR "")
set(ONNX_LIBRARY_DIR "")
set(ONNX_LIBRARY "")

if(USE_ONNX_RUNTIME)
    # Get project root (two levels up from bindings/shared)
    get_filename_component(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
    
    # Search paths for ONNX Runtime
    set(ONNX_SEARCH_PATHS
        "${PROJECT_ROOT}/onnxruntime"
        "${CMAKE_CURRENT_SOURCE_DIR}/onnxruntime"
        "/usr/local"
        "$ENV{ONNXRUNTIME_DIR}"
    )
    
    foreach(SEARCH_PATH ${ONNX_SEARCH_PATHS})
        if(EXISTS "${SEARCH_PATH}/include/onnxruntime_c_api.h")
            set(ONNX_INCLUDE_DIR "${SEARCH_PATH}/include")
            
            # Find library directory
            if(WIN32)
                if(EXISTS "${SEARCH_PATH}/lib/onnxruntime.lib")
                    set(ONNX_LIBRARY_DIR "${SEARCH_PATH}/lib")
                    set(ONNX_LIBRARY "${SEARCH_PATH}/lib/onnxruntime.lib")
                    set(ONNX_FOUND TRUE)
                endif()
            else()
                if(EXISTS "${SEARCH_PATH}/lib/libonnxruntime.so" OR EXISTS "${SEARCH_PATH}/lib/libonnxruntime.dylib")
                    set(ONNX_LIBRARY_DIR "${SEARCH_PATH}/lib")
                    set(ONNX_LIBRARY "${SEARCH_PATH}/lib/libonnxruntime.so")
                    set(ONNX_FOUND TRUE)
                endif()
            endif()
            
            if(ONNX_FOUND)
                message(STATUS "Found ONNX Runtime: ${SEARCH_PATH}")
                break()
            endif()
        endif()
    endforeach()
    
    if(NOT ONNX_FOUND)
        message(WARNING "ONNX Runtime not found. Building without ONNX support.")
        set(USE_ONNX_RUNTIME OFF)
    endif()
endif()

# ==============================================================================
# FastEmbed Static Library
# ==============================================================================
add_library(fastembed_static STATIC
    ${ASM_SOURCES}
    ${C_SOURCES}
)

# Add ONNX sources if available
if(USE_ONNX_RUNTIME AND ONNX_FOUND)
    target_sources(fastembed_static PRIVATE ${ONNX_SOURCES})
    target_compile_definitions(fastembed_static PUBLIC USE_ONNX_RUNTIME)
    target_include_directories(fastembed_static PRIVATE ${ONNX_INCLUDE_DIR})
    target_link_libraries(fastembed_static PRIVATE ${ONNX_LIBRARY})
endif()

target_include_directories(fastembed_static
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

target_link_libraries(fastembed_static PUBLIC m)

# Set output name based on platform
if(WIN32)
    set_target_properties(fastembed_static PROPERTIES OUTPUT_NAME "fastembed")
else()
    set_target_properties(fastembed_static PROPERTIES OUTPUT_NAME "fastembed")
endif()

# ==============================================================================
# FastEmbed Shared Library
# ==============================================================================
if(BUILD_SHARED_LIBS)
    add_library(fastembed_shared SHARED
        ${ASM_SOURCES}
        ${C_SOURCES}
    )
    
    # Add ONNX sources if available
    if(USE_ONNX_RUNTIME AND ONNX_FOUND)
        target_sources(fastembed_shared PRIVATE ${ONNX_SOURCES})
        target_compile_definitions(fastembed_shared PUBLIC USE_ONNX_RUNTIME)
        target_include_directories(fastembed_shared PRIVATE ${ONNX_INCLUDE_DIR})
        target_link_libraries(fastembed_shared PRIVATE ${ONNX_LIBRARY})
    endif()
    
    target_include_directories(fastembed_shared
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            $<INSTALL_INTERFACE:include>
    )
    
    target_link_libraries(fastembed_shared PUBLIC m)
    
    # Set output name
    set_target_properties(fastembed_shared PROPERTIES OUTPUT_NAME "fastembed")
endif()

# ==============================================================================
# CLI Tools
# ==============================================================================
if(BUILD_CLI_TOOLS)
    # Vector operations CLI
    add_executable(vector_ops_cli src/vector_ops_cli.c)
    target_link_libraries(vector_ops_cli PRIVATE fastembed_static)
    
    # Embedding generator CLI
    add_executable(embedding_gen_cli src/embedding_gen_cli.c)
    target_link_libraries(embedding_gen_cli PRIVATE fastembed_static)
    
    # ONNX CLI (if ONNX Runtime available)
    if(USE_ONNX_RUNTIME AND ONNX_FOUND)
        add_executable(onnx_cli src/onnx_embedding_cli.c)
        target_link_libraries(onnx_cli PRIVATE fastembed_static)
        target_compile_definitions(onnx_cli PRIVATE USE_ONNX_RUNTIME)
    endif()
endif()

# ==============================================================================
# Tests
# ==============================================================================
if(BUILD_TESTS)
    enable_testing()
    
    # Test: Hash Functions
    add_executable(test_hash_functions ../../tests/test_hash_functions.c)
    target_link_libraries(test_hash_functions PRIVATE fastembed_static)
    add_test(NAME test_hash_functions COMMAND test_hash_functions)
    
    # Test: Embedding Generation
    add_executable(test_embedding_generation ../../tests/test_embedding_generation.c)
    target_link_libraries(test_embedding_generation PRIVATE fastembed_static)
    add_test(NAME test_embedding_generation COMMAND test_embedding_generation)
    
    # Test: Quality Improvement
    add_executable(test_quality_improvement ../../tests/test_quality_improvement.c)
    target_link_libraries(test_quality_improvement PRIVATE fastembed_static)
    add_test(NAME test_quality_improvement COMMAND test_quality_improvement)
    
    # Test: ONNX Dimension (only if ONNX Runtime available)
    if(USE_ONNX_RUNTIME AND ONNX_FOUND)
        add_executable(test_onnx_dimension ../../tests/test_onnx_dimension.c)
        target_link_libraries(test_onnx_dimension PRIVATE fastembed_static)
        target_compile_definitions(test_onnx_dimension PRIVATE USE_ONNX_RUNTIME)
        add_test(NAME test_onnx_dimension COMMAND test_onnx_dimension)
    endif()
endif()

# ==============================================================================
# Benchmarks
# ==============================================================================
if(BUILD_BENCHMARKS)
    # Improved Benchmark
    add_executable(benchmark_improved ../../tests/benchmark_improved.c)
    target_link_libraries(benchmark_improved PRIVATE fastembed_static)
    
    # Enable optimization for benchmarks
    if(MSVC)
        target_compile_options(benchmark_improved PRIVATE /O2)
    else()
        target_compile_options(benchmark_improved PRIVATE -O3)
    endif()
    
    # Add ONNX support to benchmark if available
    if(USE_ONNX_RUNTIME AND ONNX_FOUND)
        target_compile_definitions(benchmark_improved PRIVATE USE_ONNX_RUNTIME)
    endif()
endif()

# ==============================================================================
# Installation
# ==============================================================================
install(TARGETS fastembed_static
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

if(BUILD_SHARED_LIBS)
    install(TARGETS fastembed_shared
        ARCHIVE DESTINATION lib
        LIBRARY DESTINATION lib
        RUNTIME DESTINATION bin
    )
endif()

# Install headers
install(DIRECTORY include/
    DESTINATION include/fastembed
    FILES_MATCHING PATTERN "*.h"
)

# ==============================================================================
# Summary
# ==============================================================================
message(STATUS "")
message(STATUS "========================================")
message(STATUS "FastEmbed Configuration Summary")
message(STATUS "========================================")
message(STATUS "Version:           ${PROJECT_VERSION}")
message(STATUS "Build type:        ${CMAKE_BUILD_TYPE}")
message(STATUS "C Compiler:        ${CMAKE_C_COMPILER}")
message(STATUS "NASM Assembler:    ${CMAKE_ASM_NASM_COMPILER}")
message(STATUS "Build shared libs: ${BUILD_SHARED_LIBS}")
message(STATUS "Build CLI tools:   ${BUILD_CLI_TOOLS}")
message(STATUS "Build tests:       ${BUILD_TESTS}")
message(STATUS "Build benchmarks:  ${BUILD_BENCHMARKS}")
message(STATUS "ONNX Runtime:      ${USE_ONNX_RUNTIME}")
if(USE_ONNX_RUNTIME AND ONNX_FOUND)
    message(STATUS "  Include:         ${ONNX_INCLUDE_DIR}")
    message(STATUS "  Library:         ${ONNX_LIBRARY_DIR}")
endif()
message(STATUS "========================================")
message(STATUS "")

