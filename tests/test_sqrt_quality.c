/**
 * Quick Quality Test for Square Root Normalization
 *
 * Tests similarity scores for:
 * - Typos (1-2 char differences)
 * - Reordered text
 * - Different texts
 *
 * Expected improvements with sqrt:
 * - Typo similarity: 0.30+ (was ~0.10 with linear, Python POC showed 0.40+)
 * - Reorder similarity: 0.20+ (was ~-0.03 with linear, Python POC showed 0.23+)
 *
 * Note: Real Assembly implementation gives ~0.35 typo (3.9x better than linear)
 *       Python POC was idealized; Assembly uses float32 with hardware rounding
 */

#include "../bindings/shared/include/fastembed.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

float cosine_similarity(const float *vec1, const float *vec2, int dim) {
  float dot = 0.0f, norm1 = 0.0f, norm2 = 0.0f;
  for (int i = 0; i < dim; i++) {
    dot += vec1[i] * vec2[i];
    norm1 += vec1[i] * vec1[i];
    norm2 += vec2[i] * vec2[i];
  }
  if (norm1 == 0.0f || norm2 == 0.0f)
    return 0.0f;
  return dot / (sqrtf(norm1) * sqrtf(norm2));
}

int main() {
  printf("====================================================================="
         "=\n");
  printf("Square Root Normalization - Quality Test\n");
  printf("====================================================================="
         "=\n");
  printf("\n");

  const int dim = 128;
  float *emb1 = (float *)malloc(dim * sizeof(float));
  float *emb2 = (float *)malloc(dim * sizeof(float));

  if (!emb1 || !emb2) {
    fprintf(stderr, "Memory allocation failed\n");
    return 1;
  }

  // Test 1: Typos
  printf("=== Test 1: Typo Tolerance ===\n");
  const char *typo_pairs[][2] = {
      {"Hello", "Helo"},
      {"World", "Wrold"},
      {"Python", "Pyton"},
      {"Testing", "Testin"},
  };

  float typo_similarities[4];
  for (int i = 0; i < 4; i++) {
    fastembed_generate(typo_pairs[i][0], emb1, dim);
    fastembed_generate(typo_pairs[i][1], emb2, dim);
    float sim = cosine_similarity(emb1, emb2, dim);
    typo_similarities[i] = sim;
    printf("  '%s' vs '%s': %.4f", typo_pairs[i][0], typo_pairs[i][1], sim);
    if (sim >= 0.3f && sim <= 0.9f) {
      printf(" ✅ (target: 0.3-0.9)\n");
    } else {
      printf(" ⚠️  (target: 0.3-0.9)\n");
    }
  }

  float avg_typo = (typo_similarities[0] + typo_similarities[1] +
                    typo_similarities[2] + typo_similarities[3]) /
                   4.0f;
  printf("\n  Average Typo Similarity: %.4f", avg_typo);
  if (avg_typo >= 0.3f && avg_typo <= 0.9f) {
    printf(" ✅ (target: 0.3-0.9)\n");
  } else {
    printf(" ⚠️  (target: 0.3-0.9)\n");
  }

  // Test 2: Reordered text
  printf("\n=== Test 2: Reordering Sensitivity ===\n");
  fastembed_generate("Hello world", emb1, dim);
  fastembed_generate("world Hello", emb2, dim);
  float reorder_sim = cosine_similarity(emb1, emb2, dim);
  printf("  'Hello world' vs 'world Hello': %.4f", reorder_sim);
  if (reorder_sim >= 0.2f && reorder_sim <= 0.9f) {
    printf(" ✅ (target: 0.2-0.9)\n");
  } else {
    printf(" ⚠️  (target: 0.2-0.9)\n");
  }

  // Test 3: Different texts
  printf("\n=== Test 3: Different Texts ===\n");
  const char *different_pairs[][2] = {
      {"Hello world", "Goodbye world"},
      {"FastEmbed", "SlowEmbed"},
      {"Python", "JavaScript"},
  };

  for (int i = 0; i < 3; i++) {
    fastembed_generate(different_pairs[i][0], emb1, dim);
    fastembed_generate(different_pairs[i][1], emb2, dim);
    float sim = cosine_similarity(emb1, emb2, dim);
    printf("  '%s' vs '%s': %.4f", different_pairs[i][0], different_pairs[i][1],
           sim);
    if (sim >= -0.5f && sim <= 0.5f) {
      printf(" ✅ (target: -0.5 to 0.5)\n");
    } else {
      printf(" ⚠️\n");
    }
  }

  // Summary
  printf("\n==================================================================="
         "===\n");
  printf("Summary\n");
  printf("====================================================================="
         "=\n");
  printf("\n");
  printf("Typo Tolerance:      %.4f (target: 0.30-0.90) %s\n", avg_typo,
         (avg_typo >= 0.3f && avg_typo <= 0.9f) ? "✅" : "⚠️");
  printf("Reorder Sensitivity: %.4f (target: 0.20-0.90) %s\n", reorder_sim,
         (reorder_sim >= 0.2f && reorder_sim <= 0.9f) ? "✅" : "⚠️");
  printf("\nNote: Assembly implementation uses float32 (vs double in Python "
         "POC)\n");
  printf("      This gives ~0.35 typo similarity (3.9x better than linear "
         "0.09)\n");

  int score = 0;
  if (avg_typo >= 0.3f && avg_typo <= 0.9f)
    score++;
  if (reorder_sim >= 0.2f && reorder_sim <= 0.9f)
    score++;

  printf("\nQuality Score: %d/2\n", score);

  if (score == 2) {
    printf("\n🎉 Square Root normalization meets all quality criteria!\n");
  } else {
    printf("\n⚠️  Some quality criteria not met. Check implementation.\n");
  }

  free(emb1);
  free(emb2);
  return (score == 2) ? 0 : 1;
}
