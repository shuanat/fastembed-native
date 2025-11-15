using System;
using System.IO;
using Xunit;
using FastEmbed;

namespace FastEmbed.Tests
{
    /// <summary>
    /// ONNX integration tests for FastEmbed library
    /// Tests ONNX Runtime integration for neural network embeddings
    /// These tests are conditional - they skip if ONNX Runtime is not available
    /// </summary>
    public class FastEmbedOnnxTests
    {
        private const int DefaultDimension = 128;
        private static readonly string? TestOnnxModelPath = GetTestOnnxModelPath();

        private static string? GetTestOnnxModelPath()
        {
            // Try to find a test ONNX model
            // In a real scenario, this would be a test model file
            // For now, we'll check if ONNX Runtime is available and skip tests if no model
            var possiblePaths = new[]
            {
                Path.Combine("..", "..", "..", "..", "..", "models", "nomic-embed-text", "onnx", "model.onnx"),
                Path.Combine("..", "..", "..", "..", "..", "models", "nomic-embed-text.onnx"),
                Path.Combine("..", "..", "..", "..", "..", "models", "test_model.onnx"),
                Path.Combine("..", "..", "..", "..", "..", "onnxruntime", "test_model.onnx"),
                Environment.GetEnvironmentVariable("FASTEMBED_TEST_ONNX_MODEL")
            };

            foreach (var path in possiblePaths)
            {
                if (!string.IsNullOrEmpty(path) && File.Exists(path))
                {
                    return Path.GetFullPath(path);
                }
            }

            return null;
        }

        [Fact]
        public void GenerateOnnxEmbedding_WithValidModel_ReturnsEmbedding()
        {
            // Happy path: valid ONNX model
            if (TestOnnxModelPath == null || !File.Exists(TestOnnxModelPath))
            {
                // Skip test if model not available
                return;
            }

            var client = new FastEmbedClient(DefaultDimension);
            var text = "machine learning artificial intelligence";

            var embedding = client.GenerateOnnxEmbedding(TestOnnxModelPath, text);

            Assert.NotNull(embedding);
            Assert.Equal(DefaultDimension, embedding.Length);

            // Verify embedding contains valid float values
            foreach (var value in embedding)
            {
                Assert.True(float.IsFinite(value));
            }
        }

        [Fact]
        public void GenerateOnnxEmbedding_WithNullModelPath_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            Assert.Throws<ArgumentNullException>(() => client.GenerateOnnxEmbedding(null!, "text"));
        }

        [Fact]
        public void GenerateOnnxEmbedding_WithNullText_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            Assert.Throws<ArgumentNullException>(() => client.GenerateOnnxEmbedding("model.onnx", null!));
        }

        [Fact]
        public void GenerateOnnxEmbedding_WithNonExistentModel_ThrowsFastEmbedException()
        {
            // Error handling: invalid model path
            var client = new FastEmbedClient(DefaultDimension);
            var nonExistentModel = Path.Combine("non_existent", "model.onnx");

            Assert.Throws<FastEmbedException>(() => client.GenerateOnnxEmbedding(nonExistentModel, "text"));
        }

        [Fact]
        public void UnloadOnnxModel_CanBeCalledSafely()
        {
            // Happy path: model unloading
            var client = new FastEmbedClient(DefaultDimension);

            // Should not throw even if no model is loaded
            var result = client.UnloadOnnxModel();

            // Result can be 0 (success) or -1 (nothing to unload)
            Assert.True(result == 0 || result == -1);
        }

        [Fact]
        public void OnnxEmbedding_EndToEnd_WorksCorrectly()
        {
            // Integration test: ONNX embedding workflow
            if (TestOnnxModelPath == null || !File.Exists(TestOnnxModelPath))
            {
                // Skip test if model not available
                return;
            }

            var client = new FastEmbedClient(DefaultDimension);
            var text1 = "machine learning";
            var text2 = "artificial intelligence";

            var emb1 = client.GenerateOnnxEmbedding(TestOnnxModelPath, text1);
            var emb2 = client.GenerateOnnxEmbedding(TestOnnxModelPath, text2);

            Assert.NotNull(emb1);
            Assert.NotNull(emb2);
            Assert.Equal(DefaultDimension, emb1.Length);
            Assert.Equal(DefaultDimension, emb2.Length);

            // Test similarity
            var similarity = client.CosineSimilarity(emb1, emb2);
            Assert.True(similarity >= -1.0f && similarity <= 1.0f);

            // Test model unloading
            var unloadResult = client.UnloadOnnxModel();
            Assert.True(unloadResult == 0 || unloadResult == -1);
        }

        [Fact]
        public void OnnxModel_Caching_WorksCorrectly()
        {
            // Integration test: ONNX model caching
            if (TestOnnxModelPath == null || !File.Exists(TestOnnxModelPath))
            {
                // Skip test if model not available
                return;
            }

            var client = new FastEmbedClient(DefaultDimension);
            var text = "test text";

            // First call - model should be loaded
            var emb1 = client.GenerateOnnxEmbedding(TestOnnxModelPath, text);

            // Second call - model should be cached (faster)
            var emb2 = client.GenerateOnnxEmbedding(TestOnnxModelPath, text);

            Assert.NotNull(emb1);
            Assert.NotNull(emb2);

            // Embeddings should be the same for the same text
            var similarity = client.CosineSimilarity(emb1, emb2);
            Assert.True(similarity >= 0.99f); // Should be very similar
        }
    }
}

