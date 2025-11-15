using System;
using System.Diagnostics;
using Xunit;
using FastEmbed;

namespace FastEmbed.Tests
{
    /// <summary>
    /// Performance benchmarks for FastEmbed library
    /// Tests critical operations performance per CONTRIBUTING.md requirements
    /// </summary>
    public class FastEmbedPerformanceTests
    {
        private const int DefaultDimension = 128;
        private const int BenchmarkIterations = 1000;

        [Fact]
        public void GenerateEmbedding_Performance_Benchmark()
        {
            // Performance benchmark: embedding generation
            var client = new FastEmbedClient(DefaultDimension);
            var text = "machine learning artificial intelligence";

            // Warmup
            client.GenerateEmbedding(text);

            var stopwatch = Stopwatch.StartNew();
            for (int i = 0; i < BenchmarkIterations; i++)
            {
                client.GenerateEmbedding(text);
            }
            stopwatch.Stop();

            var avgTime = stopwatch.ElapsedMilliseconds / (double)BenchmarkIterations;
            var avgTimeMs = avgTime;

            // Log performance (not asserting - just benchmarking)
            Console.WriteLine($"GenerateEmbedding average time: {avgTimeMs:F4} ms per embedding");
            Console.WriteLine($"Throughput: {1000.0 / avgTimeMs:F0} embeddings/second");

            // Performance should be reasonable (< 10ms per embedding for 128D)
            Assert.True(avgTimeMs < 10.0, $"Embedding generation should be fast (< 10ms), got {avgTimeMs:F4} ms");
        }

        [Fact]
        public void CosineSimilarity_Performance_Benchmark()
        {
            // Performance benchmark: cosine similarity
            var client = new FastEmbedClient(DefaultDimension);
            var text1 = "machine learning";
            var text2 = "artificial intelligence";

            var emb1 = client.GenerateEmbedding(text1);
            var emb2 = client.GenerateEmbedding(text2);

            // Warmup
            client.CosineSimilarity(emb1, emb2);

            var stopwatch = Stopwatch.StartNew();
            for (int i = 0; i < BenchmarkIterations; i++)
            {
                client.CosineSimilarity(emb1, emb2);
            }
            stopwatch.Stop();

            var avgTime = stopwatch.ElapsedMilliseconds / (double)BenchmarkIterations;
            var avgTimeMs = avgTime;

            // Log performance
            Console.WriteLine($"CosineSimilarity average time: {avgTimeMs:F4} ms");
            Console.WriteLine($"Throughput: {1000.0 / avgTimeMs:F0} operations/second");

            // Performance should be very fast (< 1ms for 128D)
            Assert.True(avgTimeMs < 1.0, $"Cosine similarity should be very fast (< 1ms), got {avgTimeMs:F4} ms");
        }

        [Fact]
        public void VectorNorm_Performance_Benchmark()
        {
            // Performance benchmark: vector norm
            var client = new FastEmbedClient(DefaultDimension);
            var text = "test text";
            var embedding = client.GenerateEmbedding(text);

            // Warmup
            client.VectorNorm(embedding);

            var stopwatch = Stopwatch.StartNew();
            for (int i = 0; i < BenchmarkIterations; i++)
            {
                client.VectorNorm(embedding);
            }
            stopwatch.Stop();

            var avgTime = stopwatch.ElapsedMilliseconds / (double)BenchmarkIterations;
            var avgTimeMs = avgTime;

            // Log performance
            Console.WriteLine($"VectorNorm average time: {avgTimeMs:F4} ms");
            Console.WriteLine($"Throughput: {1000.0 / avgTimeMs:F0} operations/second");

            // Performance should be very fast (< 0.5ms for 128D)
            Assert.True(avgTimeMs < 0.5, $"Vector norm should be very fast (< 0.5ms), got {avgTimeMs:F4} ms");
        }

        [Fact]
        public void NormalizeVector_Performance_Benchmark()
        {
            // Performance benchmark: vector normalization
            var client = new FastEmbedClient(DefaultDimension);
            var text = "test text";
            var embedding = client.GenerateEmbedding(text);

            // Warmup
            client.NormalizeVector(embedding);

            var stopwatch = Stopwatch.StartNew();
            for (int i = 0; i < BenchmarkIterations; i++)
            {
                client.NormalizeVector(embedding);
            }
            stopwatch.Stop();

            var avgTime = stopwatch.ElapsedMilliseconds / (double)BenchmarkIterations;
            var avgTimeMs = avgTime;

            // Log performance
            Console.WriteLine($"NormalizeVector average time: {avgTimeMs:F4} ms");
            Console.WriteLine($"Throughput: {1000.0 / avgTimeMs:F0} operations/second");

            // Performance should be fast (< 1ms for 128D)
            Assert.True(avgTimeMs < 1.0, $"Vector normalization should be fast (< 1ms), got {avgTimeMs:F4} ms");
        }

        [Fact]
        public void BatchGeneration_Performance_Benchmark()
        {
            // Performance benchmark: batch generation
            var client = new FastEmbedClient(DefaultDimension);
            var texts = new[]
            {
                "machine learning",
                "artificial intelligence",
                "deep learning",
                "neural networks",
                "natural language processing"
            };

            // Warmup
            client.GenerateEmbeddings(texts);

            var stopwatch = Stopwatch.StartNew();
            for (int i = 0; i < 100; i++) // Fewer iterations for batch
            {
                client.GenerateEmbeddings(texts);
            }
            stopwatch.Stop();

            var totalTime = stopwatch.ElapsedMilliseconds;
            var avgTimePerBatch = totalTime / 100.0;
            var avgTimePerEmbedding = avgTimePerBatch / texts.Length;

            // Log performance
            Console.WriteLine($"BatchGeneration average time: {avgTimePerBatch:F4} ms per batch ({texts.Length} texts)");
            Console.WriteLine($"Average time per embedding: {avgTimePerEmbedding:F4} ms");
            Console.WriteLine($"Throughput: {1000.0 / avgTimePerEmbedding:F0} embeddings/second");

            // Performance should be reasonable
            Assert.True(avgTimePerEmbedding < 10.0, $"Batch generation should be efficient, got {avgTimePerEmbedding:F4} ms per embedding");
        }

        [Fact]
        public void DifferentDimensions_Performance_Comparison()
        {
            // Performance benchmark: dimension comparison
            var dimensions = new[] { 128, 256, 512, 768 };
            var text = "machine learning artificial intelligence";

            foreach (var dim in dimensions)
            {
                var client = new FastEmbedClient(dim);

                // Warmup
                client.GenerateEmbedding(text);

                var stopwatch = Stopwatch.StartNew();
                for (int i = 0; i < 100; i++)
                {
                    client.GenerateEmbedding(text);
                }
                stopwatch.Stop();

                var avgTime = stopwatch.ElapsedMilliseconds / 100.0;
                Console.WriteLine($"Dimension {dim}: {avgTime:F4} ms per embedding");
            }
        }
    }
}

