/**
 * FastEmbed Integration Tests - Embedding Generation
 *
 * Tests for embedding generation with all supported dimensions:
 * - Test all dimensions (128, 256, 512, 768, 1024, 2048)
 * - Test consistency (same text = same embedding)
 * - Test different texts produce different embeddings
 * - Test edge cases (empty text, long text, special characters)
 * - Test case-insensitive behavior
 *
 * Compile: gcc -o test_embedding_generation test_embedding_generation.c
 * -L../build -lfastembed -lm -I../include Run: LD_LIBRARY_PATH=..
 * ./test_embedding_generation
 */

#include "fastembed.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define EPSILON 0.0001f
#define MAX_DIMENSION 2048

int tests_run = 0;
int tests_passed = 0;

/* Supported dimensions */
static const int supported_dimensions[] = {128, 256, 512, 768, 1024, 2048};
static const int num_dimensions =
    sizeof(supported_dimensions) / sizeof(supported_dimensions[0]);

#define ASSERT_EQ_INT(actual, expected)                                        \
  do {                                                                         \
    tests_run++;                                                               \
    if ((actual) == (expected)) {                                              \
      tests_passed++;                                                          \
      printf("  ✓ PASS: %s == %d\n", #actual, (int)(expected));                \
    } else {                                                                   \
      printf("  ✗ FAIL: %s (expected %d, got %d)\n", #actual, (int)(expected), \
             (int)(actual));                                                   \
    }                                                                          \
  } while (0)

#define ASSERT_NE_FLOAT(actual, expected)                                      \
  do {                                                                         \
    tests_run++;                                                               \
    if (fabsf((actual) - (expected)) >= EPSILON) {                             \
      tests_passed++;                                                          \
      printf("  ✓ PASS: %s != %.4f (value: %.4f)\n", #actual,                  \
             (float)(expected), (float)(actual));                              \
    } else {                                                                   \
      printf("  ✗ FAIL: %s equals %.4f\n", #actual, (float)(expected));        \
    }                                                                          \
  } while (0)

/**
 * Test: All supported dimensions work
 */
void test_all_dimensions() {
  printf("\n=== Test: All Supported Dimensions ===\n");

  const char *text = "Test embedding generation";
  int text_length = (int)strlen(text);

  for (int d = 0; d < num_dimensions; d++) {
    int dimension = supported_dimensions[d];
    float *output = (float *)malloc(dimension * sizeof(float));
    if (output == NULL) {
      printf("  ✗ FAIL: Memory allocation failed for dimension %d\n",
             dimension);
      tests_run++;
      continue;
    }

    int result = fastembed_generate(text, output, dimension);

    tests_run++;
    if (result == 0) {
      tests_passed++;
      printf("  ✓ PASS: Dimension %d works\n", dimension);

      /* Check that embedding is not all zeros */
      float sum = 0.0f;
      for (int i = 0; i < dimension; i++) {
        sum += fabsf(output[i]);
      }
      if (sum < EPSILON) {
        printf("    ⚠ WARNING: Embedding is all zeros for dimension %d\n",
               dimension);
      }
    } else {
      printf("  ✗ FAIL: Dimension %d failed (result: %d)\n", dimension, result);
    }

    free(output);
  }
}

/**
 * Test: Consistency - same text produces same embedding
 */
void test_consistency() {
  printf("\n=== Test: Consistency (Same Text = Same Embedding) ===\n");

  const char *text = "Consistency test";
  int dimension = 128;

  float *output1 = (float *)malloc(dimension * sizeof(float));
  float *output2 = (float *)malloc(dimension * sizeof(float));

  if (output1 == NULL || output2 == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  int result1 = fastembed_generate(text, output1, dimension);
  int result2 = fastembed_generate(text, output2, dimension);

  if (result1 != 0 || result2 != 0) {
    printf("  ✗ FAIL: Embedding generation failed (result1: %d, result2: %d)\n",
           result1, result2);
    tests_run++;
    free(output1);
    free(output2);
    return;
  }

  /* Check embeddings are identical */
  int identical = 1;
  float max_diff = 0.0f;
  for (int i = 0; i < dimension; i++) {
    float diff = fabsf(output1[i] - output2[i]);
    if (diff > max_diff)
      max_diff = diff;
    if (diff > EPSILON) {
      identical = 0;
      break;
    }
  }

  tests_run++;
  if (identical) {
    tests_passed++;
    printf(
        "  ✓ PASS: Same text produces identical embedding (max diff: %.6f)\n",
        max_diff);
  } else {
    printf(
        "  ✗ FAIL: Same text produces different embeddings (max diff: %.6f)\n",
        max_diff);
  }

  free(output1);
  free(output2);
}

/**
 * Test: Different texts produce different embeddings
 */
void test_different_texts() {
  printf("\n=== Test: Different Texts Produce Different Embeddings ===\n");

  const char *texts[] = {"Hello", "World", "FastEmbed", "Test", "Different"};
  int num_texts = sizeof(texts) / sizeof(texts[0]);
  int dimension = 128;

  float **outputs = (float **)malloc(num_texts * sizeof(float *));
  if (outputs == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  /* Generate embeddings for all texts */
  int all_success = 1;
  for (int i = 0; i < num_texts; i++) {
    outputs[i] = (float *)malloc(dimension * sizeof(float));
    if (outputs[i] == NULL) {
      all_success = 0;
      break;
    }

    int result = fastembed_generate(texts[i], outputs[i], dimension);
    if (result != 0) {
      all_success = 0;
      break;
    }
  }

  if (!all_success) {
    printf("  ✗ FAIL: Failed to generate embeddings\n");
    tests_run++;
    for (int i = 0; i < num_texts; i++) {
      if (outputs[i])
        free(outputs[i]);
    }
    free(outputs);
    return;
  }

  /* Check that embeddings are different */
  int different_pairs = 0;
  int total_pairs = 0;
  for (int i = 0; i < num_texts; i++) {
    for (int j = i + 1; j < num_texts; j++) {
      total_pairs++;
      float similarity =
          fastembed_cosine_similarity(outputs[i], outputs[j], dimension);
      if (similarity < 0.99f) /* Not identical */
      {
        different_pairs++;
      }
    }
  }

  tests_run++;
  if (different_pairs >=
      total_pairs / 2) /* At least half should be different */
  {
    tests_passed++;
    printf("  ✓ PASS: Different texts produce different embeddings (%d/%d "
           "pairs different)\n",
           different_pairs, total_pairs);
  } else {
    printf("  ✗ FAIL: Too many identical embeddings (%d/%d pairs different)\n",
           different_pairs, total_pairs);
  }

  /* Cleanup */
  for (int i = 0; i < num_texts; i++) {
    free(outputs[i]);
  }
  free(outputs);
}

/**
 * Test: Case-insensitive behavior
 */
void test_case_insensitive() {
  printf("\n=== Test: Case-Insensitive Behavior ===\n");

  const char *text1 = "Hello World";
  const char *text2 = "hello world";
  const char *text3 = "HELLO WORLD";
  int dimension = 128;

  float *output1 = (float *)malloc(dimension * sizeof(float));
  float *output2 = (float *)malloc(dimension * sizeof(float));
  float *output3 = (float *)malloc(dimension * sizeof(float));

  if (output1 == NULL || output2 == NULL || output3 == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  int result1 = fastembed_generate(text1, output1, dimension);
  int result2 = fastembed_generate(text2, output2, dimension);
  int result3 = fastembed_generate(text3, output3, dimension);

  if (result1 != 0 || result2 != 0 || result3 != 0) {
    printf("  ✗ FAIL: Embedding generation failed\n");
    tests_run++;
    free(output1);
    free(output2);
    free(output3);
    return;
  }

  /* Check that all three produce identical embeddings */
  int identical_12 = 1;
  int identical_13 = 1;
  for (int i = 0; i < dimension; i++) {
    if (fabsf(output1[i] - output2[i]) > EPSILON)
      identical_12 = 0;
    if (fabsf(output1[i] - output3[i]) > EPSILON)
      identical_13 = 0;
  }

  tests_run++;
  if (identical_12 && identical_13) {
    tests_passed++;
    printf("  ✓ PASS: Case-insensitive behavior works (all variants produce "
           "same embedding)\n");
  } else {
    printf("  ✗ FAIL: Case-insensitive behavior failed\n");
  }

  free(output1);
  free(output2);
  free(output3);
}

/**
 * Test: Edge case - empty text
 */
void test_empty_text() {
  printf("\n=== Test: Edge Case - Empty Text ===\n");

  const char *text = "";
  int dimension = 128;
  float *output = (float *)malloc(dimension * sizeof(float));

  if (output == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  int result = fastembed_generate(text, output, dimension);

  tests_run++;
  if (result != 0) /* Should fail for empty text */
  {
    tests_passed++;
    printf("  ✓ PASS: Empty text correctly rejected (result: %d)\n", result);
  } else {
    printf("  ✗ FAIL: Empty text should be rejected but was accepted\n");
  }

  free(output);
}

/**
 * Test: Edge case - long text
 */
void test_long_text() {
  printf("\n=== Test: Edge Case - Long Text ===\n");

  /* Create text near max length (8192 chars) */
  char *long_text = (char *)malloc(8193 * sizeof(char));
  if (long_text == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  /* Fill with pattern */
  for (int i = 0; i < 8192; i++) {
    long_text[i] = 'A' + (i % 26);
  }
  long_text[8192] = '\0';

  int dimension = 128;
  float *output = (float *)malloc(dimension * sizeof(float));

  if (output == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    free(long_text);
    tests_run++;
    return;
  }

  int result = fastembed_generate(long_text, output, dimension);

  tests_run++;
  if (result == 0) {
    tests_passed++;
    printf("  ✓ PASS: Long text (8192 chars) processed successfully\n");
  } else {
    printf("  ✗ FAIL: Long text processing failed (result: %d)\n", result);
  }

  free(long_text);
  free(output);
}

/**
 * Test: Edge case - special characters
 */
void test_special_characters() {
  printf("\n=== Test: Edge Case - Special Characters ===\n");

  const char *texts[] = {
      "Hello, world!",
      "Test with\nnewline",
      "Test with\ttab",
      "Test with unicode: 你好世界",
      "Test with symbols: !@#$%^&*()",
  };
  int num_texts = sizeof(texts) / sizeof(texts[0]);
  int dimension = 128;

  int all_success = 1;
  for (int i = 0; i < num_texts; i++) {
    float *output = (float *)malloc(dimension * sizeof(float));
    if (output == NULL) {
      all_success = 0;
      break;
    }

    int result = fastembed_generate(texts[i], output, dimension);
    if (result != 0) {
      all_success = 0;
    }

    free(output);
  }

  tests_run++;
  if (all_success) {
    tests_passed++;
    printf("  ✓ PASS: Special characters handled correctly\n");
  } else {
    printf("  ✗ FAIL: Some special characters caused errors\n");
  }
}

/**
 * Test: Default dimension (0 means 128)
 */
void test_default_dimension() {
  printf("\n=== Test: Default Dimension (0 = 128) ===\n");

  const char *text = "Test default dimension";
  int dimension = 0; /* Should default to 128 */

  float *output = (float *)malloc(128 * sizeof(float));
  if (output == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  int result = fastembed_generate(text, output, dimension);

  tests_run++;
  if (result == 0) {
    tests_passed++;
    printf("  ✓ PASS: Default dimension (0) works (uses 128)\n");
  } else {
    printf("  ✗ FAIL: Default dimension failed (result: %d)\n", result);
  }

  free(output);
}

/**
 * Test: Invalid dimension
 */
void test_invalid_dimension() {
  printf("\n=== Test: Invalid Dimension Rejection ===\n");

  const char *text = "Test";
  int invalid_dimensions[] = {64, 100, 500, 1000, 3000, -1};
  int num_invalid = sizeof(invalid_dimensions) / sizeof(invalid_dimensions[0]);

  int all_rejected = 1;
  for (int i = 0; i < num_invalid; i++) {
    int dimension = invalid_dimensions[i];
    float *output = (float *)malloc(MAX_DIMENSION * sizeof(float));
    if (output == NULL)
      continue;

    int result = fastembed_generate(text, output, dimension);
    if (result == 0) /* Should fail */
    {
      all_rejected = 0;
      printf("    ⚠ WARNING: Invalid dimension %d was accepted\n", dimension);
    }

    free(output);
  }

  tests_run++;
  if (all_rejected) {
    tests_passed++;
    printf("  ✓ PASS: Invalid dimensions correctly rejected\n");
  } else {
    printf("  ✗ FAIL: Some invalid dimensions were accepted\n");
  }
}

int main() {
  printf("FastEmbed Embedding Generation Integration Tests\n");
  printf("================================================\n");

  test_all_dimensions();
  test_consistency();
  test_different_texts();
  test_case_insensitive();
  test_empty_text();
  test_long_text();
  test_special_characters();
  test_default_dimension();
  test_invalid_dimension();

  printf("\n=== Test Summary ===\n");
  printf("Tests run: %d\n", tests_run);
  printf("Tests passed: %d\n", tests_passed);
  printf("Tests failed: %d\n", tests_run - tests_passed);

  if (tests_passed == tests_run) {
    printf("\n✓ All tests passed!\n");
    return 0;
  } else {
    printf("\n✗ Some tests failed\n");
    return 1;
  }
}
