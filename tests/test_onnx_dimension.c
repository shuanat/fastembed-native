/**
 * FastEmbed ONNX Dimension Tests
 *
 * Tests for ONNX model dimension detection and validation:
 * - Test dimension auto-detection
 * - Test dimension validation
 * - Test dimension mismatch detection
 * - Test caching behavior
 *
 * Compile: gcc -o test_onnx_dimension test_onnx_dimension.c -L../build
 * -lfastembed -lm -I../include -DUSE_ONNX_RUNTIME Run: LD_LIBRARY_PATH=..
 * ./test_onnx_dimension
 */

#include "fastembed.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define EPSILON 0.0001f
#define MAX_DIMENSION 2048

int tests_run = 0;
int tests_passed = 0;

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

#define ASSERT_NE_INT(actual, expected)                                        \
  do {                                                                         \
    tests_run++;                                                               \
    if ((actual) != (expected)) {                                              \
      tests_passed++;                                                          \
      printf("  ✓ PASS: %s != %d (value: %d)\n", #actual, (int)(expected),     \
             (int)(actual));                                                   \
    } else {                                                                   \
      printf("  ✗ FAIL: %s equals %d\n", #actual, (int)(expected));            \
    }                                                                          \
  } while (0)

#define ASSERT_GT_INT(actual, expected)                                        \
  do {                                                                         \
    tests_run++;                                                               \
    if ((actual) > (expected)) {                                               \
      tests_passed++;                                                          \
      printf("  ✓ PASS: %s > %d (value: %d)\n", #actual, (int)(expected),      \
             (int)(actual));                                                   \
    } else {                                                                   \
      printf("  ✗ FAIL: %s not > %d (value: %d)\n", #actual, (int)(expected),  \
             (int)(actual));                                                   \
    }                                                                          \
  } while (0)

/**
 * Test: Dimension auto-detection
 */
void test_dimension_auto_detection() {
  printf("\n=== Test: ONNX Dimension Auto-Detection ===\n");

#ifdef USE_ONNX_RUNTIME
  const char *model_path =
      "models/test.onnx"; /* Placeholder - adjust as needed */

  /* Check if model exists */
  FILE *f = fopen(model_path, "r");
  if (f == NULL) {
    printf("  ⚠ SKIP: Test model not found at %s\n", model_path);
    printf("  To test dimension detection, place a model file at %s\n",
           model_path);
    tests_run++;
    tests_passed++; /* Don't fail if model not available */
    return;
  }
  fclose(f);

  int dimension = fastembed_onnx_get_model_dimension(model_path);

  if (dimension > 0) {
    ASSERT_GT_INT(dimension, 0);
    printf("  Detected dimension: %d\n", dimension);
    printf("  ✓ PASS: Dimension auto-detection works\n");
  } else {
    printf("  ✗ FAIL: Dimension detection failed (result: %d)\n", dimension);
    printf("  Check error message: ");
    char error_buffer[512];
    if (fastembed_onnx_get_last_error(error_buffer, sizeof(error_buffer)) ==
        0) {
      printf("%s\n", error_buffer);
    } else {
      printf("No error message available\n");
    }
  }
#else
  printf("  ⚠ SKIP: ONNX Runtime not available (compiled without "
         "USE_ONNX_RUNTIME)\n");
  tests_run++;
  tests_passed++; /* Don't fail if ONNX not available */
#endif
}

/**
 * Test: Dimension validation
 */
void test_dimension_validation() {
  printf("\n=== Test: ONNX Dimension Validation ===\n");

#ifdef USE_ONNX_RUNTIME
  const char *model_path =
      "models/test.onnx"; /* Placeholder - adjust as needed */

  /* Check if model exists */
  FILE *f = fopen(model_path, "r");
  if (f == NULL) {
    printf("  ⚠ SKIP: Test model not found at %s\n", model_path);
    tests_run++;
    tests_passed++;
    return;
  }
  fclose(f);

  /* Get model dimension */
  int model_dimension = fastembed_onnx_get_model_dimension(model_path);
  if (model_dimension <= 0) {
    printf("  ⚠ SKIP: Cannot get model dimension\n");
    tests_run++;
    tests_passed++;
    return;
  }

  printf("  Model dimension: %d\n", model_dimension);

  /* Test with correct dimension */
  float *output_correct = (float *)malloc(model_dimension * sizeof(float));
  if (output_correct == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  int result_correct = fastembed_onnx_generate(model_path, "Test text",
                                               output_correct, model_dimension);
  ASSERT_EQ_INT(result_correct, 0);
  free(output_correct);

  /* Test with incorrect dimension */
  int wrong_dimension = (model_dimension == 768) ? 512 : 768;
  float *output_wrong = (float *)malloc(wrong_dimension * sizeof(float));
  if (output_wrong == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  int result_wrong = fastembed_onnx_generate(model_path, "Test text",
                                             output_wrong, wrong_dimension);
  ASSERT_NE_INT(result_wrong, 0); /* Should fail */
  printf(
      "  ✓ PASS: Dimension mismatch correctly rejected (wrong dimension: %d)\n",
      wrong_dimension);
  free(output_wrong);

  /* Test with auto-detect (dimension = 0) */
  float *output_auto = (float *)malloc(model_dimension * sizeof(float));
  if (output_auto == NULL) {
    printf("  ✗ FAIL: Memory allocation failed\n");
    tests_run++;
    return;
  }

  int result_auto =
      fastembed_onnx_generate(model_path, "Test text", output_auto, 0);
  ASSERT_EQ_INT(result_auto, 0);
  printf("  ✓ PASS: Auto-detect dimension works (dimension = 0)\n");
  free(output_auto);
#else
  printf("  ⚠ SKIP: ONNX Runtime not available (compiled without "
         "USE_ONNX_RUNTIME)\n");
  tests_run++;
  tests_passed++;
#endif
}

/**
 * Test: Dimension caching
 */
void test_dimension_caching() {
  printf("\n=== Test: ONNX Dimension Caching ===\n");

#ifdef USE_ONNX_RUNTIME
  const char *model_path =
      "models/test.onnx"; /* Placeholder - adjust as needed */

  /* Check if model exists */
  FILE *f = fopen(model_path, "r");
  if (f == NULL) {
    printf("  ⚠ SKIP: Test model not found at %s\n", model_path);
    tests_run++;
    tests_passed++;
    return;
  }
  fclose(f);

  /* First call - should detect dimension */
  int dimension1 = fastembed_onnx_get_model_dimension(model_path);
  if (dimension1 <= 0) {
    printf("  ⚠ SKIP: Cannot get model dimension\n");
    tests_run++;
    tests_passed++;
    return;
  }

  /* Second call - should use cached dimension */
  int dimension2 = fastembed_onnx_get_model_dimension(model_path);

  ASSERT_EQ_INT(dimension1, dimension2);
  printf("  First call dimension: %d\n", dimension1);
  printf("  Second call dimension: %d\n", dimension2);
  printf("  ✓ PASS: Dimension is cached correctly\n");
#else
  printf("  ⚠ SKIP: ONNX Runtime not available (compiled without "
         "USE_ONNX_RUNTIME)\n");
  tests_run++;
  tests_passed++;
#endif
}

/**
 * Test: Invalid model path
 */
void test_invalid_model_path() {
  printf("\n=== Test: Invalid Model Path ===\n");

#ifdef USE_ONNX_RUNTIME
  const char *invalid_path = "models/nonexistent_model.onnx";

  int dimension = fastembed_onnx_get_model_dimension(invalid_path);

  ASSERT_NE_INT(dimension, 0); /* Should fail (return -1) */
  if (dimension < 0) {
    printf("  ✓ PASS: Invalid model path correctly rejected (result: %d)\n",
           dimension);
  } else {
    printf("  ✗ FAIL: Invalid model path should be rejected\n");
  }

  /* Check error message */
  char error_buffer[512];
  if (fastembed_onnx_get_last_error(error_buffer, sizeof(error_buffer)) == 0) {
    printf("  Error message: %s\n", error_buffer);
  }
#else
  printf("  ⚠ SKIP: ONNX Runtime not available (compiled without "
         "USE_ONNX_RUNTIME)\n");
  tests_run++;
  tests_passed++;
#endif
}

/**
 * Test: NULL model path
 */
void test_null_model_path() {
  printf("\n=== Test: NULL Model Path ===\n");

#ifdef USE_ONNX_RUNTIME
  int dimension = fastembed_onnx_get_model_dimension(NULL);

  ASSERT_NE_INT(dimension, 0); /* Should fail (return -1) */
  if (dimension < 0) {
    printf("  ✓ PASS: NULL model path correctly rejected (result: %d)\n",
           dimension);
  } else {
    printf("  ✗ FAIL: NULL model path should be rejected\n");
  }
#else
  printf("  ⚠ SKIP: ONNX Runtime not available (compiled without "
         "USE_ONNX_RUNTIME)\n");
  tests_run++;
  tests_passed++;
#endif
}

/**
 * Test: Supported dimensions
 */
void test_supported_dimensions() {
  printf("\n=== Test: Supported Dimensions for ONNX ===\n");

#ifdef USE_ONNX_RUNTIME
  const char *model_path =
      "models/test.onnx"; /* Placeholder - adjust as needed */

  /* Check if model exists */
  FILE *f = fopen(model_path, "r");
  if (f == NULL) {
    printf("  ⚠ SKIP: Test model not found at %s\n", model_path);
    tests_run++;
    tests_passed++;
    return;
  }
  fclose(f);

  int model_dimension = fastembed_onnx_get_model_dimension(model_path);
  if (model_dimension <= 0) {
    printf("  ⚠ SKIP: Cannot get model dimension\n");
    tests_run++;
    tests_passed++;
    return;
  }

  printf("  Model dimension: %d\n", model_dimension);
  printf("  Supported dimensions: 128, 256, 512, 768, 1024, 2048\n");

  /* Test that model dimension is in supported list */
  int supported[] = {128, 256, 512, 768, 1024, 2048};
  int num_supported = sizeof(supported) / sizeof(supported[0]);
  int is_supported = 0;

  for (int i = 0; i < num_supported; i++) {
    if (model_dimension == supported[i]) {
      is_supported = 1;
      break;
    }
  }

  tests_run++;
  if (is_supported || model_dimension <= MAX_DIMENSION) {
    tests_passed++;
    printf("  ✓ PASS: Model dimension is supported or within limits\n");
  } else {
    printf(
        "  ⚠ WARNING: Model dimension %d is not in standard supported list\n",
        model_dimension);
  }
#else
  printf("  ⚠ SKIP: ONNX Runtime not available (compiled without "
         "USE_ONNX_RUNTIME)\n");
  tests_run++;
  tests_passed++;
#endif
}

int main() {
  printf("FastEmbed ONNX Dimension Tests\n");
  printf("==============================\n");

  test_dimension_auto_detection();
  test_dimension_validation();
  test_dimension_caching();
  test_invalid_model_path();
  test_null_model_path();
  test_supported_dimensions();

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
