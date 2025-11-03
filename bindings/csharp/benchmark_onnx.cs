/**
 * FastEmbed C# ONNX Benchmark
 * 
 * Compares hash-based vs ONNX embeddings for speed, memory, and quality.
 * Tests with realistic text sizes (100, 500, 2000 chars) and batch processing.
 */

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using FastEmbed;

namespace FastEmbed.Benchmark
{
    public class OnnxBenchmark
    {
        private const int DIMENSION = 768; // ONNX model only supports 768D
        private const int ITERATIONS_SINGLE = 100;
        private const int ITERATIONS_BATCH = 10;
        private static readonly int[] BATCH_SIZES = { 1, 10, 100 };

        // Realistic text samples
        private static readonly Dictionary<string, string> TEXT_SAMPLES = new Dictionary<string, string>
        {
            ["short"] = "machine learning algorithms and neural networks for artificial intelligence applications in computer science",
            ["medium"] = "Machine learning is a subset of artificial intelligence that focuses on developing algorithms capable of learning from data without being explicitly programmed. These algorithms can identify patterns, make predictions, and improve their performance over time through experience. Neural networks, a key component of modern machine learning, are inspired by the structure of the human brain and consist of interconnected nodes that process information in layers.",
            ["long"] = @"Machine learning represents a revolutionary approach to artificial intelligence that has transformed numerous industries and applications. At its core, machine learning involves the creation of algorithms that can learn from data, identify patterns, and make decisions with minimal human intervention. This field encompasses various techniques, including supervised learning where models are trained on labeled datasets, unsupervised learning that discovers hidden patterns in unlabeled data, and reinforcement learning where agents learn through interaction with their environment.

Neural networks, particularly deep neural networks, have become the cornerstone of modern machine learning. These sophisticated systems consist of multiple layers of interconnected nodes, or neurons, that process information in a hierarchical manner. The depth and complexity of these networks enable them to capture intricate relationships in data, making them exceptionally powerful for tasks such as image recognition, natural language processing, and predictive analytics.

The applications of machine learning are vast and continue to expand. In healthcare, ML models assist in disease diagnosis and drug discovery. In finance, they power fraud detection systems and algorithmic trading. In transportation, they enable autonomous vehicles to navigate complex environments. As the field evolves, the integration of machine learning into everyday technology becomes increasingly seamless, promising a future where intelligent systems enhance human capabilities in unprecedented ways."
        };

        private static string GetModelPath()
        {
            string[] possiblePaths = {
                "../../../models/nomic-embed-text.onnx",
                "../../models/nomic-embed-text.onnx",
                "models/nomic-embed-text.onnx"
            };

            foreach (var path in possiblePaths)
            {
                if (File.Exists(path))
                {
                    return Path.GetFullPath(path);
                }
            }

            return null;
        }

        private static long GetMemoryUsageMB()
        {
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            return GC.GetTotalMemory(false) / 1024 / 1024;
        }

        private static BenchmarkResult BenchmarkFunction(string name, Action fn, int iterations, int warmup = 10)
        {
            // Warmup
            for (int i = 0; i < warmup; i++)
            {
                fn();
            }

            // Force garbage collection
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            System.Threading.Thread.Sleep(100);

            // Measure time and memory
            long startMem = GetMemoryUsageMB();
            var start = System.Diagnostics.Stopwatch.StartNew();

            for (int i = 0; i < iterations; i++)
            {
                fn();
            }

            start.Stop();
            long endMem = GetMemoryUsageMB();

            double totalMs = start.Elapsed.TotalMilliseconds;
            double avgMs = totalMs / iterations;
            double throughput = 1000.0 / avgMs;
            long memDelta = endMem - startMem;

            return new BenchmarkResult
            {
                Name = name,
                AvgMs = avgMs,
                Throughput = throughput,
                StartMemMb = startMem,
                EndMemMb = endMem,
                PeakMemMb = endMem,
                MemDeltaMb = memDelta,
                Iterations = iterations
            };
        }

        private static double CompareQuality(float[] hashEmb, float[] onnxEmb, FastEmbedClient client)
        {
            return client.CosineSimilarity(hashEmb, onnxEmb);
        }

        public static void Main(string[] args)
        {
            MainOnnx(args);
        }

        public static void MainOnnx(string[] args)
        {
            Console.WriteLine("FastEmbed C# ONNX Benchmark");
            Console.WriteLine(new string('=', 50));
            Console.WriteLine($"Dimension: {DIMENSION} (ONNX model limitation)");

            string modelPath = GetModelPath();
            Console.WriteLine($"Model path: {(modelPath != null ? modelPath : "NOT FOUND")}");
            Console.WriteLine($"Model exists: {(modelPath != null && File.Exists(modelPath))}\n");

            if (modelPath == null || !File.Exists(modelPath))
            {
                Console.Error.WriteLine("ERROR: ONNX model not found");
                Console.Error.WriteLine("Please ensure the model is available.");
                Environment.Exit(1);
            }

            var client = new FastEmbedClient(DIMENSION);
            var results = new BenchmarkResults
            {
                Dimension = DIMENSION,
                Timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds()
            };

            // Single embedding benchmarks
            Console.WriteLine("--- Single Embedding Generation (Speed + Memory) ---\n");

            foreach (var entry in TEXT_SAMPLES)
            {
                string textType = entry.Key;
                string text = entry.Value;

                Console.WriteLine($"\nText type: {textType} ({text.Length} chars)");
                Console.WriteLine(new string('-', 50));

                // Hash-based embedding
                Console.WriteLine("Hash-based:");
                var hashResult = BenchmarkFunction(
                    $"hash_{textType}",
                    () => client.GenerateEmbedding(text),
                    ITERATIONS_SINGLE
                );
                float[] hashEmb = client.GenerateEmbedding(text);
                Console.WriteLine($"  Avg time: {hashResult.AvgMs:F3} ms");
                Console.WriteLine($"  Throughput: {hashResult.Throughput:N0} ops/sec");
                Console.WriteLine($"  Memory delta: {hashResult.MemDeltaMb} MB");
                results.HashBased[textType] = hashResult;

                // ONNX embedding
                Console.WriteLine("\nONNX-based:");
                var onnxResult = BenchmarkFunction(
                    $"onnx_{textType}",
                    () => client.GenerateOnnxEmbedding(modelPath, text),
                    ITERATIONS_SINGLE
                );
                float[] onnxEmb = client.GenerateOnnxEmbedding(modelPath, text);
                Console.WriteLine($"  Avg time: {onnxResult.AvgMs:F3} ms");
                Console.WriteLine($"  Throughput: {onnxResult.Throughput:N0} ops/sec");
                Console.WriteLine($"  Memory delta: {onnxResult.MemDeltaMb} MB");
                results.OnnxBased[textType] = onnxResult;

                // Quality comparison
                double quality = CompareQuality(hashEmb, onnxEmb, client);
                Console.WriteLine($"\nQuality (hash vs ONNX cosine similarity): {quality:F4}");
                results.QualityComparison[textType] = new QualityResult
                {
                    CosineSimilarity = quality,
                    TextLength = text.Length
                };

                // Speedup ratio
                double speedup = hashResult.AvgMs / onnxResult.AvgMs;
                Console.WriteLine($"\nSpeed ratio (hash/onnx): {speedup:F2}x");
                if (speedup > 1)
                {
                    Console.WriteLine($"  Hash-based is {speedup:F2}x faster");
                }
                else
                {
                    Console.WriteLine($"  ONNX is {1.0 / speedup:F2}x faster");
                }
            }

            // Batch processing benchmarks
            Console.WriteLine("\n\n--- Batch Processing ---\n");

            var textList = TEXT_SAMPLES.Values.ToArray();

            foreach (int batchSize in BATCH_SIZES)
            {
                Console.WriteLine($"\nBatch size: {batchSize}");
                Console.WriteLine(new string('-', 50));

                // Hash-based batch
                Console.WriteLine("Hash-based batch:");
                var hashBatchResult = BenchmarkFunction(
                    $"hash_batch_{batchSize}",
                    () =>
                    {
                        for (int i = 0; i < batchSize; i++)
                        {
                            client.GenerateEmbedding(textList[i % textList.Length]);
                        }
                    },
                    ITERATIONS_BATCH
                );
                Console.WriteLine($"  Avg time per batch: {hashBatchResult.AvgMs:F3} ms");
                Console.WriteLine($"  Time per embedding: {hashBatchResult.AvgMs / batchSize:F3} ms");
                double hashThroughput = 1000.0 / (hashBatchResult.AvgMs / batchSize);
                Console.WriteLine($"  Throughput: {hashThroughput:N0} embeddings/sec");

                // ONNX batch
                Console.WriteLine("\nONNX-based batch:");
                var onnxBatchResult = BenchmarkFunction(
                    $"onnx_batch_{batchSize}",
                    () =>
                    {
                        for (int i = 0; i < batchSize; i++)
                        {
                            client.GenerateOnnxEmbedding(modelPath, textList[i % textList.Length]);
                        }
                    },
                    ITERATIONS_BATCH
                );
                Console.WriteLine($"  Avg time per batch: {onnxBatchResult.AvgMs:F3} ms");
                Console.WriteLine($"  Time per embedding: {onnxBatchResult.AvgMs / batchSize:F3} ms");
                double onnxThroughput = 1000.0 / (onnxBatchResult.AvgMs / batchSize);
                Console.WriteLine($"  Throughput: {onnxThroughput:N0} embeddings/sec");

                results.BatchPerformance[$"batch_{batchSize}"] = new BatchResult
                {
                    HashBased = hashBatchResult,
                    OnnxBased = onnxBatchResult
                };
            }

            // Save results to JSON
            try
            {
                string outputFile = "benchmark_onnx_results.json";
                var options = new JsonSerializerOptions { WriteIndented = true };
                string json = JsonSerializer.Serialize(results, options);
                File.WriteAllText(outputFile, json);
                Console.WriteLine($"\n\nResults saved to: {outputFile}");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"Failed to save results: {e.Message}");
            }

            Console.WriteLine(new string('=', 50));
            Console.WriteLine("Benchmark completed!");
        }
    }

    // Helper classes for results
    class BenchmarkResult
    {
        public string Name { get; set; }
        public double AvgMs { get; set; }
        public double Throughput { get; set; }
        public long StartMemMb { get; set; }
        public long EndMemMb { get; set; }
        public long PeakMemMb { get; set; }
        public long MemDeltaMb { get; set; }
        public int Iterations { get; set; }
    }

    class QualityResult
    {
        public double CosineSimilarity { get; set; }
        public int TextLength { get; set; }
    }

    class BatchResult
    {
        public BenchmarkResult HashBased { get; set; }
        public BenchmarkResult OnnxBased { get; set; }
    }

    class BenchmarkResults
    {
        public int Dimension { get; set; }
        public double Timestamp { get; set; }
        public Dictionary<string, BenchmarkResult> HashBased { get; set; } = new Dictionary<string, BenchmarkResult>();
        public Dictionary<string, BenchmarkResult> OnnxBased { get; set; } = new Dictionary<string, BenchmarkResult>();
        public Dictionary<string, QualityResult> QualityComparison { get; set; } = new Dictionary<string, QualityResult>();
        public Dictionary<string, BatchResult> BatchPerformance { get; set; } = new Dictionary<string, BatchResult>();
    }
}

