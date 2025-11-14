/**
 * @file embedding_lib_c.c
 * @brief C wrapper for assembly-based embedding operations
 *
 * This module provides a high-level C API for FastEmbed library, wrapping
 * low-level assembly-optimized vector operations and embedding generation.
 * It serves as the bridge between the public FastEmbed API and internal
 * assembly implementations.
 *
 * Features:
 * - FastEmbed API with consistent naming convention (fastembed_*)
 * - Legacy API for backwards compatibility
 * - Input validation and error handling
 * - Type-safe wrappers around assembly functions
 *
 * Architecture:
 * - FastEmbed API: New naming convention (fastembed_*)
 * - Legacy API: Old naming convention for backwards compatibility
 * - Assembly functions: Low-level SIMD-optimized operations
 *
 * @note All vector operations are optimized using SIMD instructions (SSE/AVX)
 * @note Embedding generation uses hash-based algorithm (assembly-optimized)
 * @note ONNX model support is available through onnx_embedding_loader.c
 */

#include "embedding_lib_c.h"
#include "../include/fastembed.h"
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/** External assembly function: dot product of two vectors (SIMD-optimized) */
extern float dot_product_asm(float *vector_a, float *vector_b, int dimension);
/** External assembly function: cosine similarity between two vectors
 * (SIMD-optimized) */
extern float cosine_similarity_asm(float *vector_a, float *vector_b,
                                   int dimension);
/** External assembly function: L2 norm of a vector (SIMD-optimized) */
extern float vector_norm_asm(float *vector, int dimension);
/** External assembly function: normalize vector in-place (SIMD-optimized) */
extern void normalize_vector_asm(float *vector, int dimension);
/** External assembly function: add two vectors element-wise (SIMD-optimized) */
extern void add_vectors_asm(float *vector_a, float *vector_b, float *result,
                            int dimension);
/** External assembly function: generate embedding from text (hash-based, legacy, 768D only) */
extern int generate_simple_embedding(const char *text, float *output);
/** External assembly function: generate improved embedding with dimension support */
extern int generate_embedding_improved_asm(const char *text, float *output, int dimension);
/** External assembly function: hash text to 64-bit value */
extern uint64_t simple_text_hash(const char *text, int text_length, int seed);

/**
 * @brief Check if dimension is valid (supported dimension)
 *
 * Valid dimensions: 128, 256, 512, 768, 1024, 2048
 *
 * @param dimension Dimension to validate
 * @return 1 if valid, 0 if invalid
 */
static int is_valid_dimension(int dimension) {
  return (dimension == 128 || dimension == 256 || dimension == 512 ||
          dimension == 768 || dimension == 1024 || dimension == 2048);
}

/**
 * @brief Generate text embedding using improved hash-based algorithm
 *
 * Converts input text into a fixed-size embedding vector using an improved
 * hash-based algorithm with Sin/Cos normalization and positional hashing.
 * The embedding is deterministic (same text always produces same embedding)
 * and suitable for similarity search.
 *
 * **BREAKING CHANGE (v1.0.1)**: Default dimension changed from 768 to 128.
 * If dimension is not specified or 0, the function uses 128 as default.
 * This improves performance while maintaining good quality for most use cases.
 *
 * Supported dimensions: 128, 256, 512, 768, 1024, 2048
 *
 * The improved algorithm uses:
 * - Positional hashing: Character position affects hash value
 * - Sin/Cos normalization: Better distribution in [-1, 1] range
 * - Combined hashing: Reduces collision probability
 *
 * @param text Input text to embed (null-terminated string, max 8192 chars)
 * @param output Output array for embedding vector (must be pre-allocated, size
 * >= dimension)
 * @param dimension Requested embedding dimension (128, 256, 512, 768, 1024, 2048).
 *                  If 0, uses default dimension 128.
 * @return 0 on success, -1 on error (invalid parameters or generation failure)
 *
 * @note This function uses hash-based embedding, not learned model embeddings.
 *       For ML model embeddings, use fastembed_onnx_generate() instead.
 * @note Default dimension is 128 (changed from 768 in v1.0.1)
 * @note Performance: ~0.01-0.05ms for 128D, ~0.05-0.15ms for 768D
 * @note For BERT compatibility, use dimension=768 explicitly
 */
int fastembed_generate(const char *text, float *output, int dimension) {
  /* Validate input parameters */
  if (!text || !output) {
    return -1;
  }

  /* Use default dimension if 0 is specified */
  if (dimension == 0) {
    dimension = 128; /* Default dimension (changed from 768 in v1.0.1) */
  }

  /* Validate dimension */
  if (dimension <= 0 || !is_valid_dimension(dimension)) {
    return -1;
  }

  /* Generate embedding using improved assembly-optimized function */
  int result = generate_embedding_improved_asm(text, output, dimension);

  if (result != 0) {
    return -1;
  }

  return 0;
}

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
float fastembed_dot_product(const float *vec1, const float *vec2,
                            int dimension) {
  if (!vec1 || !vec2 || dimension <= 0) {
    return 0.0f;
  }

  /* Try assembly version first (now fixed with proper ABI compliance) */
  return dot_product_asm((float *)vec1, (float *)vec2, dimension);
}

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
 * @param vec1 First vector (read-only)
 * @param vec2 Second vector (read-only)
 * @param dimension Number of elements in vectors (must match for both)
 * @return Cosine similarity (-1.0 to 1.0), or 0.0f on error (invalid
 * parameters)
 *
 * @note Returns 0.0f if either vector has zero norm (division by zero)
 * @note Performance: O(dimension), optimized with SIMD
 */
float fastembed_cosine_similarity(const float *vec1, const float *vec2,
                                  int dimension) {
  if (!vec1 || !vec2 || dimension <= 0) {
    return 0.0f;
  }

  /* Use assembly version (now fixed with proper ABI compliance and stack
   * alignment) */
  return cosine_similarity_asm((float *)vec1, (float *)vec2, dimension);
}

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
float fastembed_vector_norm(const float *vec, int dimension) {
  if (!vec || dimension <= 0) {
    return 0.0f;
  }

  /* Try assembly version first (now fixed with proper ABI compliance) */
  return vector_norm_asm((float *)vec, dimension);
}

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
void fastembed_normalize(float *vec, int dimension) {
  if (!vec || dimension <= 0) {
    return;
  }

  normalize_vector_asm(vec, dimension);
}

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
void fastembed_add_vectors(const float *vec1, const float *vec2, float *result,
                           int dimension) {
  if (!vec1 || !vec2 || !result || dimension <= 0) {
    return;
  }

  add_vectors_asm((float *)vec1, (float *)vec2, result, dimension);
}

/**
 * @brief Generate embedding using ONNX model
 *
 * Loads a trained ONNX embedding model and generates embeddings using
 * neural network inference. Falls back to hash-based embedding if
 * ONNX Runtime is not available.
 *
 * This function provides the interface for ONNX model inference, but
 * actual implementation is delegated to onnx_generate_embedding() in
 * onnx_embedding_loader.c when USE_ONNX_RUNTIME is defined.
 *
 * @param model_path Path to .onnx model file (must be readable)
 * @param text Input text to embed (null-terminated string)
 * @param output Output array for embedding vector (must be pre-allocated, size
 * >= dimension)
 * @param dimension Requested embedding dimension
 * @return 0 on success, -1 on error
 *
 * @note Currently falls back to hash-based embedding if ONNX Runtime
 * unavailable
 * @note For proper ONNX support, compile with -DUSE_ONNX_RUNTIME
 */
int fastembed_onnx_generate(const char *model_path, const char *text,
                            float *output, int dimension) {
  if (!model_path || !text || !output || dimension <= 0) {
    return -1;
  }

#ifdef USE_ONNX_RUNTIME
  /* Use ONNX Runtime for model-based embeddings */
  extern int onnx_generate_embedding(const char *model_path, const char *text,
                                     float *output, int output_dim);
  return onnx_generate_embedding(model_path, text, output, dimension);
#else
  /* Fallback to hash-based embedding if ONNX Runtime unavailable */
  return fastembed_generate(text, output, dimension);
#endif
}

int fastembed_onnx_unload(void) {
#ifdef USE_ONNX_RUNTIME
  extern int onnx_unload_model(void);
  return onnx_unload_model();
#else
  /* Nothing to unload if ONNX Runtime not available */
  return 0;
#endif
}

int fastembed_onnx_get_last_error(char *error_buffer, size_t buffer_size) {
#ifdef USE_ONNX_RUNTIME
  extern int onnx_get_last_error(char *error_buffer, size_t buffer_size);
  return onnx_get_last_error(error_buffer, buffer_size);
#else
  /* No error message available if ONNX Runtime not compiled */
  if (error_buffer && buffer_size > 0) {
    snprintf(error_buffer, buffer_size,
             "ONNX Runtime not available (not compiled with USE_ONNX_RUNTIME)");
  }
  return -1;
#endif
}

/**
 * @brief Generate embeddings for multiple texts in batch
 *
 * Processes an array of texts and generates embeddings for each one.
 * This function provides batching capability for efficient processing
 * of multiple texts at once.
 *
 * The function processes texts sequentially. If any text fails to generate
 * an embedding, the function returns immediately with an error.
 *
 * @param texts Array of text strings (null-terminated) to embed
 * @param num_texts Number of texts in the array (must match outputs array size)
 * @param outputs Array of output arrays for embeddings (each must be
 * pre-allocated, size >= dimension)
 * @param dimension Embedding dimension (same for all texts)
 * @return 0 on success (all embeddings generated), -1 on error (validation or
 * generation failure)
 *
 * @note Arrays texts and outputs must have num_texts elements
 * @note Each output array must be pre-allocated with size >= dimension
 * @note On error, some embeddings may have been generated (partial results)
 */
int fastembed_batch_generate(const char **texts, int num_texts, float **outputs,
                             int dimension) {
  if (!texts || !outputs || num_texts <= 0 || dimension <= 0) {
    return -1;
  }

  /* Process each text sequentially */
  for (int i = 0; i < num_texts; i++) {
    /* Validate current text and output pointers */
    if (!texts[i] || !outputs[i]) {
      return -1;
    }

    /* Generate embedding for current text */
    int result = fastembed_generate(texts[i], outputs[i], dimension);
    if (result != 0) {
      return -1;
    }
  }

  return 0;
}

/**
 * @brief Legacy API: Generate text embedding
 *
 * Backwards-compatible wrapper for fastembed_generate().
 * Maintained for compatibility with existing code.
 *
 * @deprecated Use fastembed_generate() instead
 */
int generate_embedding(const char *text, float *output, int dimension) {
  return fastembed_generate(text, output, dimension);
}

/**
 * @brief Legacy API: Calculate dot product
 * @deprecated Use fastembed_dot_product() instead
 */
float dot_product(float *vector_a, float *vector_b, int dimension) {
  return fastembed_dot_product(vector_a, vector_b, dimension);
}

/**
 * @brief Legacy API: Calculate cosine similarity
 * @deprecated Use fastembed_cosine_similarity() instead
 */
float cosine_similarity(float *vector_a, float *vector_b, int dimension) {
  return fastembed_cosine_similarity(vector_a, vector_b, dimension);
}

/**
 * @brief Legacy API: Calculate vector norm
 * @deprecated Use fastembed_vector_norm() instead
 */
float vector_norm(float *vector, int dimension) {
  return fastembed_vector_norm(vector, dimension);
}

/**
 * @brief Legacy API: Normalize vector
 * @deprecated Use fastembed_normalize() instead
 */
void normalize_vector(float *vector, int dimension) {
  fastembed_normalize(vector, dimension);
}

/**
 * @brief Legacy API: Add two vectors
 * @deprecated Use fastembed_add_vectors() instead
 */
void add_vectors(float *vector_a, float *vector_b, float *result,
                 int dimension) {
  fastembed_add_vectors(vector_a, vector_b, result, dimension);
}
