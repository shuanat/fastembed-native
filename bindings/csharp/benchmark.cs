/**
 * FastEmbed C# P/Invoke Benchmark
 * 
 * Measures performance of embedding generation and vector operations
 */

using System;
using System.Diagnostics;
using FastEmbed;

class FastEmbedBenchmark
{
    const int ITERATIONS = 1000;
    const int DIMENSION = 768;

    static void Main()
    {
        Console.Out.Flush();
        Console.WriteLine("FastEmbed C# P/Invoke Benchmark");
        Console.WriteLine("================================\n");
        Console.WriteLine($"Iterations: {ITERATIONS}");
        Console.WriteLine($"Dimension: {DIMENSION}\n");
        Console.Out.Flush();

        try
        {
            var client = new FastEmbedClient(DIMENSION);

            // Test text samples
            var texts = new[]
            {
            "machine learning",
            "artificial intelligence and deep learning",
            "natural language processing with transformers",
            "computer vision and image recognition systems",
            "The quick brown fox jumps over the lazy dog and runs through the forest"
        };

            // Benchmark: Embedding Generation
            Console.WriteLine("--- Embedding Generation ---\n");

            var embResults = new System.Collections.Generic.Dictionary<string, BenchmarkResult>();
            for (int i = 0; i < texts.Length; i++)
            {
                var text = texts[i];
                var result = Benchmark(
                    $"Text {i + 1} ({text.Length} chars)",
                    () => client.GenerateEmbedding(text)
                );
                embResults[$"text{i + 1}"] = result;
            }

            // Pre-generate embeddings for vector operations
            var emb1 = client.GenerateEmbedding(texts[0]);
            var emb2 = client.GenerateEmbedding(texts[1]);

            Console.WriteLine("--- Vector Operations ---\n");

            // Benchmark: Cosine Similarity
            var cosineResult = Benchmark(
                "Cosine Similarity",
                () => client.CosineSimilarity(emb1, emb2)
            );

            // Benchmark: Dot Product
            var dotResult = Benchmark(
                "Dot Product",
                () => client.DotProduct(emb1, emb2)
            );

            // Benchmark: Vector Norm
            var normResult = Benchmark(
                "Vector Norm",
                () => client.VectorNorm(emb1)
            );

            // Benchmark: Normalize Vector
            var normalizeResult = Benchmark(
                "Normalize Vector",
                () => client.NormalizeVector(emb1)
            );

            // Benchmark: Add Vectors
            var addResult = Benchmark(
                "Add Vectors",
                () => client.AddVectors(emb1, emb2)
            );

            // Summary
            Console.WriteLine("================================");
            Console.WriteLine("Summary:");
            Console.WriteLine($"  Embedding (avg): {embResults["text1"].AvgMs:F3} ms");
            Console.WriteLine($"  Cosine Similarity: {cosineResult.AvgMs:F3} ms");
            Console.WriteLine($"  Dot Product: {dotResult.AvgMs:F3} ms");
            Console.WriteLine($"  Vector Norm: {normResult.AvgMs:F3} ms");
            Console.WriteLine("================================");
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error: {ex.Message}");
            Console.Error.WriteLine($"Stack trace: {ex.StackTrace}");
            Environment.Exit(1);
        }
    }

    static BenchmarkResult Benchmark(string name, Action fn, int iterations = ITERATIONS)
    {
        // Warmup
        for (int i = 0; i < 100; i++)
        {
            fn();
        }

        // Measure
        var sw = Stopwatch.StartNew();
        for (int i = 0; i < iterations; i++)
        {
            fn();
        }
        sw.Stop();

        var totalMs = sw.Elapsed.TotalMilliseconds;
        var avgMs = totalMs / iterations;
        var throughput = 1000.0 / avgMs;

        Console.WriteLine($"{name}:");
        Console.WriteLine($"  Avg time: {avgMs:F3} ms");
        Console.WriteLine($"  Throughput: {throughput:F0} ops/sec");
        Console.WriteLine();

        return new BenchmarkResult { AvgMs = avgMs, Throughput = throughput };
    }

    struct BenchmarkResult
    {
        public double AvgMs;
        public double Throughput;
    }
}

