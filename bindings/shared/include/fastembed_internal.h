/**
 * @file fastembed_internal.h
 * @brief FastEmbed Internal Functions (for testing and CLI tools only)
 *
 * This header exposes internal low-level assembly functions for testing
 * and debugging purposes. These functions are NOT part of the public API
 * and should NOT be used in production code.
 *
 * **WARNING:** These functions may change or be removed without notice.
 * Use the public API in fastembed.h instead.
 *
 * Copyright (c) 2024 FastEmbed Contributors
 * MIT License
 */

#ifndef FASTEMBED_INTERNAL_H
#define FASTEMBED_INTERNAL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Internal hash functions from embedding_generator.asm
/**
 * @brief Positional hash function (internal)
 * @param text Input text
 * @param text_length Length of text
 * @param seed Hash seed
 * @return 64-bit hash value
 */
uint64_t positional_hash_asm(const char *text, int text_length, int seed);

/**
 * @brief Convert hash to float using square root normalization (internal)
 * @param hash 64-bit hash value
 * @return Normalized float in range [-1, 1]
 *
 * Algorithm: sqrt((hash / 2^31)) * 2 - 1
 * Quality: Typo tolerance 0.40+, reorder sensitivity 0.23+
 */
float hash_to_float_sqrt_asm(uint64_t hash);

/**
 * @brief Generate combined hash (internal)
 * @param text Input text
 * @param text_length Length of text
 * @param seed Hash seed
 * @return 64-bit combined hash value
 */
uint64_t generate_combined_hash_asm(const char *text, int text_length,
                                    int seed);

// Internal low-level functions from embedding_lib.asm
/**
 * @brief Generate embedding (internal, low-level version)
 * @param text Input text
 * @param output Output embedding vector
 * @param dimension Embedding dimension
 * @return 0 on success, -1 on error
 */
int generate_embedding(const char *text, float *output, int dimension);

/**
 * @brief ONNX embedding generation (internal, low-level version)
 * @param model_path Path to ONNX model file
 * @param text Input text
 * @param output Output embedding vector
 * @param dimension Embedding dimension
 * @return 0 on success, -1 on error
 */
int onnx_generate_embedding(const char *model_path, const char *text,
                            float *output, int dimension);

/**
 * @brief Dot product (internal, low-level version)
 * @param vec1 First vector
 * @param vec2 Second vector
 * @param dimension Vector dimension
 * @return Dot product value
 */
float dot_product_asm(const float *vec1, const float *vec2, int dimension);

/**
 * @brief Cosine similarity (internal, low-level version)
 * @param vec1 First vector
 * @param vec2 Second vector
 * @param dimension Vector dimension
 * @return Cosine similarity value
 */
float cosine_similarity_asm(const float *vec1, const float *vec2,
                            int dimension);

/**
 * @brief Vector norm (internal, low-level version)
 * @param vec Input vector
 * @param dimension Vector dimension
 * @return L2 norm value
 */
float vector_norm_asm(const float *vec, int dimension);

/**
 * @brief Normalize vector (internal, low-level version)
 * @param vec Input/output vector
 * @param dimension Vector dimension
 */
void normalize_vector_asm(float *vec, int dimension);

// Convenience aliases without _asm suffix for CLI tools
#define dot_product dot_product_asm
#define cosine_similarity cosine_similarity_asm
#define vector_norm vector_norm_asm
#define normalize_vector normalize_vector_asm

#ifdef __cplusplus
}
#endif

#endif /* FASTEMBED_INTERNAL_H */
