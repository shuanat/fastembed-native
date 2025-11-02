/**
 * @file embedding_lib_c.h
 * @brief Legacy C API header for backwards compatibility
 *
 * This header provides legacy function names for backwards compatibility
 * with existing code that uses the old API naming convention.
 *
 * **Recommendation**: New code should use `fastembed.h` instead, which provides
 * the same functionality with the `fastembed_*` naming convention.
 *
 * All functions in this header are wrappers that delegate to the FastEmbed API
 * functions defined in `fastembed.h`.
 *
 * @deprecated This header is maintained for backwards compatibility only.
 *             Use `fastembed.h` for new projects.
 *
 * @note All vector operations are SIMD-optimized using assembly instructions
 * @note Functions accept non-const pointers for backwards compatibility
 */

#ifndef EMBEDDING_LIB_C_H
#define EMBEDDING_LIB_C_H

#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

    /**
     * @brief Generate text embedding using hash-based algorithm (legacy API)
     *
     * Wrapper for fastembed_generate() providing backwards compatibility.
     * Generates a fixed-size embedding vector from input text using hash-based
     * algorithm optimized with SIMD instructions.
     *
     * @param text Input text to embed (null-terminated string)
     * @param output Output array for embedding vector (must be pre-allocated, size >= dimension)
     * @param dimension Requested embedding dimension (currently must be 768)
     * @return 0 on success, -1 on error (invalid parameters or generation failure)
     *
     * @deprecated Use fastembed_generate() instead
     *
     * @note Uses hash-based embedding, not learned model embeddings
     * @note Current limitation: only supports dimension=768
     */
    int generate_embedding(const char *text, float *output, int dimension);

    /**
     * @brief Calculate dot product of two vectors (legacy API)
     *
     * Wrapper for fastembed_dot_product() providing backwards compatibility.
     * Computes the dot product (inner product) of two vectors using SIMD-optimized
     * assembly implementation.
     *
     * @param vector_a First vector
     * @param vector_b Second vector
     * @param dimension Number of elements in vectors (must match for both)
     * @return Dot product result, or 0.0f on error (invalid parameters)
     *
     * @deprecated Use fastembed_dot_product() instead
     *
     * @note Vectors must have the same dimension
     * @note Performance: O(dimension), optimized with SIMD
     */
    float dot_product(float *vector_a, float *vector_b, int dimension);

    /**
     * @brief Calculate cosine similarity between two vectors (legacy API)
     *
     * Wrapper for fastembed_cosine_similarity() providing backwards compatibility.
     * Computes cosine similarity (normalized dot product) between two vectors.
     *
     * @param vector_a First vector
     * @param vector_b Second vector
     * @param dimension Number of elements in vectors (must match for both)
     * @return Cosine similarity (-1.0 to 1.0), or 0.0f on error
     *
     * @deprecated Use fastembed_cosine_similarity() instead
     *
     * @note Returns 0.0f if either vector has zero norm (division by zero)
     * @note Performance: O(dimension), optimized with SIMD
     */
    float cosine_similarity(float *vector_a, float *vector_b, int dimension);

    /**
     * @brief Calculate L2 (Euclidean) norm of a vector (legacy API)
     *
     * Wrapper for fastembed_vector_norm() providing backwards compatibility.
     * Computes the Euclidean norm (magnitude) of a vector.
     *
     * @param vector Input vector
     * @param dimension Number of elements in vector
     * @return L2 norm (always >= 0.0), or 0.0f on error
     *
     * @deprecated Use fastembed_vector_norm() instead
     *
     * @note Zero vector returns 0.0 norm
     * @note Performance: O(dimension), optimized with SIMD
     */
    float vector_norm(float *vector, int dimension);

    /**
     * @brief Normalize vector to unit length (legacy API)
     *
     * Wrapper for fastembed_normalize() providing backwards compatibility.
     * Normalizes vector in-place to unit length by dividing each element by the
     * vector's L2 norm.
     *
     * @param vector Vector to normalize (modified in-place)
     * @param dimension Number of elements in vector
     *
     * @deprecated Use fastembed_normalize() instead
     *
     * @note Operation is in-place: original vector is modified
     * @note Zero vectors remain unchanged (no division by zero)
     * @note Performance: O(dimension), optimized with SIMD
     */
    void normalize_vector(float *vector, int dimension);

    /**
     * @brief Add two vectors element-wise (legacy API)
     *
     * Wrapper for fastembed_add_vectors() providing backwards compatibility.
     * Performs element-wise addition: result[i] = vector_a[i] + vector_b[i]
     *
     * @param vector_a First vector
     * @param vector_b Second vector
     * @param result Output vector for result (must be pre-allocated, size >= dimension)
     * @param dimension Number of elements in vectors (must match for all three)
     *
     * @deprecated Use fastembed_add_vectors() instead
     *
     * @note All vectors must have the same dimension
     * @note Result vector must be pre-allocated (not computed in-place)
     * @note Performance: O(dimension), optimized with SIMD
     */
    void add_vectors(float *vector_a, float *vector_b, float *result, int dimension);

#ifdef __cplusplus
}
#endif

#endif // EMBEDDING_LIB_C_H
