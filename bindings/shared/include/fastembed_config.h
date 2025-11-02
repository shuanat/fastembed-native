/**
 * @file fastembed_config.h
 * @brief FastEmbed library configuration constants
 *
 * This file contains all configuration constants used across FastEmbed library.
 * Centralizing constants here ensures consistency and makes it easy to adjust
 * limits and sizes across the entire project.
 *
 * All constants are defined with clear documentation about their purpose and usage.
 */

#ifndef FASTEMBED_CONFIG_H
#define FASTEMBED_CONFIG_H

/** Maximum vector dimension supported across all operations */
#define FASTEMBED_MAX_DIMENSION 2048

/** Maximum text input length in characters (unified across all CLI tools) */
#define FASTEMBED_MAX_TEXT_LENGTH 8192

/** Default embedding dimension (BERT-base hidden size) */
#define FASTEMBED_EMBEDDING_DIM 768

/** Maximum ONNX model output dimension */
#define FASTEMBED_MAX_OUTPUT_DIM 2048

/** Maximum sequence length for tokenization (BERT-like models) */
#define FASTEMBED_MAX_SEQUENCE_LENGTH 8192

/** Maximum JSON input buffer size in characters (for CLI tools) */
#define FASTEMBED_JSON_BUFFER_SIZE 65536

/** Vocabulary size for tokenization (BERT base) */
#define FASTEMBED_VOCAB_SIZE 30528

#endif // FASTEMBED_CONFIG_H
