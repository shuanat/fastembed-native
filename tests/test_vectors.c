/**
 * Simple vector operations test
 */
#include <stdio.h>
#include "fastembed.h"

int main(void)
{
    printf("=== FastEmbed Vector Operations Test ===\n\n");

    /* Test dot product */
    float v1[3] = {1.0f, 2.0f, 3.0f};
    float v2[3] = {4.0f, 5.0f, 6.0f};
    float dot = fastembed_dot_product(v1, v2, 3);
    float expected_dot = 1.0f * 4.0f + 2.0f * 5.0f + 3.0f * 6.0f; // 32.0
    printf("Dot Product: %.2f (expected: %.2f) - %s\n",
           dot, expected_dot, (dot > 31.9f && dot < 32.1f) ? "✓ PASS" : "✗ FAIL");

    /* Test cosine similarity */
    float v3[2] = {1.0f, 0.0f};
    float v4[2] = {0.0f, 1.0f};
    float cos = fastembed_cosine_similarity(v3, v4, 2);
    printf("Cosine Similarity (orthogonal): %.4f (expected: ~0.0) - %s\n",
           cos, (cos > -0.1f && cos < 0.1f) ? "✓ PASS" : "✗ FAIL");

    /* Test vector norm */
    float v5[3] = {3.0f, 4.0f, 0.0f};
    float norm = fastembed_vector_norm(v5, 3);
    float expected_norm = 5.0f; // sqrt(3^2 + 4^2 + 0^2) = 5
    printf("Vector Norm: %.4f (expected: %.4f) - %s\n",
           norm, expected_norm, (norm > 4.9f && norm < 5.1f) ? "✓ PASS" : "✗ FAIL");

    printf("\n=== Test Complete ===\n");
    return 0;
}
