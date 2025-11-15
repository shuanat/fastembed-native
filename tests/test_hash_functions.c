/**
 * FastEmbed Unit Tests - Hash Functions
 *
 * Tests for improved hash-based embedding algorithm functions:
 * - positional_hash_asm: Positional hashing with character position weighting
 * - hash_to_float_sqrt_asm: Square Root normalization to [-1, 1] range
 * - generate_combined_hash_asm: Combined hashing for better distribution
 *
 * Compile: gcc -o test_hash_functions test_hash_functions.c -L../build
 * -lfastembed -lm -I../include Run: LD_LIBRARY_PATH=.. ./test_hash_functions
 */

#include "fastembed.h"
#include <assert.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Internal functions for testing */
#include "../bindings/shared/include/fastembed_internal.h"

#define EPSILON 0.0001f
#define FLOAT_EPSILON 0.001f

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

#define ASSERT_EQ_UINT64(actual, expected)                                     \
  do {                                                                         \
    tests_run++;                                                               \
    if ((actual) == (expected)) {                                              \
      tests_passed++;                                                          \
      printf("  ✓ PASS: %s == %llu\n", #actual,                                \
             (unsigned long long)(expected));                                  \
    } else {                                                                   \
      printf("  ✗ FAIL: %s (expected %llu, got %llu)\n", #actual,              \
             (unsigned long long)(expected), (unsigned long long)(actual));    \
    }                                                                          \
  } while (0)

#define ASSERT_NE_UINT64(actual, expected)                                     \
  do {                                                                         \
    tests_run++;                                                               \
    if ((actual) != (expected)) {                                              \
      tests_passed++;                                                          \
      printf("  ✓ PASS: %s != %llu\n", #actual,                                \
             (unsigned long long)(expected));                                  \
    } else {                                                                   \
      printf("  ✗ FAIL: %s (values are equal: %llu)\n", #actual,               \
             (unsigned long long)(actual));                                    \
    }                                                                          \
  } while (0)

#define ASSERT_IN_RANGE(value, min, max)                                       \
  do {                                                                         \
    tests_run++;                                                               \
    if ((value) >= (min) && (value) <= (max)) {                                \
      tests_passed++;                                                          \
      printf("  ✓ PASS: %s in range [%.4f, %.4f] (value: %.4f)\n", #value,     \
             (float)(min), (float)(max), (float)(value));                      \
    } else {                                                                   \
      printf("  ✗ FAIL: %s out of range [%.4f, %.4f] (value: %.4f)\n", #value, \
             (float)(min), (float)(max), (float)(value));                      \
    }                                                                          \
  } while (0)

/**
 * Test: positional_hash_asm - Deterministic behavior
 */
void test_positional_hash_deterministic() {
  printf("\n=== Test: positional_hash_asm - Deterministic ===\n");

  const char *text = "Hello";
  int text_length = (int)strlen(text);
  int seed = 42;

  uint64_t hash1 = positional_hash_asm(text, text_length, seed);
  uint64_t hash2 = positional_hash_asm(text, text_length, seed);

  ASSERT_EQ_UINT64(hash1, hash2);
  printf("  Hash value: %llu\n", (unsigned long long)hash1);
}

/**
 * Test: positional_hash_asm - Position affects result
 */
void test_positional_hash_position_sensitive() {
  printf("\n=== Test: positional_hash_asm - Position Sensitive ===\n");

  const char *text1 = "ab";
  const char *text2 = "ba";
  int text_length = 2;
  int seed = 0;

  uint64_t hash1 = positional_hash_asm(text1, text_length, seed);
  uint64_t hash2 = positional_hash_asm(text2, text_length, seed);

  ASSERT_NE_UINT64(hash1, hash2);
  printf("  'ab' hash: %llu\n", (unsigned long long)hash1);
  printf("  'ba' hash: %llu\n", (unsigned long long)hash2);
}

/**
 * Test: positional_hash_asm - Seed affects result
 */
void test_positional_hash_seed_sensitive() {
  printf("\n=== Test: positional_hash_asm - Seed Sensitive ===\n");

  const char *text = "Hello";
  int text_length = (int)strlen(text);
  int seed1 = 0;
  int seed2 = 1;

  uint64_t hash1 = positional_hash_asm(text, text_length, seed1);
  uint64_t hash2 = positional_hash_asm(text, text_length, seed2);

  ASSERT_NE_UINT64(hash1, hash2);
  printf("  Seed 0 hash: %llu\n", (unsigned long long)hash1);
  printf("  Seed 1 hash: %llu\n", (unsigned long long)hash2);
}

/**
 * Test: hash_to_float_sqrt_asm - Range [-1, 1]
 */
void test_hash_to_float_sin_range() {
  printf("\n=== Test: hash_to_float_sqrt_asm - Range [-1, 1] ===\n");

  /* Test multiple hash values to ensure range */
  uint64_t test_hashes[] = {
      0, 1, 100, 1000, 10000, 100000, 1000000, UINT64_MAX / 2, UINT64_MAX};
  int num_hashes = sizeof(test_hashes) / sizeof(test_hashes[0]);

  for (int i = 0; i < num_hashes; i++) {
    float result = hash_to_float_sqrt_asm(test_hashes[i]);
    float result2 = hash_to_float_sqrt_asm(test_hashes[i]); // Test determinism

    tests_run++;
    if (result >= -1.0f && result <= 1.0f) {
      // Check determinism - same hash should give same value
      if (fabsf(result - result2) < 0.001f) {
        tests_passed++;
        printf(
            "  ✓ PASS: Hash %llu -> %.6f (in range [-1, 1], deterministic)\n",
            (unsigned long long)test_hashes[i], result);
      } else {
        printf("  ✗ FAIL: Hash %llu -> %.6f vs %.6f (NON-DETERMINISTIC!)\n",
               (unsigned long long)test_hashes[i], result, result2);
      }
    } else {
      printf("  ✗ FAIL: Hash %llu -> %.6f (out of range [-1, 1])\n",
             (unsigned long long)test_hashes[i], result);
    }
  }
}

/**
 * Test: hash_to_float_sqrt_asm - Distribution
 */
void test_hash_to_float_sin_distribution() {
  printf("\n=== Test: hash_to_float_sqrt_asm - Distribution ===\n");

  /* Test that different hashes produce different values */
  uint64_t hash1 = 12345;
  uint64_t hash2 = 54321;
  uint64_t hash3 = 99999;

  float result1 = hash_to_float_sqrt_asm(hash1);
  float result2 = hash_to_float_sqrt_asm(hash2);
  float result3 = hash_to_float_sqrt_asm(hash3);

  /* At least two should be different */
  int different = 0;
  if (fabsf(result1 - result2) > FLOAT_EPSILON)
    different++;
  if (fabsf(result1 - result3) > FLOAT_EPSILON)
    different++;
  if (fabsf(result2 - result3) > FLOAT_EPSILON)
    different++;

  tests_run++;
  if (different >= 2) {
    tests_passed++;
    printf("  ✓ PASS: Different hashes produce different values\n");
  } else {
    printf("  ✗ FAIL: Hashes produce too similar values\n");
  }

  printf("  Hash %llu -> %.6f\n", (unsigned long long)hash1, result1);
  printf("  Hash %llu -> %.6f\n", (unsigned long long)hash2, result2);
  printf("  Hash %llu -> %.6f\n", (unsigned long long)hash3, result3);
}

/**
 * Test: hash_to_float_sqrt_asm - Deterministic
 */
void test_hash_to_float_sin_deterministic() {
  printf("\n=== Test: hash_to_float_sqrt_asm - Deterministic ===\n");

  uint64_t hash = 12345;

  float result1 = hash_to_float_sqrt_asm(hash);
  float result2 = hash_to_float_sqrt_asm(hash);

  float diff = fabsf(result1 - result2);

  tests_run++;
  if (diff == 0.0f) {
    // Exact match - perfect determinism
    tests_passed++;
    printf("  ✓ PASS: Same hash produces identical value (%.6f)\n", result1);
  } else if (diff < FLOAT_EPSILON) {
    // Very close but not identical - still acceptable
    tests_passed++;
    printf("  ✓ PASS: Same hash produces same value (diff: %.10f)\n", diff);
  } else {
    printf("  ✗ FAIL: Same hash produces different values (%.10f vs %.10f, "
           "diff: %.10f)\n",
           result1, result2, diff);
  }
}

/**
 * Test: generate_combined_hash_asm - Deterministic
 */
void test_combined_hash_deterministic() {
  printf("\n=== Test: generate_combined_hash_asm - Deterministic ===\n");

  const char *text = "Hello world";
  int text_length = (int)strlen(text);
  int seed = 42;

  uint64_t hash1 = generate_combined_hash_asm(text, text_length, seed);
  uint64_t hash2 = generate_combined_hash_asm(text, text_length, seed);

  ASSERT_EQ_UINT64(hash1, hash2);
  printf("  Combined hash: %llu\n", (unsigned long long)hash1);
}

/**
 * Test: generate_combined_hash_asm - Better distribution
 */
void test_combined_hash_distribution() {
  printf("\n=== Test: generate_combined_hash_asm - Better Distribution ===\n");

  const char *texts[] = {"Hello", "World", "FastEmbed", "Test", "Different"};
  int num_texts = sizeof(texts) / sizeof(texts[0]);
  int seed = 0;

  uint64_t hashes[5];
  for (int i = 0; i < num_texts; i++) {
    hashes[i] =
        generate_combined_hash_asm(texts[i], (int)strlen(texts[i]), seed);
    printf("  '%s' -> %llu\n", texts[i], (unsigned long long)hashes[i]);
  }

  /* Check that at least some hashes are different */
  int different = 0;
  for (int i = 0; i < num_texts; i++) {
    for (int j = i + 1; j < num_texts; j++) {
      if (hashes[i] != hashes[j])
        different++;
    }
  }

  tests_run++;
  if (different >= 3) /* At least 3 pairs should be different */
  {
    tests_passed++;
    printf("  ✓ PASS: Combined hash produces good distribution\n");
  } else {
    printf("  ✗ FAIL: Combined hash produces too many collisions\n");
  }
}

/**
 * Test: generate_combined_hash_asm - Seed affects result
 */
void test_combined_hash_seed_sensitive() {
  printf("\n=== Test: generate_combined_hash_asm - Seed Sensitive ===\n");

  const char *text = "Hello";
  int text_length = (int)strlen(text);
  int seed1 = 0;
  int seed2 = 1;

  uint64_t hash1 = generate_combined_hash_asm(text, text_length, seed1);
  uint64_t hash2 = generate_combined_hash_asm(text, text_length, seed2);

  ASSERT_NE_UINT64(hash1, hash2);
  printf("  Seed 0 hash: %llu\n", (unsigned long long)hash1);
  printf("  Seed 1 hash: %llu\n", (unsigned long long)hash2);
}

int main() {
  printf("FastEmbed Hash Functions Unit Tests\n");
  printf("===================================\n");

  /* Test positional_hash_asm */
  test_positional_hash_deterministic();
  test_positional_hash_position_sensitive();
  test_positional_hash_seed_sensitive();

  /* Test hash_to_float_sqrt_asm */
  test_hash_to_float_sin_range();
  test_hash_to_float_sin_distribution();
  test_hash_to_float_sin_deterministic();

  /* Test generate_combined_hash_asm */
  test_combined_hash_deterministic();
  test_combined_hash_distribution();
  test_combined_hash_seed_sensitive();

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
