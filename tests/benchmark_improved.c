/**
 * FastEmbed Performance Benchmarks - Improved Algorithm
 *
 * Benchmarks for improved hash-based embedding algorithm:
 * - Benchmark all dimensions (128, 256, 512, 768, 1024, 2048)
 * - Measure performance for different text lengths
 * - Verify 128D default: < 0.05 ms (faster than old 768D)
 * - Verify 768D: < 0.15 ms (acceptable)
 * - Compare performance across dimensions
 *
 * Compile: gcc -o benchmark_improved benchmark_improved.c -L../build
 * -lfastembed -lm -I../include -O2 Run: LD_LIBRARY_PATH=.. ./benchmark_improved
 */

#include "fastembed.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Supported dimensions */
static const int supported_dimensions[] = {128, 256, 512, 768, 1024, 2048};
static const int num_dimensions =
    sizeof(supported_dimensions) / sizeof(supported_dimensions[0]);

/* Test texts of different lengths */
static const char *test_texts[] = {
    "Hello",                                 /* Short: ~5 chars */
    "FastEmbed is a fast embedding library", /* Medium: ~40 chars */
    "FastEmbed is a high-performance native embedding library that provides "
    "ultra-fast text embedding generation using SIMD-optimized assembly code. "
    "It supports both hash-based deterministic embeddings and ONNX Runtime "
    "integration for neural network models. The library is designed for "
    "cross-platform use on Windows and Linux x86-64 systems.", /* Long: ~250
                                                                  chars */
};
static const int num_texts = sizeof(test_texts) / sizeof(test_texts[0]);
static const char *text_labels[] = {"Short (~5 chars)", "Medium (~40 chars)",
                                    "Long (~250 chars)"};

/* High-resolution timer */
#ifdef _WIN32
#include <windows.h>
static double get_time_ms() {
  LARGE_INTEGER frequency, counter;
  QueryPerformanceFrequency(&frequency);
  QueryPerformanceCounter(&counter);
  return (double)counter.QuadPart * 1000.0 / (double)frequency.QuadPart;
}
#else
#include <sys/time.h>
static double get_time_ms() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}
#endif

/**
 * Benchmark embedding generation for a specific dimension and text
 */
double benchmark_embedding(const char *text, int dimension, int iterations) {
  float *output = (float *)malloc(dimension * sizeof(float));
  if (output == NULL)
    return -1.0;

  /* Warm-up */
  for (int i = 0; i < 10; i++) {
    fastembed_generate(text, output, dimension);
  }

  /* Actual benchmark */
  double start = get_time_ms();
  for (int i = 0; i < iterations; i++) {
    fastembed_generate(text, output, dimension);
  }
  double end = get_time_ms();

  double total_time = end - start;
  double avg_time = total_time / iterations;

  free(output);
  return avg_time;
}

/**
 * Benchmark all dimensions for a specific text
 */
void benchmark_text(const char *text, const char *label, int iterations) {
  printf("\n=== Benchmark: %s ===\n", label);
  printf("Text length: %zu characters\n", strlen(text));
  printf("Iterations: %d\n", iterations);
  printf("\nDimension | Avg Time (ms) | Throughput (emb/s)\n");
  printf("----------|---------------|-------------------\n");

  for (int d = 0; d < num_dimensions; d++) {
    int dimension = supported_dimensions[d];
    double avg_time = benchmark_embedding(text, dimension, iterations);

    if (avg_time < 0.0) {
      printf("  %4d    | ERROR         | ERROR\n", dimension);
      continue;
    }

    double throughput = 1000.0 / avg_time; /* embeddings per second */

    printf("  %4d    | %10.4f    | %10.0f\n", dimension, avg_time, throughput);

    /* Verify performance targets */
    if (dimension == 128 && avg_time > 0.05) {
      printf("    ⚠ WARNING: 128D exceeds target (< 0.05 ms)\n");
    }
    if (dimension == 768 && avg_time > 0.15) {
      printf("    ⚠ WARNING: 768D exceeds target (< 0.15 ms)\n");
    }
  }
}

/**
 * Benchmark dimension detection (if ONNX available)
 */
void benchmark_onnx_dimension_detection() {
  printf("\n=== Benchmark: ONNX Dimension Detection ===\n");

#ifdef USE_ONNX_RUNTIME
  const char *model_path =
      "models/test.onnx"; /* Placeholder - adjust as needed */
  int iterations = 100;

  /* Check if model exists */
  FILE *f = fopen(model_path, "r");
  if (f == NULL) {
    printf("  ⚠ SKIP: Test model not found at %s\n", model_path);
    printf("  To test ONNX dimension detection, place a model file at %s\n",
           model_path);
    return;
  }
  fclose(f);

  /* Warm-up */
  fastembed_onnx_get_model_dimension(model_path);

  /* Benchmark */
  double start = get_time_ms();
  for (int i = 0; i < iterations; i++) {
    fastembed_onnx_get_model_dimension(model_path);
  }
  double end = get_time_ms();

  double total_time = end - start;
  double avg_time = total_time / iterations;
  double throughput = 1000.0 / avg_time;

  printf("Iterations: %d\n", iterations);
  printf("Average time: %.4f ms\n", avg_time);
  printf("Throughput: %.0f detections/sec\n", throughput);
  printf("\nNote: First call loads model (~100-500ms), subsequent calls use "
         "cache\n");
#else
  printf("  ⚠ SKIP: ONNX Runtime not available (compiled without "
         "USE_ONNX_RUNTIME)\n");
#endif
}

/**
 * Performance comparison summary
 */
void performance_summary() {
  printf("\n=== Performance Summary ===\n");
  printf("\nPerformance Targets:\n");
  printf("- 128D (default): < 0.05 ms per embedding\n");
  printf("- 768D (BERT): < 0.15 ms per embedding\n");
  printf("- All dimensions: Scalable performance\n");
  printf("\nImprovements:\n");
  printf("- Default dimension changed from 768 to 128 (2-3x faster)\n");
  printf("- Improved algorithm with positional hashing and Square Root "
         "normalization\n");
  printf("- Case-insensitive normalization (no performance impact)\n");
  printf("\nNote: Performance may vary based on:\n");
  printf("- CPU architecture and SIMD support\n");
  printf("- Text length\n");
  printf("- System load\n");
}

int main() {
  printf("FastEmbed Performance Benchmarks - Improved Algorithm\n");
  printf("====================================================\n");

  int iterations = 10000; /* Number of iterations for benchmark */

  /* Benchmark each text length */
  for (int t = 0; t < num_texts; t++) {
    benchmark_text(test_texts[t], text_labels[t], iterations);
  }

  /* Benchmark ONNX dimension detection */
  benchmark_onnx_dimension_detection();

  /* Summary */
  performance_summary();

  printf("\n=== Benchmark Complete ===\n");
  return 0;
}
