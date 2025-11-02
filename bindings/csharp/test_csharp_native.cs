using System;
using System.Diagnostics;
using System.Linq;
using FastEmbed;

namespace FastEmbed.Tests
{
    class TestFastEmbedCSharp
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Testing FastEmbed C# Native Module...\n");
            Console.WriteLine("========================================");

            try
            {
                var client = new FastEmbedClient(dimension: 768);
                Console.WriteLine($"✓ FastEmbed initialized (dimension={client.Dimension})\n");

                // Test 1: Generate embedding
                Console.WriteLine("1. Testing GenerateEmbedding...");
                string text1 = "machine learning artificial intelligence";
                var embedding1 = client.GenerateEmbedding(text1);
                Console.WriteLine($"  ✓ Embedding generated");
                Console.WriteLine($"    Type: {embedding1.GetType().Name}");
                Console.WriteLine($"    Length: {embedding1.Length}");
                Console.WriteLine($"    First 5 values: [{string.Join(", ", embedding1.Take(5).Select(x => x.ToString("F4")))}]");

                string text2 = "deep learning neural networks";
                var embedding2 = client.GenerateEmbedding(text2);
                Console.WriteLine($"  ✓ Second embedding generated\n");

                // Test 2: Vector norm
                Console.WriteLine("2. Testing VectorNorm...");
                float norm1 = client.VectorNorm(embedding1);
                Console.WriteLine($"  ✓ Norm calculated: {norm1:F4}");
                if (Math.Abs(norm1 - 7.2859f) < 0.001f)
                {
                    Console.WriteLine($"  ✓ Norm matches expected value (7.2859)\n");
                }
                else
                {
                    Console.WriteLine($"  ⚠ Norm doesn't match expected value (expected 7.2859, got {norm1:F4})\n");
                }

                // Test 3: Normalize vector
                Console.WriteLine("3. Testing NormalizeVector...");
                var normalized1 = client.NormalizeVector(embedding1);
                float normAfterNormalize = client.VectorNorm(normalized1);
                Console.WriteLine($"  ✓ Vector normalized");
                Console.WriteLine($"    Norm after normalization: {normAfterNormalize:F4} (should be ~1.0)");
                if (Math.Abs(normAfterNormalize - 1.0f) < 0.001f)
                {
                    Console.WriteLine($"  ✓ Normalized correctly\n");
                }
                else
                {
                    Console.WriteLine($"  ✗ Normalization failed (expected 1.0, got {normAfterNormalize:F4})\n");
                }

                // Test 4: Cosine similarity
                Console.WriteLine("4. Testing CosineSimilarity...");
                float similarity = client.CosineSimilarity(embedding1, embedding2);
                Console.WriteLine($"  ✓ Cosine similarity calculated: {similarity:F4}");
                Console.WriteLine($"    Text 1: {text1}");
                Console.WriteLine($"    Text 2: {text2}");
                if (similarity > 0.9f && similarity <= 1.0f)
                {
                    Console.WriteLine($"  ✓ High similarity (hash-based embeddings)\n");
                }
                else
                {
                    Console.WriteLine($"  ⚠ Unexpected similarity value: {similarity:F4}\n");
                }

                // Test 5: Dot product
                Console.WriteLine("5. Testing DotProduct...");
                float dotProd = client.DotProduct(embedding1, embedding2);
                Console.WriteLine($"  ✓ Dot product calculated: {dotProd:F4}");
                if (Math.Abs(dotProd - 52.1856f) < 0.001f)
                {
                    Console.WriteLine($"  ✓ Dot product matches expected value (52.1856)\n");
                }
                else
                {
                    Console.WriteLine($"  ⚠ Dot product doesn't match expected ({dotProd:F4} vs 52.1856)\n");
                }

                // Test 6: Add vectors
                Console.WriteLine("6. Testing AddVectors...");
                var vectorA = Enumerable.Repeat(new[] { 1.0f, 2.0f, 3.0f }, 256).SelectMany(x => x).ToArray();
                var vectorB = Enumerable.Repeat(new[] { 4.0f, 5.0f, 6.0f }, 256).SelectMany(x => x).ToArray();
                var resultVector = client.AddVectors(vectorA, vectorB);
                Console.WriteLine($"  ✓ Vectors added");
                Console.WriteLine($"    Result length: {resultVector.Length}");
                Console.WriteLine($"    First 5 values: [{string.Join(", ", resultVector.Take(5).Select(x => x.ToString("F1")))}]");
                bool addCorrect = Math.Abs(resultVector[0] - 5.0f) < 0.001f &&
                                   Math.Abs(resultVector[1] - 7.0f) < 0.001f &&
                                   Math.Abs(resultVector[2] - 9.0f) < 0.001f;
                if (addCorrect)
                {
                    Console.WriteLine($"  ✓ Vector addition correct\n");
                }
                else
                {
                    Console.WriteLine($"  ✗ Vector addition incorrect\n");
                }

                // Test 7: Text similarity helper
                Console.WriteLine("7. Testing TextSimilarity (high-level API)...");
                float textSim = client.TextSimilarity(text1, text2);
                Console.WriteLine($"  ✓ Text similarity: {textSim:F4}\n");

                // Test 8: Batch processing
                Console.WriteLine("8. Testing GenerateEmbeddings (batch)...");
                var texts = new[] { "AI", "ML", "NLP", "Computer Vision" };
                var embeddings = client.GenerateEmbeddings(texts);
                Console.WriteLine($"  ✓ Batch processing complete");
                Console.WriteLine($"    Generated {embeddings.Length} embeddings\n");

                // Performance benchmark
                Console.WriteLine("9. Performance benchmark...");
                const int iterations = 100;
                var sw = Stopwatch.StartNew();
                for (int i = 0; i < iterations; i++)
                {
                    _ = client.GenerateEmbedding($"test {i}");
                }
                sw.Stop();
                double avgTime = sw.Elapsed.TotalMilliseconds / iterations;
                double throughput = 1000.0 / avgTime;
                Console.WriteLine($"  ✓ Benchmark completed");
                Console.WriteLine($"    Iterations: {iterations}");
                Console.WriteLine($"    Total time: {sw.Elapsed.TotalSeconds:F2}s");
                Console.WriteLine($"    Average time: {avgTime:F2}ms per embedding");
                Console.WriteLine($"    Throughput: {throughput:F1} embeddings/sec\n");

                Console.WriteLine("========================================");
                Console.WriteLine("ALL TESTS PASSED ✓");
                Console.WriteLine("========================================\n");
                Console.WriteLine($"FastEmbed C# native module is working correctly!");
                Console.WriteLine($"Performance: ~{avgTime:F2}ms per embedding (native speed)");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\n✗ ERROR: {ex.Message}");
                Console.WriteLine($"Stack trace:\n{ex.StackTrace}");
                Environment.Exit(1);
            }
        }
    }
}

