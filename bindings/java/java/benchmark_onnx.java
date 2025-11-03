import java.io.File;

import com.fastembed.FastEmbed;

public class benchmark_onnx {
    private static final int DIMENSION = 768;

    // Test texts with different lengths (identical to Node.js/Python/C#)
    private static final String SHORT_TEXT = "machine learning algorithms and neural networks for artificial intelligence applications in computer science";
    private static final String MEDIUM_TEXT = "Machine learning is a subset of artificial intelligence that focuses on developing algorithms capable of learning from data without being explicitly programmed. These algorithms can identify patterns, make predictions, and improve their performance over time through experience. Neural networks, a key component of modern machine learning, are inspired by the structure of the human brain and consist of interconnected nodes that process information in layers.";
    private static final String LONG_TEXT = "Machine learning represents a revolutionary approach to artificial intelligence that has transformed numerous industries and applications. At its core, machine learning involves the creation of algorithms that can learn from data, identify patterns, and make decisions with minimal human intervention. This field encompasses various techniques, including supervised learning where models are trained on labeled datasets, unsupervised learning that discovers hidden patterns in unlabeled data, and reinforcement learning where agents learn through interaction with their environment.\n\nNeural networks, particularly deep neural networks, have become the cornerstone of modern machine learning. These sophisticated systems consist of multiple layers of interconnected nodes, or neurons, that process information in a hierarchical manner. The depth and complexity of these networks enable them to capture intricate relationships in data, making them exceptionally powerful for tasks such as image recognition, natural language processing, and predictive analytics.\n\nThe applications of machine learning are vast and continue to expand. In healthcare, ML models assist in disease diagnosis and drug discovery. In finance, they power fraud detection systems and algorithmic trading. In transportation, they enable autonomous vehicles to navigate complex environments. As the field evolves, the integration of machine learning into everyday technology becomes increasingly seamless, promising a future where intelligent systems enhance human capabilities in unprecedented ways.";

    private static final int WARMUP_ITERATIONS = 10;
    private static final int BENCHMARK_ITERATIONS = 100;
    private static final int ITERATIONS_BATCH = 10;
    private static final int[] BATCH_SIZES = { 1, 10, 100 };

    public static void main(String[] args) {
        String modelPath = "../../../models/nomic-embed-text.onnx";

        if (args.length > 0) {
            modelPath = args[0];
        }

        File modelFile = new File(modelPath);
        if (!modelFile.exists()) {
            System.err.println("ERROR: ONNX model not found at: " + modelPath);
            System.err.println("Please download the model first or provide the correct path.");
            System.exit(1);
        }

        System.out.println("========================================");
        System.out.println("FastEmbed Java ONNX Benchmark");
        System.out.println("========================================");
        System.out.println("Model: " + modelPath);
        System.out.println("Dimension: " + DIMENSION);
        System.out.println();

        try {
            FastEmbed embedder = new FastEmbed(DIMENSION);

            // Test hash-based embeddings
            System.out.println("--- Hash-Based Embeddings ---");
            benchmarkHash(embedder, "Short text", SHORT_TEXT);
            benchmarkHash(embedder, "Medium text", MEDIUM_TEXT);
            benchmarkHash(embedder, "Long text", LONG_TEXT);

            // Test ONNX embeddings
            System.out.println("\n--- ONNX-Based Embeddings ---");
            benchmarkOnnx(embedder, modelPath, "Short text", SHORT_TEXT);
            benchmarkOnnx(embedder, modelPath, "Medium text", MEDIUM_TEXT);
            benchmarkOnnx(embedder, modelPath, "Long text", LONG_TEXT);

            // Quality comparison
            System.out.println("\n--- Quality Comparison ---");
            compareQuality(embedder, modelPath);

            // Batch processing benchmarks
            System.out.println("\n\n--- Batch Processing ---\n");
            String[] textList = { SHORT_TEXT, MEDIUM_TEXT, LONG_TEXT };
            for (int batchSize : BATCH_SIZES) {
                System.out.println("\nBatch size: " + batchSize);
                System.out.println("--------------------------------------------------");

                // Hash-based batch
                System.out.println("Hash-based batch:");
                benchmarkBatchHash(embedder, batchSize, textList);

                // ONNX batch
                System.out.println("\nONNX-based batch:");
                benchmarkBatchOnnx(embedder, modelPath, batchSize, textList);
            }

            // Cleanup
            embedder.unloadOnnxModel();

        } catch (Exception e) {
            System.err.println("ERROR: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static void benchmarkHash(FastEmbed embedder, String label, String text) {
        // Warmup
        for (int i = 0; i < WARMUP_ITERATIONS; i++) {
            embedder.generateEmbedding(text);
        }

        // Benchmark
        long start = System.nanoTime();
        for (int i = 0; i < BENCHMARK_ITERATIONS; i++) {
            embedder.generateEmbedding(text);
        }
        long end = System.nanoTime();

        double avgTime = (end - start) / 1_000_000.0 / BENCHMARK_ITERATIONS;
        double throughput = 1000.0 / avgTime;

        System.out.printf("%s: %.3f ms/req, %.1f req/s, %.1f tokens/s%n",
                label, avgTime, throughput, (text.split("\\s+").length * throughput));
    }

    private static void benchmarkOnnx(FastEmbed embedder, String modelPath, String label, String text) {
        // Warmup
        for (int i = 0; i < WARMUP_ITERATIONS; i++) {
            embedder.generateOnnxEmbedding(modelPath, text);
        }

        // Force GC before measurement (like Node.js/Python)
        System.gc();
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
        }
        System.gc();

        // Measure memory before
        long memBefore = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();

        // Benchmark
        long start = System.nanoTime();
        for (int i = 0; i < BENCHMARK_ITERATIONS; i++) {
            embedder.generateOnnxEmbedding(modelPath, text);
        }
        long end = System.nanoTime();

        // Measure memory after
        System.gc();
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
        }
        long memAfter = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();

        double avgTime = (end - start) / 1_000_000.0 / BENCHMARK_ITERATIONS;
        double throughput = 1000.0 / avgTime;
        double memDeltaMB = (memAfter - memBefore) / 1024.0 / 1024.0;

        System.out.printf("%s: %.3f ms/req, %.1f req/s, %.1f tokens/s, Memory: %.3f MB%n",
                label, avgTime, throughput, (text.split("\\s+").length * throughput), memDeltaMB);
    }

    private static void benchmarkBatchHash(FastEmbed embedder, int batchSize, String[] textList) {
        // Warmup
        for (int i = 0; i < WARMUP_ITERATIONS; i++) {
            for (int j = 0; j < batchSize; j++) {
                embedder.generateEmbedding(textList[j % textList.length]);
            }
        }

        // Benchmark
        long start = System.nanoTime();
        for (int i = 0; i < ITERATIONS_BATCH; i++) {
            for (int j = 0; j < batchSize; j++) {
                embedder.generateEmbedding(textList[j % textList.length]);
            }
        }
        long end = System.nanoTime();

        double avgTimeBatch = (end - start) / 1_000_000.0 / ITERATIONS_BATCH;
        double avgTimePerEmbedding = avgTimeBatch / batchSize;
        double throughput = 1000.0 / avgTimePerEmbedding;

        System.out.printf("  Avg time per batch: %.3f ms%n", avgTimeBatch);
        System.out.printf("  Time per embedding: %.3f ms%n", avgTimePerEmbedding);
        System.out.printf("  Throughput: %,.0f embeddings/sec%n", throughput);
    }

    private static void benchmarkBatchOnnx(FastEmbed embedder, String modelPath, int batchSize, String[] textList) {
        // Warmup
        for (int i = 0; i < WARMUP_ITERATIONS; i++) {
            for (int j = 0; j < batchSize; j++) {
                embedder.generateOnnxEmbedding(modelPath, textList[j % textList.length]);
            }
        }

        // Benchmark
        long start = System.nanoTime();
        for (int i = 0; i < ITERATIONS_BATCH; i++) {
            for (int j = 0; j < batchSize; j++) {
                embedder.generateOnnxEmbedding(modelPath, textList[j % textList.length]);
            }
        }
        long end = System.nanoTime();

        double avgTimeBatch = (end - start) / 1_000_000.0 / ITERATIONS_BATCH;
        double avgTimePerEmbedding = avgTimeBatch / batchSize;
        double throughput = 1000.0 / avgTimePerEmbedding;

        System.out.printf("  Avg time per batch: %.3f ms%n", avgTimeBatch);
        System.out.printf("  Time per embedding: %.3f ms%n", avgTimePerEmbedding);
        System.out.printf("  Throughput: %,.0f embeddings/sec%n", throughput);
    }

    private static void compareQuality(FastEmbed embedder, String modelPath) {
        String text1 = "The cat sat on the mat";
        String text2 = "The feline rested on the rug";
        String text3 = "I like programming in Java";

        try {
            // Hash-based embeddings
            float[] hash1 = embedder.generateEmbedding(text1);
            float[] hash2 = embedder.generateEmbedding(text2);
            float[] hash3 = embedder.generateEmbedding(text3);

            float hashSim12 = embedder.cosineSimilarity(hash1, hash2);
            float hashSim13 = embedder.cosineSimilarity(hash1, hash3);

            // ONNX embeddings
            float[] onnx1 = embedder.generateOnnxEmbedding(modelPath, text1);
            float[] onnx2 = embedder.generateOnnxEmbedding(modelPath, text2);
            float[] onnx3 = embedder.generateOnnxEmbedding(modelPath, text3);

            float onnxSim12 = embedder.cosineSimilarity(onnx1, onnx2);
            float onnxSim13 = embedder.cosineSimilarity(onnx1, onnx3);

            System.out.printf("Text similarity (semantically similar):%n");
            System.out.printf("  Hash-based: %.4f%n", hashSim12);
            System.out.printf("  ONNX-based: %.4f%n", onnxSim12);

            System.out.printf("Text similarity (semantically different):%n");
            System.out.printf("  Hash-based: %.4f%n", hashSim13);
            System.out.printf("  ONNX-based: %.4f%n", onnxSim13);

            System.out.printf("ONNX captures semantics better: %s%n",
                    (onnxSim12 > onnxSim13 && hashSim12 <= hashSim13 + 0.1) ? "YES" : "NO");

        } catch (Exception e) {
            System.err.println("ERROR in quality comparison: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
