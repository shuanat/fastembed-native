/**
 * FastEmbed C Example - Basic Usage
 *
 * Compile: gcc -o basic basic.c -L../build -lfastembed -lm -I../include
 * Run: LD_LIBRARY_PATH=.. ./basic
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "fastembed.h"

int main()
{
    printf("FastEmbed C Example\n");
    printf("==================\n\n");

    const int dimension = 768;

    // Generate embedding
    printf("1. Generating embedding...\n");
    float embedding[dimension];
    int result = fastembed_generate("Hello, world! This is a test.", embedding, dimension);

    if (result != 0)
    {
        fprintf(stderr, "Error: Failed to generate embedding (code: %d)\n", result);
        return 1;
    }

    printf("   ✓ Generated embedding (dimension: %d)\n", dimension);
    printf("   First 5 values: %.4f, %.4f, %.4f, %.4f, %.4f\n",
           embedding[0], embedding[1], embedding[2], embedding[3], embedding[4]);

    // Generate another embedding
    printf("\n2. Generating second embedding...\n");
    float embedding2[dimension];
    result = fastembed_generate("Goodbye, world! Another test.", embedding2, dimension);

    if (result != 0)
    {
        fprintf(stderr, "Error: Failed to generate embedding (code: %d)\n", result);
        return 1;
    }

    printf("   ✓ Generated second embedding\n");

    // Calculate cosine similarity
    printf("\n3. Calculating cosine similarity...\n");
    float similarity = fastembed_cosine_similarity(embedding, embedding2, dimension);
    printf("   ✓ Cosine similarity: %.4f\n", similarity);

    // Calculate dot product
    printf("\n4. Calculating dot product...\n");
    float dot = fastembed_dot_product(embedding, embedding2, dimension);
    printf("   ✓ Dot product: %.4f\n", dot);

    // Normalize first embedding
    printf("\n5. Normalizing first embedding...\n");
    fastembed_normalize(embedding, dimension);

    float norm = fastembed_vector_norm(embedding, dimension);
    printf("   ✓ Normalized (L2 norm: %.4f)\n", norm);

    printf("\n✓ All operations completed successfully!\n");

    return 0;
}
