/**
 * @file benchmark.c
 * @brief Performance benchmarks for FastEmbed library
 *
 * This benchmark suite measures performance of:
 * - Hash-based embedding generation
 * - ONNX embedding generation (with caching)
 * - Vector operations (dot product, cosine similarity, normalization)
 * - Model loading time (first call vs cached calls)
 *
 * Compile: make benchmark-build
 * Run: make benchmark
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <math.h>
#include "fastembed.h"

#define DIMENSION 768
#define WARMUP_ITERATIONS 10
#define BENCHMARK_ITERATIONS 1000

/* Timing utilities */
static double get_time_ms(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0;
}

/* Benchmark hash-based embedding generation */
static void benchmark_hash_embedding(void)
{
    printf("\n=== Benchmark: Hash-based Embedding Generation ===\n");

    const char *test_texts[] = {
        "Hello world",
        "The quick brown fox jumps over the lazy dog",
        "FastEmbed is a high-performance embedding library with SIMD optimizations",
        "Machine learning models require efficient vector operations for real-time inference",
    };
    int num_texts = sizeof(test_texts) / sizeof(test_texts[0]);

    float *embeddings = malloc(sizeof(float) * DIMENSION * num_texts);
    if (!embeddings)
    {
        printf("ERROR: Memory allocation failed\n");
        return;
    }

    /* Warmup */
    for (int i = 0; i < WARMUP_ITERATIONS; i++)
    {
        for (int j = 0; j < num_texts; j++)
        {
            fastembed_generate(test_texts[j], embeddings + j * DIMENSION, DIMENSION);
        }
    }

    /* Benchmark */
    double start = get_time_ms();
    for (int i = 0; i < BENCHMARK_ITERATIONS; i++)
    {
        for (int j = 0; j < num_texts; j++)
        {
            fastembed_generate(test_texts[j], embeddings + j * DIMENSION, DIMENSION);
        }
    }
    double end = get_time_ms();

    double total_time = end - start;
    int total_operations = BENCHMARK_ITERATIONS * num_texts;
    double avg_time_per_embedding = total_time / total_operations;
    double embeddings_per_second = 1000.0 / avg_time_per_embedding;

    printf("  Total time: %.2f ms\n", total_time);
    printf("  Operations: %d embeddings\n", total_operations);
    printf("  Average per embedding: %.4f ms\n", avg_time_per_embedding);
    printf("  Throughput: %.2f embeddings/sec\n", embeddings_per_second);
    printf("  Text lengths: ");
    for (int j = 0; j < num_texts; j++)
    {
        printf("%zu ", strlen(test_texts[j]));
    }
    printf("chars\n");

    free(embeddings);
}

/* Benchmark ONNX embedding generation with caching */
static void benchmark_onnx_embedding(void)
{
    printf("\n=== Benchmark: ONNX Embedding Generation (with Caching) ===\n");

#if defined(USE_ONNX_RUNTIME) || defined(__USE_ONNX_RUNTIME__)
    const char *model_path = "models/nomic-embed-text.onnx";

    /* Check if model file exists */
    FILE *f = fopen(model_path, "r");
    if (!f)
    {
        printf("  ⚠️  WARNING: Model file not found: %s\n", model_path);
        printf("     Skipping ONNX benchmarks.\n");
        printf("     To enable: Place model file in models/ directory\n");
        return;
    }
    fclose(f);

    const char *test_texts[] = {
        "Hello world",
        "The quick brown fox jumps over the lazy dog",
        "FastEmbed is a high-performance embedding library",
        "Machine learning models require efficient operations",
    };
    int num_texts = sizeof(test_texts) / sizeof(test_texts[0]);

    float *embeddings = malloc(sizeof(float) * DIMENSION * num_texts);
    if (!embeddings)
    {
        printf("  ERROR: Memory allocation failed\n");
        return;
    }

    /* Test 1: First call (model loading) */
    printf("\n  Test 1: First Call (Model Loading)\n");
    double start = get_time_ms();
    int first_call_success = 1;
    for (int j = 0; j < num_texts; j++)
    {
        int result = fastembed_onnx_generate(model_path, test_texts[j],
                                             embeddings + j * DIMENSION, DIMENSION);
        if (result != 0)
        {
            printf("    ERROR: ONNX embedding generation failed for text %d\n", j);
            first_call_success = 0;
            break;
        }
    }
    double end = get_time_ms();
    double first_call_time = end - start;

    if (!first_call_success)
    {
        printf("    Skipping remaining ONNX benchmarks due to errors\n");
        free(embeddings);
        return;
    }

    printf("    Time: %.2f ms (%.4f ms per embedding)\n",
           first_call_time, first_call_time / num_texts);

    /* Test 2: Cached calls (no reload) */
    printf("\n  Test 2: Cached Calls (No Model Reload)\n");
    start = get_time_ms();
    for (int i = 0; i < BENCHMARK_ITERATIONS; i++)
    {
        for (int j = 0; j < num_texts; j++)
        {
            fastembed_onnx_generate(model_path, test_texts[j],
                                    embeddings + j * DIMENSION, DIMENSION);
        }
    }
    end = get_time_ms();
    double cached_time = end - start;
    int total_operations = BENCHMARK_ITERATIONS * num_texts;
    double avg_time_per_embedding = cached_time / total_operations;
    double embeddings_per_second = 1000.0 / avg_time_per_embedding;

    printf("    Total time: %.2f ms\n", cached_time);
    printf("    Operations: %d embeddings\n", total_operations);
    printf("    Average per embedding: %.4f ms\n", avg_time_per_embedding);
    printf("    Throughput: %.2f embeddings/sec\n", embeddings_per_second);

    /* Test 3: Comparison */
    printf("\n  Test 3: Performance Comparison\n");
    double speedup = first_call_time / avg_time_per_embedding;
    printf("    First call overhead: %.2f ms\n", first_call_time - avg_time_per_embedding);
    printf("    Caching speedup: %.2fx faster\n", speedup);
    printf("    Cache efficiency: %.1f%% (loading time / inference time)\n",
           100.0 * avg_time_per_embedding / first_call_time);

    /* Test 4: Model switching */
    printf("\n  Test 4: Model Switching Test\n");
    int unload_result = fastembed_onnx_unload();
    if (unload_result != 0)
    {
        printf("    WARNING: fastembed_onnx_unload() returned error\n");
    }

    start = get_time_ms();
    int reload_result = fastembed_onnx_generate(model_path, test_texts[0], embeddings, DIMENSION);
    end = get_time_ms();

    if (reload_result == 0)
    {
        printf("    Time after unload (reload): %.2f ms\n", end - start);
    }
    else
    {
        printf("    ERROR: Failed to reload model after unload\n");
    }

    free(embeddings);
#else
    printf("  SKIPPED: ONNX Runtime not available\n");
    printf("  Compile with -DUSE_ONNX_RUNTIME to enable ONNX benchmarks\n");
#endif
}

/* Benchmark vector operations */
static void benchmark_vector_operations(void)
{
    printf("\n=== Benchmark: Vector Operations ===\n");

    float *vec1 = malloc(sizeof(float) * DIMENSION);
    float *vec2 = malloc(sizeof(float) * DIMENSION);
    float *result = malloc(sizeof(float) * DIMENSION);

    if (!vec1 || !vec2 || !result)
    {
        printf("ERROR: Memory allocation failed\n");
        goto cleanup;
    }

    /* Generate test vectors */
    for (int i = 0; i < DIMENSION; i++)
    {
        vec1[i] = (float)(i % 100) / 100.0f;
        vec2[i] = (float)((i + 50) % 100) / 100.0f;
    }

    /* Warmup */
    for (int i = 0; i < WARMUP_ITERATIONS; i++)
    {
        fastembed_dot_product(vec1, vec2, DIMENSION);
        fastembed_cosine_similarity(vec1, vec2, DIMENSION);
        fastembed_vector_norm(vec1, DIMENSION);
    }

    /* Benchmark dot product */
    printf("\n  Dot Product:\n");
    double start = get_time_ms();
    for (int i = 0; i < BENCHMARK_ITERATIONS * 10; i++)
    {
        fastembed_dot_product(vec1, vec2, DIMENSION);
    }
    double end = get_time_ms();
    double dot_time = end - start;
    printf("    Time: %.2f ms for %d operations\n", dot_time, BENCHMARK_ITERATIONS * 10);
    printf("    Average: %.4f ns per operation\n", (dot_time * 1000000.0) / (BENCHMARK_ITERATIONS * 10));

    /* Benchmark cosine similarity */
    printf("\n  Cosine Similarity:\n");
    start = get_time_ms();
    for (int i = 0; i < BENCHMARK_ITERATIONS * 10; i++)
    {
        fastembed_cosine_similarity(vec1, vec2, DIMENSION);
    }
    end = get_time_ms();
    double cosine_time = end - start;
    printf("    Time: %.2f ms for %d operations\n", cosine_time, BENCHMARK_ITERATIONS * 10);
    printf("    Average: %.4f ns per operation\n", (cosine_time * 1000000.0) / (BENCHMARK_ITERATIONS * 10));

    /* Benchmark vector norm */
    printf("\n  Vector Norm:\n");
    start = get_time_ms();
    for (int i = 0; i < BENCHMARK_ITERATIONS * 10; i++)
    {
        fastembed_vector_norm(vec1, DIMENSION);
    }
    end = get_time_ms();
    double norm_time = end - start;
    printf("    Time: %.2f ms for %d operations\n", norm_time, BENCHMARK_ITERATIONS * 10);
    printf("    Average: %.4f ns per operation\n", (norm_time * 1000000.0) / (BENCHMARK_ITERATIONS * 10));

    /* Benchmark normalization */
    printf("\n  Vector Normalization:\n");
    start = get_time_ms();
    for (int i = 0; i < BENCHMARK_ITERATIONS * 10; i++)
    {
        memcpy(result, vec1, sizeof(float) * DIMENSION);
        fastembed_normalize(result, DIMENSION);
    }
    end = get_time_ms();
    double normalize_time = end - start;
    printf("    Time: %.2f ms for %d operations\n", normalize_time, BENCHMARK_ITERATIONS * 10);
    printf("    Average: %.4f ns per operation\n", (normalize_time * 1000000.0) / (BENCHMARK_ITERATIONS * 10));

    /* Benchmark vector addition */
    printf("\n  Vector Addition:\n");
    start = get_time_ms();
    for (int i = 0; i < BENCHMARK_ITERATIONS * 10; i++)
    {
        fastembed_add_vectors(vec1, vec2, result, DIMENSION);
    }
    end = get_time_ms();
    double add_time = end - start;
    printf("    Time: %.2f ms for %d operations\n", add_time, BENCHMARK_ITERATIONS * 10);
    printf("    Average: %.4f ns per operation\n", (add_time * 1000000.0) / (BENCHMARK_ITERATIONS * 10));

cleanup:
    if (vec1)
        free(vec1);
    if (vec2)
        free(vec2);
    if (result)
        free(result);
}

/* Main benchmark runner */
int main(int argc, char **argv)
{
    printf("╔══════════════════════════════════════════════════════════════╗\n");
    printf("║          FastEmbed Performance Benchmarks                    ║\n");
    printf("╚══════════════════════════════════════════════════════════════╝\n");
    fflush(stdout);

    printf("\nConfiguration:\n");
    printf("  Dimension: %d\n", DIMENSION);
    printf("  Warmup iterations: %d\n", WARMUP_ITERATIONS);
    printf("  Benchmark iterations: %d\n", BENCHMARK_ITERATIONS);
    printf("\n");
    fflush(stdout);

    /* Run benchmarks */
    benchmark_hash_embedding();
    fflush(stdout);

    benchmark_vector_operations();
    fflush(stdout);

    benchmark_onnx_embedding();
    fflush(stdout);

    printf("\n╔═════════════════════════════════════════════════════════════╗\n");
    printf("║                    Benchmarks Complete                       ║\n");
    printf("╚══════════════════════════════════════════════════════════════╝\n");
    fflush(stdout);

    return 0;
}
