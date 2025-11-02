/**
 * @file onnx_embedding_loader.c
 * @brief ONNX Runtime integration for embedding models (REFACTORED - Standard C API with Caching)
 *
 * This module provides functionality to load ONNX embedding models (e.g., BERT-based,
 * nomic-embed-text) and generate text embeddings directly using ONNX Runtime.
 *
 * Features:
 * - Direct ONNX model loading and inference using standard C API
 * - **Model session caching**: Models are loaded once and reused across multiple calls
 * - Simplified tokenization for BERT-like models
 * - Automatic tensor creation and management
 * - L2 normalization of output embeddings
 *
 * Performance:
 * - First call with a model: loads model into memory (~100-500ms depending on model size)
 * - Subsequent calls: reuse cached session (no reload overhead)
 * - Automatic model switching: if different model_path is provided, previous model is unloaded
 *
 * Requires: ONNX Runtime C API (libonnxruntime.so / onnxruntime.dll)
 */

#ifdef USE_ONNX_RUNTIME

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <ctype.h>
#include <limits.h>
#include <unistd.h>

#include <onnxruntime_c_api.h>
#include "../include/fastembed_config.h"

#define MAX_TEXT_LENGTH FASTEMBED_MAX_TEXT_LENGTH
#define MAX_OUTPUT_DIM FASTEMBED_MAX_OUTPUT_DIM
#define MAX_SEQUENCE_LENGTH FASTEMBED_MAX_SEQUENCE_LENGTH
#define VOCAB_SIZE FASTEMBED_VOCAB_SIZE
#define MAX_MODEL_PATH 512

/**
 * @brief Global ONNX Runtime API instance
 *
 * Using standard API pattern - store const OrtApi* pointer
 */
static const OrtApi *g_ort = NULL;

/**
 * @brief Cached model session structure
 *
 * Stores loaded ONNX model session and related resources for reuse.
 */
typedef struct
{
    char model_path[MAX_MODEL_PATH];    /* Resolved path to model file */
    OrtEnv *env;                        /* ONNX environment (singleton) */
    OrtMemoryInfo *memory_info;         /* CPU memory info */
    OrtSessionOptions *session_options; /* Session options */
    OrtSession *session;                /* Loaded session */
    OrtAllocator *allocator;            /* Allocator for names */
    char *output_name;                  /* Cached output name */
    int is_loaded;                      /* Flag: is session loaded */
} CachedModelSession;

/**
 * @brief Global cached session (single model support)
 *
 * For multiple models, this could be extended to a hash table or array.
 */
static CachedModelSession g_cached_session = {0};

/**
 * @brief Initialize ONNX Runtime API (standard approach)
 *
 * Gets the API base and retrieves the API structure.
 *
 * @return 0 on success, -1 on error
 */
static int init_onnx_api(void)
{
    if (g_ort != NULL)
    {
        return 0; // Already initialized
    }

    const OrtApiBase *api_base = OrtGetApiBase();
    if (api_base == NULL)
    {
        fprintf(stderr, "ERROR: OrtGetApiBase() returned NULL\n");
        return -1;
    }

    g_ort = api_base->GetApi(ORT_API_VERSION);
    if (g_ort == NULL)
    {
        fprintf(stderr, "ERROR: GetApi() returned NULL\n");
        return -1;
    }

    return 0;
}

/**
 * @brief Helper macro to check ORT status and handle errors
 */
#define CHECK_ORT_STATUS(expr)                                \
    do                                                        \
    {                                                         \
        OrtStatus *status = (expr);                           \
        if (status != NULL)                                   \
        {                                                     \
            const char *msg = g_ort->GetErrorMessage(status); \
            fprintf(stderr, "ONNX Runtime Error: %s\n", msg); \
            g_ort->ReleaseStatus(status);                     \
            goto cleanup;                                     \
        }                                                     \
    } while (0)

/**
 * @brief Load or retrieve cached ONNX model session
 *
 * If model is already loaded (same path), returns cached session.
 * Otherwise, loads the model and caches it for future use.
 *
 * @param model_path Path to .onnx model file
 * @param cached Pointer to cached session structure
 * @return 0 on success, -1 on error
 */
static int load_or_get_cached_session(const char *model_path, CachedModelSession *cached)
{
    char resolved_path[PATH_MAX];

    /* Resolve model path */
    if (realpath(model_path, resolved_path) == NULL)
    {
        fprintf(stderr, "Model file not found: %s\n", model_path);
        return -1;
    }

    /* Check if same model is already loaded */
    if (cached->is_loaded && strcmp(cached->model_path, resolved_path) == 0)
    {
        return 0; /* Already loaded, reuse */
    }

    /* Unload previous model if different */
    if (cached->is_loaded)
    {
        if (cached->output_name && cached->allocator)
        {
            cached->allocator->Free(cached->allocator, cached->output_name);
            cached->output_name = NULL;
        }
        if (cached->session)
            g_ort->ReleaseSession(cached->session);
        if (cached->session_options)
            g_ort->ReleaseSessionOptions(cached->session_options);
        if (cached->memory_info)
            g_ort->ReleaseMemoryInfo(cached->memory_info);
        /* Note: env is singleton, don't release it */

        memset(cached, 0, sizeof(CachedModelSession));
    }

    /* Create or get environment (singleton) */
    if (cached->env == NULL)
    {
        CHECK_ORT_STATUS(g_ort->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "FastEmbed", &cached->env));
    }

    /* Create CPU memory info */
    CHECK_ORT_STATUS(g_ort->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &cached->memory_info));

    /* Create session options */
    CHECK_ORT_STATUS(g_ort->CreateSessionOptions(&cached->session_options));

    /* Create session from file */
    CHECK_ORT_STATUS(g_ort->CreateSession(cached->env, resolved_path, cached->session_options, &cached->session));

    /* Get allocator */
    CHECK_ORT_STATUS(g_ort->GetAllocatorWithDefaultOptions(&cached->allocator));

    /* Get output name (cache it) */
    size_t num_output_nodes = 0;
    CHECK_ORT_STATUS(g_ort->SessionGetOutputCount(cached->session, &num_output_nodes));

    if (num_output_nodes > 0)
    {
        CHECK_ORT_STATUS(g_ort->SessionGetOutputName(cached->session, 0, cached->allocator, &cached->output_name));
    }

    if (cached->output_name == NULL)
    {
        fprintf(stderr, "Failed to get output name from model\n");
        return -1;
    }

    /* Save resolved path and mark as loaded */
    strncpy(cached->model_path, resolved_path, MAX_MODEL_PATH - 1);
    cached->model_path[MAX_MODEL_PATH - 1] = '\0';
    cached->is_loaded = 1;

    return 0;

cleanup:
    /* Cleanup on error */
    if (cached->session)
    {
        g_ort->ReleaseSession(cached->session);
        cached->session = NULL;
    }
    if (cached->session_options)
    {
        g_ort->ReleaseSessionOptions(cached->session_options);
        cached->session_options = NULL;
    }
    if (cached->memory_info)
    {
        g_ort->ReleaseMemoryInfo(cached->memory_info);
        cached->memory_info = NULL;
    }
    return -1;
}

/**
 * @brief Simple tokenization (word-based with hash for IDs)
 *
 * Converts text into token IDs using a simple word-based tokenization strategy.
 * This is a placeholder for proper tokenization (e.g., WordPiece, BPE).
 *
 * @param text Input text to tokenize
 * @param token_ids Output array of token IDs (must be pre-allocated)
 * @param max_length Maximum sequence length
 * @return Number of tokens generated, or -1 on error
 */
static int simple_tokenize(const char *text, int64_t *token_ids, int max_length)
{
    if (text == NULL || token_ids == NULL || max_length <= 0)
        return -1;

    int token_count = 0;
    token_ids[token_count++] = 101; /* [CLS] token ID */

    /* Simple word-based tokenization */
    const char *p = text;
    int word_start = 1;
    uint32_t hash = 0;

    for (int i = 0; p[i] != '\0' && token_count < max_length - 1; i++)
    {
        if (isspace((unsigned char)p[i]) || ispunct((unsigned char)p[i]))
        {
            if (!word_start && token_count < max_length - 1)
            {
                /* Map hash to vocabulary ID (simple modulo) */
                int64_t token_id = (hash % VOCAB_SIZE);
                if (token_id < 100) /* Skip special tokens */
                    token_id += 100;
                token_ids[token_count++] = token_id;
                hash = 0;
            }
            word_start = 1;
        }
        else
        {
            hash = hash * 31 + (unsigned char)tolower((unsigned char)p[i]);
            word_start = 0;
        }
    }

    /* Add final token if we have a word in progress */
    if (!word_start && token_count < max_length - 1)
    {
        int64_t token_id = (hash % VOCAB_SIZE);
        if (token_id < 100)
            token_id += 100;
        token_ids[token_count++] = token_id;
    }

    /* Add [SEP] token at end */
    if (token_count < max_length)
        token_ids[token_count++] = 102; /* [SEP] token ID */

    return token_count;
}

/**
 * @brief L2 normalize vector in-place
 *
 * Divides each element by the L2 norm, making the vector unit length.
 *
 * @param vec Vector to normalize (modified in-place)
 * @param dim Dimension of vector
 */
static void normalize_l2(float *vec, int dim)
{
    if (vec == NULL || dim <= 0)
        return;

    /* Calculate L2 norm */
    double norm = 0.0;
    for (int i = 0; i < dim; i++)
        norm += (double)vec[i] * (double)vec[i];
    norm = sqrt(norm);

    /* Normalize if norm > 0 */
    if (norm > 1e-8)
    {
        float inv_norm = 1.0f / (float)norm;
        for (int i = 0; i < dim; i++)
            vec[i] *= inv_norm;
    }
}

/**
 * @brief Generate embedding using ONNX Runtime model (STANDARD C API)
 *
 * Loads an ONNX embedding model and generates embeddings for the input text.
 * The function performs tokenization, runs inference, extracts the [CLS] token
 * embedding, and normalizes the result.
 *
 * @param model_path Path to .onnx model file
 * @param text Input text to embed (null-terminated string)
 * @param output Output array for embedding vector (must be pre-allocated)
 * @param output_dim Requested output dimension (must match model output)
 * @return 0 on success, -1 on error
 */
int onnx_generate_embedding(
    const char *model_path,
    const char *text,
    float *output,
    int output_dim)
{
    /* Validate inputs */
    if (!model_path || !text || !output || output_dim <= 0 || output_dim > MAX_OUTPUT_DIM)
    {
        fprintf(stderr, "Invalid input parameters\n");
        return -1;
    }

    /* Initialize ONNX Runtime API */
    if (init_onnx_api() != 0)
    {
        fprintf(stderr, "Failed to initialize ONNX Runtime API\n");
        return -1;
    }

    /* Load or get cached session */
    if (load_or_get_cached_session(model_path, &g_cached_session) != 0)
    {
        fprintf(stderr, "Failed to load model session\n");
        return -1;
    }

    /* Use cached session resources */
    OrtSession *session = g_cached_session.session;
    OrtMemoryInfo *memory_info = g_cached_session.memory_info;
    const char *output_name = g_cached_session.output_name;

    OrtValue *input_tensor = NULL;
    OrtValue *token_type_tensor = NULL;
    OrtValue *attention_mask_tensor = NULL;
    OrtValue *output_tensor = NULL;

    int result = -1;

    /* Tokenize input text */
    int64_t input_ids[MAX_SEQUENCE_LENGTH];
    int sequence_length = simple_tokenize(text, input_ids, MAX_SEQUENCE_LENGTH);
    if (sequence_length < 0)
    {
        fprintf(stderr, "Failed to tokenize text\n");
        goto cleanup;
    }

    /* Create token_type_ids (all zeros for single sequence) */
    int64_t token_type_ids[MAX_SEQUENCE_LENGTH];
    memset(token_type_ids, 0, sequence_length * sizeof(int64_t));

    /* Create attention_mask (all ones) */
    int64_t attention_mask_arr[MAX_SEQUENCE_LENGTH];
    for (int i = 0; i < sequence_length; i++)
        attention_mask_arr[i] = 1;

    /* Prepare input arrays */
    const char *input_names[3] = {"input_ids", "token_type_ids", "attention_mask"};
    const OrtValue *inputs[3];
    size_t actual_input_count = 3;

    /* Create input tensors */
    int64_t input_shape[2] = {1, sequence_length};

    CHECK_ORT_STATUS(g_ort->CreateTensorWithDataAsOrtValue(
        memory_info, input_ids, sequence_length * sizeof(int64_t),
        input_shape, 2, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &input_tensor));

    CHECK_ORT_STATUS(g_ort->CreateTensorWithDataAsOrtValue(
        memory_info, token_type_ids, sequence_length * sizeof(int64_t),
        input_shape, 2, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &token_type_tensor));

    CHECK_ORT_STATUS(g_ort->CreateTensorWithDataAsOrtValue(
        memory_info, attention_mask_arr, sequence_length * sizeof(int64_t),
        input_shape, 2, ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, &attention_mask_tensor));

    /* Populate input arrays */
    inputs[0] = input_tensor;
    inputs[1] = token_type_tensor;
    inputs[2] = attention_mask_tensor;

    /* Run inference using standard API */
    const char *output_names_arr[1] = {output_name};
    CHECK_ORT_STATUS(g_ort->Run(session, NULL, input_names, inputs, actual_input_count,
                                output_names_arr, 1, &output_tensor));

    if (output_tensor == NULL)
    {
        fprintf(stderr, "Inference failed: output tensor is NULL\n");
        goto cleanup;
    }

    /* Extract embeddings from output tensor */
    float *output_data = NULL;
    CHECK_ORT_STATUS(g_ort->GetTensorMutableData(output_tensor, (void **)&output_data));

    /* Extract [CLS] token embedding (first token) */
    if (output_dim <= MAX_OUTPUT_DIM)
    {
        memcpy(output, output_data, output_dim * sizeof(float));
        normalize_l2(output, output_dim);
    }

    result = 0;

cleanup:
    /* Cleanup only tensor values (session resources are cached) */
    if (input_tensor)
        g_ort->ReleaseValue(input_tensor);
    if (token_type_tensor)
        g_ort->ReleaseValue(token_type_tensor);
    if (attention_mask_tensor)
        g_ort->ReleaseValue(attention_mask_tensor);
    if (output_tensor)
        g_ort->ReleaseValue(output_tensor);

    return result;
}

/**
 * @brief Unload cached model session
 *
 * Frees all cached resources. Can be called to free memory when done with model.
 * Subsequent calls will reload the model automatically.
 *
 * @return 0 on success, -1 if not initialized
 */
int onnx_unload_model(void)
{
    if (g_ort == NULL)
    {
        return -1;
    }

    if (!g_cached_session.is_loaded)
    {
        return 0; /* Nothing to unload */
    }

    /* Free cached resources */
    if (g_cached_session.output_name && g_cached_session.allocator)
    {
        g_cached_session.allocator->Free(g_cached_session.allocator, g_cached_session.output_name);
        g_cached_session.output_name = NULL;
    }

    if (g_cached_session.session)
    {
        g_ort->ReleaseSession(g_cached_session.session);
        g_cached_session.session = NULL;
    }

    if (g_cached_session.session_options)
    {
        g_ort->ReleaseSessionOptions(g_cached_session.session_options);
        g_cached_session.session_options = NULL;
    }

    if (g_cached_session.memory_info)
    {
        g_ort->ReleaseMemoryInfo(g_cached_session.memory_info);
        g_cached_session.memory_info = NULL;
    }

    /* Note: env is singleton, don't release it */

    /* Clear cache */
    memset(&g_cached_session, 0, sizeof(CachedModelSession));

    return 0;
}

#endif /* USE_ONNX_RUNTIME */
