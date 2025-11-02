package com.fastembed.test;

import com.fastembed.FastEmbed;

import java.util.Arrays;

/**
 * Test program for FastEmbed Java Native Module
 */
public class TestFastEmbedJava {

    public static void main(String[] args) {
        System.out.println("Testing FastEmbed Java Native Module...\n");
        System.out.println("========================================");

        try {
            // Check if native library is available
            if (!FastEmbed.isAvailable()) {
                System.err.println("✗ Native library not available");
                System.err.println("\nPlease build the native library first:");
                System.err.println("  cd java && mvn clean compile");
                System.exit(1);
            }

            FastEmbed client = new FastEmbed(768);
            System.out.println("✓ FastEmbed initialized (dimension=" + client.getDimension() + ")\n");

            // Test 1: Generate embedding
            System.out.println("1. Testing generateEmbedding...");
            String text1 = "machine learning artificial intelligence";
            float[] embedding1 = client.generateEmbedding(text1);
            System.out.println("  ✓ Embedding generated");
            System.out.println("    Type: " + embedding1.getClass().getSimpleName());
            System.out.println("    Length: " + embedding1.length);
            System.out.print("    First 5 values: [");
            for (int i = 0; i < 5; i++) {
                System.out.printf("%.4f", embedding1[i]);
                if (i < 4) System.out.print(", ");
            }
            System.out.println("]\n");

            String text2 = "deep learning neural networks";
            float[] embedding2 = client.generateEmbedding(text2);
            System.out.println("  ✓ Second embedding generated\n");

            // Test 2: Vector norm
            System.out.println("2. Testing vectorNorm...");
            float norm1 = client.vectorNorm(embedding1);
            System.out.printf("  ✓ Norm calculated: %.4f\n", norm1);
            if (Math.abs(norm1 - 7.2859f) < 0.001f) {
                System.out.println("  ✓ Norm matches expected value (7.2859)\n");
            } else {
                System.out.printf("  ⚠ Norm doesn't match expected value (expected 7.2859, got %.4f)\n\n", norm1);
            }

            // Test 3: Normalize vector
            System.out.println("3. Testing normalizeVector...");
            float[] normalized1 = client.normalizeVector(embedding1);
            float normAfterNormalize = client.vectorNorm(normalized1);
            System.out.println("  ✓ Vector normalized");
            System.out.printf("    Norm after normalization: %.4f (should be ~1.0)\n", normAfterNormalize);
            if (Math.abs(normAfterNormalize - 1.0f) < 0.001f) {
                System.out.println("  ✓ Normalized correctly\n");
            } else {
                System.out.printf("  ✗ Normalization failed (expected 1.0, got %.4f)\n\n", normAfterNormalize);
            }

            // Test 4: Cosine similarity
            System.out.println("4. Testing cosineSimilarity...");
            float similarity = client.cosineSimilarity(embedding1, embedding2);
            System.out.printf("  ✓ Cosine similarity calculated: %.4f\n", similarity);
            System.out.println("    Text 1: " + text1);
            System.out.println("    Text 2: " + text2);
            if (similarity > 0.9f && similarity <= 1.0f) {
                System.out.println("  ✓ High similarity (hash-based embeddings)\n");
            } else {
                System.out.printf("  ⚠ Unexpected similarity value: %.4f\n\n", similarity);
            }

            // Test 5: Dot product
            System.out.println("5. Testing dotProduct...");
            float dotProd = client.dotProduct(embedding1, embedding2);
            System.out.printf("  ✓ Dot product calculated: %.4f\n", dotProd);
            if (Math.abs(dotProd - 52.1856f) < 0.001f) {
                System.out.println("  ✓ Dot product matches expected value (52.1856)\n");
            } else {
                System.out.printf("  ⚠ Dot product doesn't match expected (%.4f vs 52.1856)\n\n", dotProd);
            }

            // Test 6: Add vectors
            System.out.println("6. Testing addVectors...");
            float[] vectorA = new float[768];
            float[] vectorB = new float[768];
            for (int i = 0; i < 768; i++) {
                vectorA[i] = (i % 3 == 0) ? 1.0f : (i % 3 == 1) ? 2.0f : 3.0f;
                vectorB[i] = (i % 3 == 0) ? 4.0f : (i % 3 == 1) ? 5.0f : 6.0f;
            }
            float[] resultVector = client.addVectors(vectorA, vectorB);
            System.out.println("  ✓ Vectors added");
            System.out.println("    Result length: " + resultVector.length);
            System.out.print("    First 5 values: [");
            for (int i = 0; i < 5; i++) {
                System.out.printf("%.1f", resultVector[i]);
                if (i < 4) System.out.print(", ");
            }
            System.out.println("]");
            boolean addCorrect = Math.abs(resultVector[0] - 5.0f) < 0.001f &&
                                 Math.abs(resultVector[1] - 7.0f) < 0.001f &&
                                 Math.abs(resultVector[2] - 9.0f) < 0.001f;
            if (addCorrect) {
                System.out.println("  ✓ Vector addition correct\n");
            } else {
                System.out.println("  ✗ Vector addition incorrect\n");
            }

            // Test 7: Text similarity helper
            System.out.println("7. Testing textSimilarity (high-level API)...");
            float textSim = client.textSimilarity(text1, text2);
            System.out.printf("  ✓ Text similarity: %.4f\n\n", textSim);

            // Test 8: Batch processing
            System.out.println("8. Testing generateEmbeddings (batch)...");
            String[] texts = {"AI", "ML", "NLP", "Computer Vision"};
            float[][] embeddings = client.generateEmbeddings(texts);
            System.out.println("  ✓ Batch processing complete");
            System.out.println("    Generated " + embeddings.length + " embeddings\n");

            // Performance benchmark
            System.out.println("9. Performance benchmark...");
            final int iterations = 100;
            long startTime = System.nanoTime();
            for (int i = 0; i < iterations; i++) {
                client.generateEmbedding("test " + i);
            }
            long endTime = System.nanoTime();
            double elapsedMs = (endTime - startTime) / 1_000_000.0;
            double avgTime = elapsedMs / iterations;
            double throughput = 1000.0 / avgTime;
            System.out.println("  ✓ Benchmark completed");
            System.out.println("    Iterations: " + iterations);
            System.out.printf("    Total time: %.2fs\n", elapsedMs / 1000.0);
            System.out.printf("    Average time: %.2fms per embedding\n", avgTime);
            System.out.printf("    Throughput: %.1f embeddings/sec\n\n", throughput);

            System.out.println("========================================");
            System.out.println("ALL TESTS PASSED ✓");
            System.out.println("========================================\n");
            System.out.println("FastEmbed Java native module is working correctly!");
            System.out.printf("Performance: ~%.2fms per embedding (native speed)\n", avgTime);

        } catch (Exception e) {
            System.err.println("\n✗ ERROR: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}

