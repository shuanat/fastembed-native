/**
 * @file fastembed.h
 * @brief FastEmbed C API Header
 *
 * Ultra-fast native embedding library for generating embeddings and performing
 * vector operations. This library provides SIMD-optimized implementations
 * using assembly code for maximum performance.
 *
 * **Features:**
 * - Hash-based embedding generation (deterministic, fast)
 * - ONNX Runtime integration for neural network embeddings
 * - SIMD-optimized vector operations (SSE/AVX)
 * - Cross-platform: Windows (x64) and Linux (x86-64)
 *
 * **Embedding Generation:**
 * - Hash-based: Fast, deterministic, no model required
 * - ONNX-based: Uses trained neural network models (BERT, etc.)
 *
 * **Vector Operations:**
 * - Dot product: vec1 · vec2
 * - Cosine similarity: (vec1 · vec2) / (||vec1|| * ||vec2||)
 * - L2 norm: ||vec|| = sqrt(Σ(vec[i]²))
 * - Normalization: vec / ||vec||
 * - Vector addition: vec1 + vec2
 *
 * **Performance:**
 * - All vector operations use SIMD instructions (SSE/AVX)
 * - Assembly-optimized implementations
 * - Thread-safe (stateless operations)
 *
 * **Usage Example:**
 * @code
 * #include "fastembed.h"
 * #include "fastembed_config.h"
 *
 * // Default dimension (128) - recommended for most use cases
 * float embedding[FASTEMBED_DEFAULT_DIMENSION];
 * int result = fastembed_generate("Hello world", embedding, 0); // 0 = use
 * default (128)
 *
 * // BERT compatibility (768 dimensions)
 * float embedding_bert[FASTEMBED_EMBEDDING_DIM];
 * int result_bert = fastembed_generate("Hello world", embedding_bert, 768);
 *
 * float similarity = fastembed_cosine_similarity(embedding1, embedding2, 128);
 * @endcode
 *
 * @note For backwards compatibility, see embedding_lib_c.h (deprecated)
 * @note Maximum vector dimension: 2048 (see fastembed_config.h)
 * @note All operations assume vectors are allocated by caller
 *
 * Copyright (c) 2024 FastEmbed Contributors
 * MIT License
 */

#ifndef FASTEMBED_H
#define FASTEMBED_H

#include <stdint.h>

// Export macros for Windows DLL
#ifdef _WIN32
#ifdef FASTEMBED_BUILDING_LIB
#define FASTEMBED_EXPORT __declspec(dllexport)
#else
#define FASTEMBED_EXPORT __declspec(dllimport)
#endif
#else
#define FASTEMBED_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Generate text embedding using improved hash-based algorithm
 *
 * Converts input text into a fixed-size embedding vector using an improved
 * hash-based algorithm with Sin/Cos normalization and positional hashing.
 * The embedding is deterministic: the same text always produces the same
 * embedding.
 *
 * **BREAKING CHANGE (v1.0.1)**: Default dimension changed from 768 to 128.
 * If dimension is 0, the function uses 128 as default. This improves
 * performance while maintaining good quality for most use cases.
 *
 * Supported dimensions: 128, 256, 512, 768, 1024, 2048
 *
 * The improved algorithm uses:
 * - Positional hashing: Character position affects hash value
 * - Sin/Cos normalization: Better distribution in [-1, 1] range
 * - Combined hashing: Reduces collision probability
 * - Case-insensitive normalization: Text is converted to lowercase before
 *   hashing (improves search quality and consistency with ONNX loader)
 *
 * @param text Input text to embed (null-terminated string, max 8192 chars)
 * @param output Output array for embedding vector (must be pre-allocated, size
 * >= dimension)
 * @param dimension Requested embedding dimension (128, 256, 512, 768, 1024,
 * 2048). If 0, uses default dimension 128.
 * @return 0 on success, -1 on error (invalid parameters or generation failure)
 *
 * @note This function uses hash-based embedding, not learned model embeddings
 * @note For ML model embeddings, use fastembed_onnx_generate() instead
 * @note Default dimension is 128 (changed from 768 in v1.0.1)
 * @note Performance: ~0.01-0.05ms for 128D, ~0.05-0.15ms for 768D
 * @note For BERT compatibility, use dimension=768 explicitly
 */
FASTEMBED_EXPORT int fastembed_generate(const char *text, float *output,
                                        int dimension);

/**
 * @brief Calculate dot product of two vectors
 *
 * Computes the dot product (inner product) of two vectors:
 * result = Σ(vec1[i] * vec2[i]) for i = 0..dimension-1
 *
 * Uses SIMD-optimized assembly implementation for maximum performance.
 *
 * @param vec1 First vector (read-only)
 * @param vec2 Second vector (read-only)
 * @param dimension Number of elements in vectors (must match for both)
 * @return Dot product result, or 0.0f on error (invalid parameters)
 *
 * @note Vectors must have the same dimension
 * @note Performance: O(dimension), optimized with SIMD
 */
FASTEMBED_EXPORT float fastembed_dot_product(const float *vec1,
                                             const float *vec2, int dimension);

/**
 * @brief Calculate cosine similarity between two vectors
 *
 * Computes cosine similarity (normalized dot product):
 * similarity = (vec1 · vec2) / (||vec1|| * ||vec2||)
 *
 * Cosine similarity ranges from -1.0 (opposite) to 1.0 (identical).
 * Commonly used for semantic similarity in embedding space.
 *
 * Uses SIMD-optimized assembly implementation for maximum performance.
 *
 * @param vec1 First vector (read-only, should be normalized)
 * @param vec2 Second vector (read-only, should be normalized)
 * @param dimension Number of elements in vectors (must match for both)
 * @return Cosine similarity (-1.0 to 1.0), or 0.0f on error (invalid
 * parameters)
 *
 * @note Returns 0.0f if either vector has zero norm (division by zero)
 * @note For normalized vectors, cosine similarity equals dot product
 * @note Performance: O(dimension), optimized with SIMD
 */
FASTEMBED_EXPORT float fastembed_cosine_similarity(const float *vec1,
                                                   const float *vec2,
                                                   int dimension);

/**
 * @brief Calculate L2 (Euclidean) norm of a vector
 *
 * Computes the Euclidean norm (magnitude) of a vector:
 * norm = sqrt(Σ(vec[i]²)) for i = 0..dimension-1
 *
 * Uses SIMD-optimized assembly implementation for maximum performance.
 *
 * @param vec Input vector (read-only)
 * @param dimension Number of elements in vector
 * @return L2 norm (always >= 0.0), or 0.0f on error (invalid parameters)
 *
 * @note Zero vector returns 0.0 norm
 * @note Performance: O(dimension), optimized with SIMD
 */
FASTEMBED_EXPORT float fastembed_vector_norm(const float *vec, int dimension);

/**
 * @brief Normalize vector to unit length (L2 normalization)
 *
 * Normalizes vector in-place to unit length by dividing each element
 * by the vector's L2 norm. Resulting vector has norm = 1.0.
 *
 * If input vector has zero norm, normalization is skipped (no change).
 *
 * Uses SIMD-optimized assembly implementation for maximum performance.
 *
 * @param vec Vector to normalize (modified in-place)
 * @param dimension Number of elements in vector
 *
 * @note Operation is in-place: original vector is modified
 * @note Zero vectors remain unchanged (no division by zero)
 * @note Performance: O(dimension), optimized with SIMD
 */
FASTEMBED_EXPORT void fastembed_normalize(float *vec, int dimension);

/**
 * @brief Add two vectors element-wise
 *
 * Performs element-wise addition: result[i] = vec1[i] + vec2[i]
 * for all i in [0, dimension-1].
 *
 * Uses SIMD-optimized assembly implementation for maximum performance.
 *
 * @param vec1 First vector (read-only)
 * @param vec2 Second vector (read-only)
 * @param result Output vector for result (must be pre-allocated, size >=
 * dimension)
 * @param dimension Number of elements in vectors (must match for all three)
 *
 * @note All vectors must have the same dimension
 * @note Result vector must be pre-allocated (not computed in-place)
 * @note Performance: O(dimension), optimized with SIMD
 */
FASTEMBED_EXPORT void fastembed_add_vectors(const float *vec1,
                                            const float *vec2, float *result,
                                            int dimension);

/**
 * @brief Generate embedding using ONNX Runtime model
 *
 * Loads a trained ONNX embedding model (e.g., BERT-based, nomic-embed-text)
 * and generates embeddings using neural network inference. This provides
 * learned semantic embeddings as opposed to hash-based embeddings.
 *
 * The function performs tokenization, runs ONNX inference, extracts the
 * [CLS] token embedding, and applies L2 normalization.
 *
 * **Performance Optimization:** The model session is cached in memory after
 * the first call. Subsequent calls with the same model_path reuse the cached
 * session, significantly improving performance (no model reload overhead).
 *
 * @param model_path Path to .onnx model file (must be readable)
 * @param text Input text to embed (null-terminated string, max 8192 chars)
 * @param output Output array for embedding vector (must be pre-allocated, size
 * >= dimension)
 * @param dimension Requested embedding dimension (must match model output, max
 * 2048). If 0, automatically detects dimension from model.
 * @return 0 on success, -1 on error (file not found, inference failure,
 * dimension mismatch, etc.)
 *
 * @note Requires ONNX Runtime to be installed and linked at compile time
 * @note Compile with -DUSE_ONNX_RUNTIME to enable ONNX support
 * @note Falls back to hash-based embedding if ONNX Runtime unavailable
 * @note Output embedding is L2-normalized (unit vector)
 * @note Model is cached after first load - use fastembed_onnx_unload() to free
 * memory
 * @note Dimension is automatically validated against model output
 * @note Use fastembed_onnx_get_model_dimension() to get model dimension before
 * calling this function
 */
FASTEMBED_EXPORT int fastembed_onnx_generate(const char *model_path,
                                             const char *text, float *output,
                                             int dimension);

/**
 * @brief Unload cached ONNX model session
 *
 * Frees the cached ONNX model session from memory. This can be useful to
 * free memory when done with a model, or to switch to a different model.
 *
 * After calling this function, the next call to fastembed_onnx_generate()
 * will automatically reload the model (no manual reload needed).
 *
 * @return 0 on success, -1 if ONNX Runtime not initialized or nothing to unload
 *
 * @note Safe to call even if no model is loaded (returns 0)
 * @note This function only affects the cached session, not ONNX Runtime itself
 */
FASTEMBED_EXPORT int fastembed_onnx_unload(void);

/**
 * @brief Get last error message from ONNX operations
 *
 * Returns the last error message that occurred during ONNX operations.
 * This provides detailed diagnostic information for debugging.
 *
 * @param error_buffer Output buffer for error message (must be at least 512
 * bytes)
 * @param buffer_size Size of error buffer
 * @return 0 on success (error message copied), -1 if no error message available
 *
 * @note Only available when compiled with USE_ONNX_RUNTIME
 * @note Error message is cleared on each new ONNX operation
 */
FASTEMBED_EXPORT int fastembed_onnx_get_last_error(char *error_buffer,
                                                   size_t buffer_size);

/**
 * @brief Get ONNX model output dimension
 *
 * Returns the output dimension of an ONNX embedding model. If the model is
 * already loaded (cached), returns the cached dimension immediately.
 * Otherwise, loads the model to detect the dimension.
 *
 * This function is useful to determine the correct dimension parameter before
 * calling fastembed_onnx_generate().
 *
 * @param model_path Path to .onnx model file (must be readable)
 * @return Model output dimension on success, -1 on error (model not found,
 * invalid model, dimension detection failed)
 *
 * @note The dimension is cached per model path for performance
 * @note Returns -1 if ONNX Runtime is not available
 * @note Use this function to validate dimension before calling
 * fastembed_onnx_generate()
 *
 * @example
 * ```c
 * int dim = fastembed_onnx_get_model_dimension("model.onnx");
 * if (dim > 0) {
 *   float *output = malloc(dim * sizeof(float));
 *   fastembed_onnx_generate("model.onnx", "text", output, dim);
 * }
 * ```
 */
FASTEMBED_EXPORT int fastembed_onnx_get_model_dimension(const char *model_path);

/**
 * @brief Generate embeddings for multiple texts in batch
 *
 * Processes an array of texts and generates embeddings for each one.
 * This function provides batching capability for efficient processing
 * of multiple texts at once using hash-based algorithm.
 *
 * The function processes texts sequentially. If any text fails to generate
 * an embedding, the function returns immediately with an error.
 *
 * @param texts Array of text strings (null-terminated) to embed
 * @param num_texts Number of texts in the array (must match outputs array size)
 * @param outputs Array of output arrays for embeddings (each must be
 * pre-allocated, size >= dimension)
 * @param dimension Embedding dimension (same for all texts). Supported
 * dimensions: 128, 256, 512, 768, 1024, 2048. If 0, uses default dimension 128.
 * @return 0 on success (all embeddings generated), -1 on error (validation or
 * generation failure)
 *
 * @note Arrays texts and outputs must have num_texts elements
 * @note Each output array must be pre-allocated with size >= dimension
 * @note On error, some embeddings may have been generated (partial results)
 * @note Supported dimensions: 128, 256, 512, 768, 1024, 2048
 * @note Uses hash-based embeddings (fastembed_generate) for all texts
 */
FASTEMBED_EXPORT int fastembed_batch_generate(const char **texts, int num_texts,
                                               float **outputs, int dimension);

#ifdef __cplusplus
}
#endif

#endif // FASTEMBED_H
