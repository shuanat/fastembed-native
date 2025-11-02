/**
 * @file embedding_gen_cli.c
 * @brief Command-line interface for hash-based embedding generation
 *
 * This CLI tool provides a simple interface for generating text embeddings
 * using the hash-based algorithm (assembly-optimized). It reads text from
 * stdin and outputs the embedding vector as a JSON array.
 *
 * Features:
 * - Hash-based embedding generation (deterministic)
 * - SIMD-optimized assembly implementation
 * - JSON-formatted output for easy parsing
 * - Stdin/stdout interface for shell integration
 *
 * Usage examples:
 * @code
 *   # From stdin
 *   echo "Hello world" | ./embedding_gen_cli
 *
 *   # From file
 *   cat document.txt | ./embedding_gen_cli
 *
 *   # Pipeline processing
 *   cat file1.txt file2.txt | ./embedding_gen_cli
 * @endcode
 *
 * Output format:
 * - Success: JSON array of floats: [0.123456, -0.789012, ...]
 * - Error: JSON error object: {"error":"Failed to generate embedding"}
 *
 * Exit codes:
 * - 0: Success
 * - 1: Error (I/O error, generation failure)
 *
 * @note This tool uses hash-based embeddings, not neural network models
 * @note For ONNX model embeddings, use onnx_embedding_cli instead
 * @note Embedding dimension is fixed at 768 (BERT-base size)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include "../include/fastembed_config.h"
#include "embedding_lib_c.h"

#define MAX_TEXT_LENGTH FASTEMBED_MAX_TEXT_LENGTH
#define EMBEDDING_DIM FASTEMBED_EMBEDDING_DIM

/**
 * @brief Main entry point for embedding generation CLI tool
 *
 * Processes text input from stdin, generates embedding using hash-based
 * algorithm, and outputs result as JSON array.
 *
 * Workflow:
 * 1. Read text from stdin (up to MAX_TEXT_LENGTH characters)
 * 2. Remove trailing newline character if present
 * 3. Generate embedding using hash-based algorithm (assembly-optimized)
 * 4. Output embedding vector as JSON array
 *
 * @param argc Number of command-line arguments (currently unused)
 * @param argv Command-line arguments array (currently unused)
 * @return Exit code: 0 on success, 1 on error
 *
 * @note Text is read from stdin, not command-line arguments
 * @note Empty input or read failure results in error
 * @note Output is always to stdout, errors to stderr
 */
int main(int argc, char *argv[])
{
    char text_buffer[MAX_TEXT_LENGTH];
    float output[EMBEDDING_DIM];

    /* Read text from stdin (supports piping and redirection) */
    if (fgets(text_buffer, sizeof(text_buffer), stdin) == NULL)
    {
        fprintf(stderr, "{\"error\":\"Failed to read input\"}\n");
        return 1;
    }

    /* Remove trailing newline character if present (added by fgets) */
    size_t len = strlen(text_buffer);
    if (len > 0 && text_buffer[len - 1] == '\n')
    {
        text_buffer[len - 1] = '\0';
    }

    /* Generate embedding using hash-based algorithm (assembly-optimized) */
    if (generate_embedding(text_buffer, output, EMBEDDING_DIM) != 0)
    {
        fprintf(stderr, "{\"error\":\"Failed to generate embedding\"}\n");
        return 1;
    }

    /* Output embedding as JSON array for easy parsing */
    /* Format: [0.123456, -0.789012, ...] */
    printf("[");
    for (int i = 0; i < EMBEDDING_DIM; i++)
    {
        printf("%.6f", output[i]);
        if (i < EMBEDDING_DIM - 1)
        {
            printf(",");
        }
    }
    printf("]\n");

    return 0;
}
