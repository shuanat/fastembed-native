/**
 * @file vector_ops_cli.c
 * @brief Command-line interface for vector operations using SIMD-optimized assembly
 *
 * This CLI tool provides a simple interface for performing vector operations
 * (dot product, cosine similarity, norm, normalize) on embedding vectors.
 * It reads JSON input from stdin and outputs results as JSON.
 *
 * Features:
 * - SIMD-optimized vector operations (SSE/AVX)
 * - JSON-based input/output for easy integration
 * - Supports multiple operations: cosine, dot, norm, normalize
 * - Assembly-optimized backend for maximum performance
 *
 * Supported operations:
 * - "cosine": Cosine similarity between two vectors
 * - "dot": Dot product of two vectors
 * - "norm": L2 norm (magnitude) of a vector
 * - "normalize": Normalize vector to unit length (in-place)
 *
 * Usage examples:
 * @code
 *   # Cosine similarity
 *   echo '{"op":"cosine","vec1":[1,2,3],"vec2":[4,5,6],"dim":3}' | ./vector_ops_cli
 *
 *   # Dot product
 *   echo '{"op":"dot","vec1":[1,2,3],"vec2":[4,5,6],"dim":3}' | ./vector_ops_cli
 *
 *   # Vector norm
 *   echo '{"op":"norm","vec1":[3,4,0],"dim":3}' | ./vector_ops_cli
 *
 *   # Normalize vector
 *   echo '{"op":"normalize","vec1":[3,4,0],"dim":3}' | ./vector_ops_cli
 * @endcode
 *
 * Input format:
 * - JSON object with fields: "op" (operation name), "vec1" (array), "vec2" (optional array), "dim" (dimension)
 * - Dimension can be omitted if vec1 array is provided (will be auto-detected)
 *
 * Output format:
 * - Success: JSON object with "result" field (scalar for cosine/dot/norm, array for normalize)
 * - Error: JSON object with "error" field containing error message
 *
 * Exit codes:
 * - 0: Success
 * - 1: Error (I/O error, invalid format, unknown operation)
 *
 * @note This tool uses a simplified JSON parser. For production use, consider cJSON library.
 * @note All vector operations are SIMD-optimized using assembly instructions.
 * @note Maximum vector dimension is 2048.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include "../include/fastembed_config.h"
#include "embedding_lib_c.h"

#define MAX_DIMENSION FASTEMBED_MAX_DIMENSION
#define JSON_BUFFER_SIZE FASTEMBED_JSON_BUFFER_SIZE

/**
 * @brief Parse simplified JSON input for vector operations
 *
 * Parses a simplified JSON format to extract operation type, vectors, and dimension.
 * This is a basic parser suitable for CLI usage. For production applications,
 * use a proper JSON library like cJSON.
 *
 * Input JSON format:
 * @code
 * {
 *   "op": "cosine|dot|norm|normalize",
 *   "vec1": [1.0, 2.0, 3.0, ...],
 *   "vec2": [4.0, 5.0, 6.0, ...],  // Optional, only for cosine/dot
 *   "dim": 3  // Optional, auto-detected from vec1 if omitted
 * }
 * @endcode
 *
 * Parsing algorithm:
 * 1. Extract "op" field (operation name)
 * 2. Extract "dim" field (dimension, if specified)
 * 3. Extract "vec1" array (required for all operations)
 * 4. Extract "vec2" array (required only for cosine/dot operations)
 * 5. Auto-detect dimension from vec1 if not specified
 *
 * @param json Input JSON string (modified in-place during parsing)
 * @param op Output buffer for operation name (must be at least 32 chars)
 * @param vec1 Output array for first vector (must be pre-allocated, size >= MAX_DIMENSION)
 * @param vec2 Output array for second vector (must be pre-allocated, size >= MAX_DIMENSION)
 * @param dim Output parameter for vector dimension (also used as input if > 0)
 * @return 0 on success, -1 on error (invalid format, dimension out of range)
 *
 * @note This is a simplified parser that doesn't handle all JSON edge cases
 * @note Whitespace handling is basic (may fail on complex JSON)
 * @note Dimension must be between 1 and MAX_DIMENSION
 */
int parse_json_simple(char *json, char *op, float *vec1, float *vec2, int *dim)
{
    /* Initialize output parameters */
    *dim = 0;
    op[0] = '\0';

    /* Extract "op" field: look for "op":"value" pattern */
    char *op_start = strstr(json, "\"op\"");
    if (op_start)
    {
        char *colon = strchr(op_start, ':');
        if (colon)
        {
            char *quote1 = strchr(colon, '"');
            if (quote1)
            {
                quote1++; /* Skip opening quote */
                char *quote2 = strchr(quote1, '"');
                if (quote2)
                {
                    int len = quote2 - quote1;
                    if (len > 0 && len < 32)
                    {
                        strncpy(op, quote1, len);
                        op[len] = '\0';
                    }
                }
            }
        }
    }

    /* Extract "dim" field: look for "dim":number pattern */
    char *dim_start = strstr(json, "\"dim\"");
    if (dim_start)
    {
        *dim = atoi(dim_start + 5); /* Skip past "dim": */
    }

    /* Extract "vec1" array: look for "vec1":[1,2,3,...] pattern */
    char *vec1_start = strstr(json, "\"vec1\"");
    if (vec1_start)
    {
        char *array_start = strchr(vec1_start, '[');
        if (array_start)
        {
            array_start++; /* Skip '[' */
            char *array_end = strchr(array_start, ']');
            if (array_end)
            {
                /* Parse comma-separated floating-point numbers */
                int count = 0;
                char *num_start = array_start;
                while (num_start < array_end && count < MAX_DIMENSION)
                {
                    vec1[count] = strtof(num_start, &num_start);
                    count++;
                    if (*num_start == ',')
                        num_start++; /* Skip comma */
                }
                /* Auto-detect dimension from vec1 if not explicitly specified */
                if (*dim == 0)
                    *dim = count;
            }
        }
    }

    /* Extract "vec2" array: only needed for cosine similarity and dot product */
    if (strcmp(op, "cosine") == 0 || strcmp(op, "dot") == 0)
    {
        char *vec2_start = strstr(json, "\"vec2\"");
        if (vec2_start)
        {
            char *array_start = strchr(vec2_start, '[');
            if (array_start)
            {
                array_start++; /* Skip '[' */
                char *array_end = strchr(array_start, ']');
                if (array_end)
                {
                    /* Parse comma-separated floating-point numbers */
                    int count = 0;
                    char *num_start = array_start;
                    while (num_start < array_end && count < MAX_DIMENSION)
                    {
                        vec2[count] = strtof(num_start, &num_start);
                        count++;
                        if (*num_start == ',')
                            num_start++; /* Skip comma */
                    }
                }
            }
        }
    }

    /* Validate dimension: must be positive and within limits */
    return (*dim > 0 && *dim <= MAX_DIMENSION) ? 0 : -1;
}

/**
 * @brief Main entry point for vector operations CLI tool
 *
 * Processes JSON input from stdin, parses operation and vectors, executes
 * the requested vector operation using SIMD-optimized assembly functions,
 * and outputs result as JSON.
 *
 * Workflow:
 * 1. Read JSON input from stdin (up to JSON_BUFFER_SIZE characters)
 * 2. Parse JSON to extract operation, vectors, and dimension
 * 3. Validate input (operation type, vector dimensions)
 * 4. Execute operation using assembly-optimized functions
 * 5. Output result as JSON (scalar for cosine/dot/norm, array for normalize)
 *
 * @param argc Number of command-line arguments (currently unused)
 * @param argv Command-line arguments array (currently unused)
 * @return Exit code: 0 on success, 1 on error
 *
 * @note Input is read from stdin, not command-line arguments
 * @note Output is always to stdout, errors to stderr
 * @note All operations are SIMD-optimized using assembly code
 */
int main(int argc, char *argv[])
{
    char buffer[JSON_BUFFER_SIZE];
    char op[32] = {0};
    float vec1[MAX_DIMENSION] = {0};
    float vec2[MAX_DIMENSION] = {0};
    int dim = 0;

    /* Read JSON input from stdin (supports piping and redirection) */
    if (fgets(buffer, sizeof(buffer), stdin) == NULL)
    {
        fprintf(stderr, "{\"error\":\"Failed to read input\"}\n");
        return 1;
    }

    /* Parse JSON input to extract operation, vectors, and dimension */
    if (parse_json_simple(buffer, op, vec1, vec2, &dim) != 0)
    {
        fprintf(stderr, "{\"error\":\"Invalid input format\"}\n");
        return 1;
    }

    /* Execute requested operation using SIMD-optimized assembly functions */
    if (strcmp(op, "cosine") == 0)
    {
        /* Cosine similarity: (vec1 · vec2) / (||vec1|| * ||vec2||) */
        float result = cosine_similarity(vec1, vec2, dim);
        printf("{\"result\":%.6f}\n", result);
    }
    else if (strcmp(op, "dot") == 0)
    {
        /* Dot product: vec1 · vec2 = Σ(vec1[i] * vec2[i]) */
        float result = dot_product(vec1, vec2, dim);
        printf("{\"result\":%.6f}\n", result);
    }
    else if (strcmp(op, "norm") == 0)
    {
        /* L2 norm: ||vec1|| = sqrt(Σ(vec1[i]²)) */
        float result = vector_norm(vec1, dim);
        printf("{\"result\":%.6f}\n", result);
    }
    else if (strcmp(op, "normalize") == 0)
    {
        /* Normalize vector to unit length: vec1 = vec1 / ||vec1|| */
        normalize_vector(vec1, dim);
        /* Output normalized vector as JSON array */
        printf("{\"result\":[");
        for (int i = 0; i < dim; i++)
        {
            printf("%.6f", vec1[i]);
            if (i < dim - 1)
                printf(",");
        }
        printf("]}\n");
    }
    else
    {
        fprintf(stderr, "{\"error\":\"Unknown operation: %s\"}\n", op);
        return 1;
    }

    return 0;
}
