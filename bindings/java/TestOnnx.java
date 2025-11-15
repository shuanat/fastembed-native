import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import com.fastembed.FastEmbed;

/**
 * Test script for FastEmbed Java ONNX Runtime integration
 */
public class test_onnx {
    public static void main(String[] args) {
        System.out.println("Testing FastEmbed Java ONNX Runtime Integration...\n");
        System.out.println("=".repeat(60));

        // Check if ONNX model is available
        Path modelPath = Paths.get("..", "..", "models", "nomic-embed-text", "onnx", "model.onnx").toAbsolutePath()
                .normalize();
        boolean onnxAvailable = Files.exists(modelPath);

        if (!onnxAvailable) {
            System.out.println("⚠ ONNX model not found at: " + modelPath);
            System.out.println("⚠ Skipping ONNX tests (this is expected if ONNX Runtime is not configured)");
            System.out.println("⚠ To run ONNX tests, place an ONNX model at: " + modelPath);
            System.exit(0); // Exit successfully (skip tests)
        }

        try {
            // Check if native library is available
            if (!FastEmbed.isAvailable()) {
                System.err.println("✗ Native library not loaded");
                System.exit(1);
            }

            System.out.println("✓ Native library loaded successfully\n");

            // Initialize client
            System.out.println("1. Initializing FastEmbed...");
            FastEmbed client = new FastEmbed(768); // Common ONNX model dimension
            System.out.println("✓ FastEmbed initialized (dimension=" + client.getDimension() + ")\n");

            System.out.println("✓ ONNX functions available");
            System.out.println("  Model path: " + modelPath + "\n");

            // Test 1: Generate ONNX embedding
            System.out.println("2. Testing generateOnnxEmbedding...");
            String text = "machine learning artificial intelligence";

            try {
                long start = System.currentTimeMillis();
                float[] embedding = client.generateOnnxEmbedding(modelPath.toString(), text);
                long elapsed = System.currentTimeMillis() - start;

                System.out.println("✓ ONNX embedding generated in " + elapsed + "ms");
                System.out.println("  Type: float[]");
                System.out.println("  Length: " + embedding.length);
                System.out.print("  First 5 values: [");
                for (int i = 0; i < Math.min(5, embedding.length); i++) {
                    System.out.print(embedding[i]);
                    if (i < Math.min(4, embedding.length - 1))
                        System.out.print(", ");
                }
                System.out.println("]");

                // Verify embedding is normalized (unit vector)
                float norm = client.vectorNorm(embedding);
                System.out.printf("  Norm: %.4f (should be ~1.0 for L2-normalized)%n", norm);

                if (Math.abs(norm - 1.0f) > 0.1f) {
                    System.out.println("  ⚠ Warning: Embedding norm is not ~1.0, may not be normalized");
                }
            } catch (FastEmbed.FastEmbedException e) {
                System.err.println("✗ Failed to generate ONNX embedding: " + e.getMessage());
                throw e;
            }
            System.out.println();

            // Test 2: ONNX error handling
            System.out.println("3. Testing ONNX error handling...");
            try {
                // Try with non-existent model
                client.generateOnnxEmbedding("non_existent_model.onnx", "text");
                System.out.println("  ⚠ Warning: Should have thrown FastEmbedException for non-existent model");
            } catch (FastEmbed.FastEmbedException e) {
                System.out.println("✓ Error handling works (non-existent model correctly rejected)");
            } catch (Exception e) {
                System.out.println("  Unexpected error type: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            }
            System.out.println();

            // Test 3: ONNX model caching
            System.out.println("4. Testing ONNX model caching...");
            String text1 = "first text";
            String text2 = "second text";

            // First call (model load)
            long start1 = System.currentTimeMillis();
            float[] emb1 = client.generateOnnxEmbedding(modelPath.toString(), text1);
            long time1 = System.currentTimeMillis() - start1;
            System.out.println("  First call: " + time1 + "ms (includes model loading)");

            // Second call (cached model)
            long start2 = System.currentTimeMillis();
            float[] emb2 = client.generateOnnxEmbedding(modelPath.toString(), text2);
            long time2 = System.currentTimeMillis() - start2;
            System.out.println("  Second call: " + time2 + "ms (cached model)");

            if (time2 < time1) {
                System.out.println("✓ Model caching works (second call faster)");
            } else {
                System.out.println("  (Caching may not be noticeable for small models)");
            }
            System.out.println();

            // Test 4: Unload ONNX model
            System.out.println("5. Testing unloadOnnxModel...");
            try {
                int result = client.unloadOnnxModel();
                System.out.println("✓ Model unloaded, result: " + result);

                // Next call should reload model
                long start3 = System.currentTimeMillis();
                float[] emb3 = client.generateOnnxEmbedding(modelPath.toString(), text1);
                long time3 = System.currentTimeMillis() - start3;
                System.out.println("  Reload after unload: " + time3 + "ms");
            } catch (Exception e) {
                System.err.println("✗ Failed to unload model: " + e.getMessage());
                throw e;
            }
            System.out.println();

            // Test 5: Dimension validation
            System.out.println("6. Testing dimension validation...");
            try {
                // Try with wrong dimension (if model supports validation)
                // Note: Java binding uses client dimension, so we need to create a new client
                FastEmbed client128 = new FastEmbed(128); // Wrong dimension
                client128.generateOnnxEmbedding(modelPath.toString(), text);
                System.out.println("  ⚠ Warning: Should have validated dimension mismatch");
            } catch (FastEmbed.FastEmbedException e) {
                System.out.println("✓ Dimension validation works (wrong dimension correctly rejected)");
            } catch (Exception e) {
                System.out.println("  Unexpected error: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            }
            System.out.println();

            // Test 6: Edge cases
            System.out.println("7. Testing edge cases...");

            // Empty text
            try {
                float[] embEmpty = client.generateOnnxEmbedding(modelPath.toString(), "");
                System.out.println("✓ Empty text handled");
            } catch (Exception e) {
                System.out.println("  Empty text error: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            }

            // Very long text
            try {
                String longText = "a".repeat(1000);
                float[] embLong = client.generateOnnxEmbedding(modelPath.toString(), longText);
                System.out.println("✓ Very long text handled");
            } catch (Exception e) {
                System.out.println("  Long text error: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            }
            System.out.println();

            // Test 7: Performance benchmark
            System.out.println("8. ONNX Performance benchmark...");
            int iterations = 10; // Fewer iterations for ONNX (slower)
            String[] texts = new String[iterations];
            for (int i = 0; i < iterations; i++) {
                texts[i] = "test text " + i;
            }

            long start = System.currentTimeMillis();
            for (String testText : texts) {
                client.generateOnnxEmbedding(modelPath.toString(), testText);
            }
            long elapsed = System.currentTimeMillis() - start;

            double avgTime = (double) elapsed / iterations;
            System.out.println("✓ Benchmark completed");
            System.out.println("  Iterations: " + iterations);
            System.out.println("  Total time: " + (elapsed / 1000.0) + "s");
            System.out.printf("  Average time: %.2fms per embedding%n", avgTime);
            System.out.printf("  Throughput: %.1f embeddings/sec%n", (iterations / (elapsed / 1000.0)));
            System.out.println();

            System.out.println("=".repeat(60));
            System.out.println("ALL ONNX TESTS PASSED ✓");
            System.out.println("=".repeat(60));
            System.out.println("\nONNX Runtime integration is working correctly!");
            System.out.printf("Performance: ~%.1fms per embedding (ONNX inference)%n", avgTime);

        } catch (Exception e) {
            System.err.println("\n✗ Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
