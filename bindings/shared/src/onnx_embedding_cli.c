/**
 * @file onnx_embedding_cli.c
 * @brief Command-line interface for ONNX embedding model inference
 *
 * This CLI tool provides a simple interface for generating text embeddings
 * using ONNX embedding models (e.g., BERT-based, nomic-embed-text) without
 * requiring external services like Ollama.
 *
 * Features:
 * - Direct ONNX model inference
 * - Input from stdin or command-line arguments
 * - JSON-formatted output for easy parsing
 * - Fallback to hash-based embedding if ONNX Runtime is unavailable
 *
 * Usage examples:
 * @code
 *   # From stdin
 *   echo "Hello world" | ./onnx_embedding_cli models/nomic-embed-text.onnx
 *
 *   # From command line
 *   ./onnx_embedding_cli models/nomic-embed-text.onnx "Hello world"
 *
 *   # Pipe from file
 *   cat input.txt | ./onnx_embedding_cli models/nomic-embed-text.onnx
 * @endcode
 *
 * Output format:
 * - Success: JSON array of floats: [0.123, -0.456, ...]
 * - Error: JSON error object: {"error":"Failed to generate embedding"}
 * - Warning: JSON warning object (if fallback used)
 *
 * Exit codes:
 * - 0: Success
 * - 1: Error (invalid arguments, failed inference, I/O error)
 */

#include "../include/fastembed_config.h"
#include "../include/fastembed_internal.h"
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef USE_ONNX_RUNTIME
/** Fallback to hash-based embedding if ONNX Runtime is not available */
#include "embedding_lib_c.h"
#endif

#define MAX_TEXT_LENGTH FASTEMBED_MAX_TEXT_LENGTH
#define EMBEDDING_DIM FASTEMBED_EMBEDDING_DIM

/**
 * @brief Main entry point for ONNX embedding CLI tool
 *
 * Processes command-line arguments, reads input text (from stdin or argv),
 * generates embedding using ONNX model or fallback method, and outputs
 * result as JSON array.
 *
 * Workflow:
 * 1. Validate command-line arguments (at least model path required)
 * 2. Read input text from command-line argument or stdin
 * 3. Generate embedding using ONNX model (or hash-based fallback)
 * 4. Output embedding vector as JSON array
 *
 * @param argc Number of command-line arguments
 * @param argv Command-line arguments array
 *              - argv[0]: Program name
 *              - argv[1]: Path to .onnx model file (required)
 *              - argv[2]: Optional text input (if not provided, reads from
 * stdin)
 * @return Exit code: 0 on success, 1 on error
 */
int main(int argc, char *argv[]) {
  /* Validate minimum argument count */
  if (argc < 2) {
    fprintf(stderr, "Usage: %s <model.onnx> [text]\n", argv[0]);
    fprintf(stderr, "   or: echo \"text\" | %s <model.onnx>\n", argv[0]);
    return 1;
  }

  /* Extract model path from arguments */
  const char *model_path = argv[1];
  char text_buffer[MAX_TEXT_LENGTH];
  float output[EMBEDDING_DIM];

  /* Read input text: prefer command-line argument, fallback to stdin */
  if (argc >= 3) {
    /* Text provided as command-line argument */
    strncpy(text_buffer, argv[2], sizeof(text_buffer) - 1);
    text_buffer[sizeof(text_buffer) - 1] = '\0';
  } else {
    /* Read text from stdin (supports piping and redirection) */
    if (fgets(text_buffer, sizeof(text_buffer), stdin) == NULL) {
      fprintf(stderr, "{\"error\":\"Failed to read input\"}\n");
      return 1;
    }

    /* Remove trailing newline character if present (from fgets) */
    size_t len = strlen(text_buffer);
    if (len > 0 && text_buffer[len - 1] == '\n') {
      text_buffer[len - 1] = '\0';
    }
  }

  /* Generate embedding using appropriate method */
  int result;

#ifdef USE_ONNX_RUNTIME
  /* Use ONNX Runtime for model inference */
  result =
      onnx_generate_embedding(model_path, text_buffer, output, EMBEDDING_DIM);
#else
  /* Fallback to hash-based embedding if ONNX Runtime is not compiled in */
  fprintf(stderr, "{\"warning\":\"ONNX Runtime not available, using hash-based "
                  "embedding\"}\n");
  result = generate_embedding(text_buffer, output, EMBEDDING_DIM);
#endif

  /* Check inference result */
  if (result != 0) {
    fprintf(stderr, "{\"error\":\"Failed to generate embedding\"}\n");
    return 1;
  }

  /* Output embedding as JSON array for easy parsing */
  /* Format: [0.123456, -0.789012, ...] */
  printf("[");
  for (int i = 0; i < EMBEDDING_DIM; i++) {
    printf("%.6f", output[i]);
    if (i < EMBEDDING_DIM - 1) {
      printf(",");
    }
  }
  printf("]\n");

  return 0;
}
