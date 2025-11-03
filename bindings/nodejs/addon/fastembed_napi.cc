/**
 * FastEmbed Native N-API Module
 *
 * Native Node.js addon using N-API for direct C library integration
 * without FFI dependencies. Provides high-performance binding to FastEmbed.
 */

#include <node_api.h>
#include <cstring>
#include <cstdlib>

// Forward declarations of FastEmbed C functions
extern "C"
{
    int fastembed_generate(const char *text, float *output, int dimension);
    int fastembed_onnx_generate(const char *model_path, const char *text, float *output, int dimension);
    int fastembed_onnx_unload(void);
    float fastembed_cosine_similarity(const float *vector_a, const float *vector_b, int dimension);
    float fastembed_dot_product(const float *vector_a, const float *vector_b, int dimension);
    float fastembed_vector_norm(const float *vector, int dimension);
    void normalize_vector_asm(float *vector, int dimension);
    void fastembed_add_vectors(const float *vector_a, const float *vector_b, float *result, int dimension);
}

// Helper: Convert napi_value to string
static char *GetStringFromValue(napi_env env, napi_value value)
{
    size_t str_size;
    napi_get_value_string_utf8(env, value, nullptr, 0, &str_size);

    char *buf = (char *)malloc(str_size + 1);
    napi_get_value_string_utf8(env, value, buf, str_size + 1, &str_size);

    return buf;
}

// Helper: Convert napi_value (Float32Array/Array) to float array
static float *GetFloatArrayFromValue(napi_env env, napi_value value, size_t *out_length)
{
    bool is_typedarray;
    napi_is_typedarray(env, value, &is_typedarray);

    if (is_typedarray)
    {
        // Float32Array
        napi_typedarray_type type;
        size_t length;
        void *data;
        napi_value arraybuffer;
        size_t byte_offset;

        napi_get_typedarray_info(env, value, &type, &length, &data, &arraybuffer, &byte_offset);

        if (type != napi_float32_array)
        {
            return nullptr;
        }

        *out_length = length;
        float *result = (float *)malloc(length * sizeof(float));
        memcpy(result, data, length * sizeof(float));
        return result;
    }
    else
    {
        // Regular array
        bool is_array;
        napi_is_array(env, value, &is_array);

        if (!is_array)
        {
            return nullptr;
        }

        uint32_t length;
        napi_get_array_length(env, value, &length);

        *out_length = length;
        float *result = (float *)malloc(length * sizeof(float));

        for (uint32_t i = 0; i < length; i++)
        {
            napi_value element;
            napi_get_element(env, value, i, &element);

            double value;
            napi_get_value_double(env, element, &value);
            result[i] = (float)value;
        }

        return result;
    }
}

/**
 * Generate embedding from text
 *
 * @param text - Input text string
 * @param dimension - Embedding dimension (default: 768)
 * @returns Float32Array with embedding vector
 */
static napi_value GenerateEmbedding(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1)
    {
        napi_throw_error(env, nullptr, "Expected at least 1 argument: text");
        return nullptr;
    }

    // Get text argument
    char *text = GetStringFromValue(env, args[0]);

    // Get dimension argument (default: 768)
    int dimension = 768;
    if (argc >= 2)
    {
        napi_get_value_int32(env, args[1], &dimension);
    }

    // Allocate output buffer
    float *output = (float *)malloc(dimension * sizeof(float));

    // Call C function
    int result = fastembed_generate(text, output, dimension);

    free(text);

    if (result != 0)
    {
        free(output);
        napi_throw_error(env, nullptr, "Failed to generate embedding");
        return nullptr;
    }

    // Create Float32Array
    napi_value arraybuffer;
    void *data;
    napi_create_arraybuffer(env, dimension * sizeof(float), &data, &arraybuffer);
    memcpy(data, output, dimension * sizeof(float));

    napi_value typedarray;
    napi_create_typedarray(env, napi_float32_array, dimension, arraybuffer, 0, &typedarray);

    free(output);

    return typedarray;
}

/**
 * Generate embedding from text using ONNX model
 *
 * @param modelPath - Path to ONNX model file
 * @param text - Input text string
 * @param dimension - Embedding dimension (default: 768)
 * @returns Float32Array with embedding vector
 */
static napi_value GenerateOnnxEmbedding(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2)
    {
        napi_throw_error(env, nullptr, "Expected at least 2 arguments: modelPath, text");
        return nullptr;
    }

    // Get model path argument
    char *model_path = GetStringFromValue(env, args[0]);

    // Get text argument
    char *text = GetStringFromValue(env, args[1]);

    // Get dimension argument (default: 768)
    int dimension = 768;
    if (argc >= 3)
    {
        napi_get_value_int32(env, args[2], &dimension);
    }

    // Allocate output buffer
    float *output = (float *)malloc(dimension * sizeof(float));

    // Call C function
    int result = fastembed_onnx_generate(model_path, text, output, dimension);

    free(model_path);
    free(text);

    if (result != 0)
    {
        free(output);
        napi_throw_error(env, nullptr, "Failed to generate ONNX embedding");
        return nullptr;
    }

    // Create Float32Array
    napi_value arraybuffer;
    void *data;
    napi_create_arraybuffer(env, dimension * sizeof(float), &data, &arraybuffer);
    memcpy(data, output, dimension * sizeof(float));

    napi_value typedarray;
    napi_create_typedarray(env, napi_float32_array, dimension, arraybuffer, 0, &typedarray);

    free(output);

    return typedarray;
}

/**
 * Unload ONNX model from memory
 *
 * @returns Number (0 on success, -1 on error)
 */
static napi_value UnloadOnnxModel(napi_env env, napi_callback_info info)
{
    int result = fastembed_onnx_unload();

    napi_value return_value;
    napi_create_int32(env, result, &return_value);

    return return_value;
}

/**
 * Calculate cosine similarity between two vectors
 *
 * @param vector_a - First vector (Float32Array or Array)
 * @param vector_b - Second vector (Float32Array or Array)
 * @returns Cosine similarity value (float)
 */
static napi_value CosineSimilarity(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2)
    {
        napi_throw_error(env, nullptr, "Expected 2 arguments: vector_a, vector_b");
        return nullptr;
    }

    // Get vectors
    size_t len_a, len_b;
    float *vector_a = GetFloatArrayFromValue(env, args[0], &len_a);
    float *vector_b = GetFloatArrayFromValue(env, args[1], &len_b);

    if (!vector_a || !vector_b)
    {
        if (vector_a)
            free(vector_a);
        if (vector_b)
            free(vector_b);
        napi_throw_error(env, nullptr, "Invalid vector arguments");
        return nullptr;
    }

    if (len_a != len_b)
    {
        free(vector_a);
        free(vector_b);
        napi_throw_error(env, nullptr, "Vectors must have the same length");
        return nullptr;
    }

    // Call C function
    float similarity = fastembed_cosine_similarity(vector_a, vector_b, (int)len_a);

    free(vector_a);
    free(vector_b);

    // Return result
    napi_value result;
    napi_create_double(env, similarity, &result);

    return result;
}

/**
 * Calculate dot product of two vectors
 *
 * @param vector_a - First vector
 * @param vector_b - Second vector
 * @returns Dot product value (float)
 */
static napi_value DotProduct(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2)
    {
        napi_throw_error(env, nullptr, "Expected 2 arguments: vector_a, vector_b");
        return nullptr;
    }

    size_t len_a, len_b;
    float *vector_a = GetFloatArrayFromValue(env, args[0], &len_a);
    float *vector_b = GetFloatArrayFromValue(env, args[1], &len_b);

    if (!vector_a || !vector_b || len_a != len_b)
    {
        if (vector_a)
            free(vector_a);
        if (vector_b)
            free(vector_b);
        napi_throw_error(env, nullptr, "Invalid vector arguments");
        return nullptr;
    }

    float dot = fastembed_dot_product(vector_a, vector_b, (int)len_a);

    free(vector_a);
    free(vector_b);

    napi_value result;
    napi_create_double(env, dot, &result);

    return result;
}

/**
 * Calculate vector norm (L2 norm)
 *
 * @param vector - Input vector
 * @returns Norm value (float)
 */
static napi_value VectorNorm(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1)
    {
        napi_throw_error(env, nullptr, "Expected 1 argument: vector");
        return nullptr;
    }

    size_t length;
    float *vector = GetFloatArrayFromValue(env, args[0], &length);

    if (!vector)
    {
        napi_throw_error(env, nullptr, "Invalid vector argument");
        return nullptr;
    }

    float norm = fastembed_vector_norm(vector, (int)length);

    free(vector);

    napi_value result;
    napi_create_double(env, norm, &result);

    return result;
}

/**
 * Normalize vector in-place (L2 normalization)
 *
 * @param vector - Input/output vector
 * @returns Normalized vector (Float32Array)
 */
static napi_value NormalizeVector(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 1)
    {
        napi_throw_error(env, nullptr, "Expected 1 argument: vector");
        return nullptr;
    }

    size_t length;
    float *vector = GetFloatArrayFromValue(env, args[0], &length);

    if (!vector)
    {
        napi_throw_error(env, nullptr, "Invalid vector argument");
        return nullptr;
    }

    normalize_vector_asm(vector, (int)length);

    // Create Float32Array with normalized values
    napi_value arraybuffer;
    void *data;
    napi_create_arraybuffer(env, length * sizeof(float), &data, &arraybuffer);
    memcpy(data, vector, length * sizeof(float));

    napi_value typedarray;
    napi_create_typedarray(env, napi_float32_array, length, arraybuffer, 0, &typedarray);

    free(vector);

    return typedarray;
}

/**
 * Add two vectors element-wise
 *
 * @param vector_a - First vector
 * @param vector_b - Second vector
 * @returns Result vector (Float32Array)
 */
static napi_value AddVectors(napi_env env, napi_callback_info info)
{
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2)
    {
        napi_throw_error(env, nullptr, "Expected 2 arguments: vector_a, vector_b");
        return nullptr;
    }

    size_t len_a, len_b;
    float *vector_a = GetFloatArrayFromValue(env, args[0], &len_a);
    float *vector_b = GetFloatArrayFromValue(env, args[1], &len_b);

    if (!vector_a || !vector_b || len_a != len_b)
    {
        if (vector_a)
            free(vector_a);
        if (vector_b)
            free(vector_b);
        napi_throw_error(env, nullptr, "Invalid vector arguments");
        return nullptr;
    }

    float *result = (float *)malloc(len_a * sizeof(float));
    fastembed_add_vectors(vector_a, vector_b, result, (int)len_a);

    free(vector_a);
    free(vector_b);

    // Create Float32Array
    napi_value arraybuffer;
    void *data;
    napi_create_arraybuffer(env, len_a * sizeof(float), &data, &arraybuffer);
    memcpy(data, result, len_a * sizeof(float));

    napi_value typedarray;
    napi_create_typedarray(env, napi_float32_array, len_a, arraybuffer, 0, &typedarray);

    free(result);

    return typedarray;
}

// Module initialization
static napi_value Init(napi_env env, napi_value exports)
{
    // Export functions
    napi_value generate_fn, generate_onnx_fn, unload_onnx_fn, cosine_fn, dot_fn, norm_fn, normalize_fn, add_fn;

    napi_create_function(env, nullptr, 0, GenerateEmbedding, nullptr, &generate_fn);
    napi_create_function(env, nullptr, 0, GenerateOnnxEmbedding, nullptr, &generate_onnx_fn);
    napi_create_function(env, nullptr, 0, UnloadOnnxModel, nullptr, &unload_onnx_fn);
    napi_create_function(env, nullptr, 0, CosineSimilarity, nullptr, &cosine_fn);
    napi_create_function(env, nullptr, 0, DotProduct, nullptr, &dot_fn);
    napi_create_function(env, nullptr, 0, VectorNorm, nullptr, &norm_fn);
    napi_create_function(env, nullptr, 0, NormalizeVector, nullptr, &normalize_fn);
    napi_create_function(env, nullptr, 0, AddVectors, nullptr, &add_fn);

    napi_set_named_property(env, exports, "generateEmbedding", generate_fn);
    napi_set_named_property(env, exports, "generateOnnxEmbedding", generate_onnx_fn);
    napi_set_named_property(env, exports, "unloadOnnxModel", unload_onnx_fn);
    napi_set_named_property(env, exports, "cosineSimilarity", cosine_fn);
    napi_set_named_property(env, exports, "dotProduct", dot_fn);
    napi_set_named_property(env, exports, "vectorNorm", norm_fn);
    napi_set_named_property(env, exports, "normalizeVector", normalize_fn);
    napi_set_named_property(env, exports, "addVectors", add_fn);

    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
