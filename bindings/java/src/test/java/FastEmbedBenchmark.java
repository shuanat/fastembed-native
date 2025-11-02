/**
 * FastEmbed Java JNI Benchmark
 * 
 * Measures performance of embedding generation and vector operations
 */

package com.fastembed;

public class FastEmbedBenchmark {
    private static final int ITERATIONS = 1000;
    private static final int DIMENSION = 768;

    public static void main(String[] args) {
        System.out.println("FastEmbed Java JNI Benchmark");
        System.out.println("============================\n");
        System.out.println("Iterations: " + ITERATIONS);
        System.out.println("Dimension: " + DIMENSION + "\n");

        FastEmbed client = new FastEmbed(DIMENSION);

        // Test text samples
        String[] texts = {
            "machine learning",
            "artificial intelligence and deep learning",
            "natural language processing with transformers",
            "computer vision and image recognition systems",
            "The quick brown fox jumps over the lazy dog and runs through the forest"
        };

        // Benchmark: Embedding Generation
        System.out.println("--- Embedding Generation ---\n");

        for (int i = 0; i < texts.length; i++) {
            String text = texts[i];
            benchmark(
                String.format("Text %d (%d chars)", i + 1, text.length()),
                () -> client.generateEmbedding(text)
            );
        }

        // Pre-generate embeddings for vector operations
        float[] emb1 = client.generateEmbedding(texts[0]);
        float[] emb2 = client.generateEmbedding(texts[1]);

        System.out.println("--- Vector Operations ---\n");

        // Benchmark: Cosine Similarity
        benchmark("Cosine Similarity", () -> client.cosineSimilarity(emb1, emb2));

        // Benchmark: Dot Product
        benchmark("Dot Product", () -> client.dotProduct(emb1, emb2));

        // Benchmark: Vector Norm
        benchmark("Vector Norm", () -> client.vectorNorm(emb1));

        // Benchmark: Normalize Vector
        benchmark("Normalize Vector", () -> client.normalizeVector(emb1));

        // Benchmark: Add Vectors
        benchmark("Add Vectors", () -> client.addVectors(emb1, emb2));

        System.out.println("============================");
        System.out.println("Benchmark completed!");
        System.out.println("============================");
    }

    static void benchmark(String name, Runnable fn) {
        benchmark(name, fn, ITERATIONS);
    }

    static void benchmark(String name, Runnable fn, int iterations) {
        // Warmup
        for (int i = 0; i < 100; i++) {
            fn.run();
        }

        // Measure
        long start = System.nanoTime();
        for (int i = 0; i < iterations; i++) {
            fn.run();
        }
        long end = System.nanoTime();

        long totalNs = end - start;
        double avgNs = (double) totalNs / iterations;
        double avgMs = avgNs / 1_000_000.0;
        double throughput = 1_000_000_000.0 / avgNs;

        System.out.println(name + ":");
        System.out.printf("  Avg time: %.3f ms%n", avgMs);
        System.out.printf("  Throughput: %,d ops/sec%n", (int) throughput);
        System.out.println();
    }
}

