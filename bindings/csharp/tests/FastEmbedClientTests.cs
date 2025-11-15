using System;
using Xunit;
using FastEmbed;

namespace FastEmbed.Tests
{
    /// <summary>
    /// Unit tests for FastEmbedClient class
    /// Tests follow CONTRIBUTING.md requirements: happy path, edge cases, error handling
    /// </summary>
    public class FastEmbedClientTests
    {
        private const int DefaultDimension = 128; // Default dimension in v1.0.1

        [Fact]
        public void Constructor_WithValidDimension_InitializesSuccessfully()
        {
            // Happy path: valid dimension
            var client = new FastEmbedClient(DefaultDimension);
            Assert.Equal(DefaultDimension, client.Dimension);
        }

        [Fact]
        public void Constructor_WithZeroDimension_ThrowsArgumentException()
        {
            // Error handling: invalid dimension
            Assert.Throws<ArgumentException>(() => new FastEmbedClient(0));
        }

        [Fact]
        public void Constructor_WithNegativeDimension_ThrowsArgumentException()
        {
            // Error handling: invalid dimension
            Assert.Throws<ArgumentException>(() => new FastEmbedClient(-1));
        }

        [Fact]
        public void Constructor_WithDefaultParameter_UsesDefaultDimension()
        {
            // Happy path: default parameter (768 for backward compatibility)
            var client = new FastEmbedClient();
            Assert.Equal(768, client.Dimension);
        }

        [Fact]
        public void GenerateEmbedding_WithValidText_ReturnsEmbedding()
        {
            // Happy path: valid text
            var client = new FastEmbedClient(DefaultDimension);
            var text = "machine learning artificial intelligence";

            var embedding = client.GenerateEmbedding(text);

            Assert.NotNull(embedding);
            Assert.Equal(DefaultDimension, embedding.Length);
            // Verify embedding contains valid float values
            foreach (var value in embedding)
            {
                Assert.True(float.IsFinite(value));
            }
        }

        [Fact]
        public void GenerateEmbedding_WithNullText_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            Assert.Throws<ArgumentNullException>(() => client.GenerateEmbedding(null!));
        }

        [Fact]
        public void GenerateEmbedding_WithEmptyString_ThrowsException()
        {
            // Edge case: empty text should throw exception (invalid input)
            var client = new FastEmbedClient(DefaultDimension);

            // Empty string is not valid input for embedding generation
            Assert.Throws<FastEmbedException>(() => client.GenerateEmbedding(""));
        }

        [Fact]
        public void GenerateEmbedding_WithVeryLongText_ThrowsException()
        {
            // Edge case: very long text should throw exception (exceeds buffer limit)
            var client = new FastEmbedClient(DefaultDimension);
            var longText = new string('a', 10000); // 10000 chars exceeds max buffer size (8192)

            // Very long text exceeds native library buffer limits
            Assert.Throws<FastEmbedException>(() => client.GenerateEmbedding(longText));
        }

        [Fact]
        public void GenerateEmbedding_WithSpecialCharacters_ReturnsEmbedding()
        {
            // Edge case: special characters
            var client = new FastEmbedClient(DefaultDimension);
            var text = "Hello! @#$%^&*() 世界 🌍";

            var embedding = client.GenerateEmbedding(text);

            Assert.NotNull(embedding);
            Assert.Equal(DefaultDimension, embedding.Length);
        }

        [Fact]
        public void GenerateEmbedding_WithUnicodeText_ReturnsEmbedding()
        {
            // Edge case: unicode text
            var client = new FastEmbedClient(DefaultDimension);
            var text = "Привет мир こんにちは";

            var embedding = client.GenerateEmbedding(text);

            Assert.NotNull(embedding);
            Assert.Equal(DefaultDimension, embedding.Length);
        }

        [Fact]
        public void CosineSimilarity_WithValidVectors_ReturnsSimilarity()
        {
            // Happy path: valid vectors
            var client = new FastEmbedClient(DefaultDimension);
            var text1 = "machine learning";
            var text2 = "artificial intelligence";

            var emb1 = client.GenerateEmbedding(text1);
            var emb2 = client.GenerateEmbedding(text2);

            var similarity = client.CosineSimilarity(emb1, emb2);

            Assert.True(similarity >= -1.0f && similarity <= 1.0f);
        }

        [Fact]
        public void CosineSimilarity_WithNullVectorA_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            var vectorB = new float[DefaultDimension];

            Assert.Throws<ArgumentNullException>(() => client.CosineSimilarity(null!, vectorB));
        }

        [Fact]
        public void CosineSimilarity_WithNullVectorB_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            var vectorA = new float[DefaultDimension];

            Assert.Throws<ArgumentNullException>(() => client.CosineSimilarity(vectorA, null!));
        }

        [Fact]
        public void CosineSimilarity_WithDimensionMismatch_ThrowsArgumentException()
        {
            // Error handling: invalid arguments
            var client = new FastEmbedClient(DefaultDimension);
            var vectorA = new float[DefaultDimension];
            var vectorB = new float[DefaultDimension + 1];

            Assert.Throws<ArgumentException>(() => client.CosineSimilarity(vectorA, vectorB));
        }

        [Fact]
        public void DotProduct_WithValidVectors_ReturnsProduct()
        {
            // Happy path: valid vectors
            var client = new FastEmbedClient(DefaultDimension);
            var vectorA = new float[DefaultDimension];
            var vectorB = new float[DefaultDimension];

            // Initialize with test values
            for (int i = 0; i < DefaultDimension; i++)
            {
                vectorA[i] = 1.0f;
                vectorB[i] = 2.0f;
            }

            var product = client.DotProduct(vectorA, vectorB);

            Assert.True(float.IsFinite(product));
        }

        [Fact]
        public void DotProduct_WithNullVectorA_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            var vectorB = new float[DefaultDimension];

            Assert.Throws<ArgumentNullException>(() => client.DotProduct(null!, vectorB));
        }

        [Fact]
        public void DotProduct_WithDimensionMismatch_ThrowsArgumentException()
        {
            // Error handling: invalid arguments
            var client = new FastEmbedClient(DefaultDimension);
            var vectorA = new float[DefaultDimension];
            var vectorB = new float[DefaultDimension + 1];

            Assert.Throws<ArgumentException>(() => client.DotProduct(vectorA, vectorB));
        }

        [Fact]
        public void VectorNorm_WithValidVector_ReturnsNorm()
        {
            // Happy path: valid vector
            var client = new FastEmbedClient(DefaultDimension);
            var vector = new float[DefaultDimension];

            // Initialize with test values
            for (int i = 0; i < DefaultDimension; i++)
            {
                vector[i] = 1.0f;
            }

            var norm = client.VectorNorm(vector);

            Assert.True(norm >= 0.0f);
            Assert.True(float.IsFinite(norm));
        }

        [Fact]
        public void VectorNorm_WithNullVector_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            Assert.Throws<ArgumentNullException>(() => client.VectorNorm(null!));
        }

        [Fact]
        public void VectorNorm_WithZeroVector_ReturnsZero()
        {
            // Edge case: zero vector
            var client = new FastEmbedClient(DefaultDimension);
            var vector = new float[DefaultDimension]; // All zeros

            var norm = client.VectorNorm(vector);

            Assert.Equal(0.0f, norm);
        }

        [Fact]
        public void VectorNorm_WithLargeDimensions_ReturnsNorm()
        {
            // Edge case: large dimensions
            const int largeDimension = 2048;
            var client = new FastEmbedClient(largeDimension);
            var vector = new float[largeDimension];

            for (int i = 0; i < largeDimension; i++)
            {
                vector[i] = 1.0f;
            }

            var norm = client.VectorNorm(vector);

            Assert.True(norm >= 0.0f);
            Assert.True(float.IsFinite(norm));
        }

        [Fact]
        public void NormalizeVector_WithValidVector_ReturnsNormalizedVector()
        {
            // Happy path: valid vector
            var client = new FastEmbedClient(DefaultDimension);
            var text = "test text";
            var vector = client.GenerateEmbedding(text);

            var normalized = client.NormalizeVector(vector);

            Assert.NotNull(normalized);
            Assert.Equal(DefaultDimension, normalized.Length);

            // Verify normalized vector has norm ~1.0
            var norm = client.VectorNorm(normalized);
            Assert.True(Math.Abs(norm - 1.0f) < 0.01f, $"Expected norm ~1.0, got {norm}");
        }

        [Fact]
        public void NormalizeVector_WithNullVector_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            Assert.Throws<ArgumentNullException>(() => client.NormalizeVector(null!));
        }

        [Fact]
        public void AddVectors_WithValidVectors_ReturnsSum()
        {
            // Happy path: valid vectors
            var client = new FastEmbedClient(DefaultDimension);
            var vectorA = new float[DefaultDimension];
            var vectorB = new float[DefaultDimension];

            for (int i = 0; i < DefaultDimension; i++)
            {
                vectorA[i] = 1.0f;
                vectorB[i] = 2.0f;
            }

            var sum = client.AddVectors(vectorA, vectorB);

            Assert.NotNull(sum);
            Assert.Equal(DefaultDimension, sum.Length);
            Assert.Equal(3.0f, sum[0]);
        }

        [Fact]
        public void AddVectors_WithNullVectorA_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            var vectorB = new float[DefaultDimension];

            Assert.Throws<ArgumentNullException>(() => client.AddVectors(null!, vectorB));
        }

        [Fact]
        public void TextSimilarity_WithValidTexts_ReturnsSimilarity()
        {
            // Happy path: valid texts
            var client = new FastEmbedClient(DefaultDimension);
            var text1 = "machine learning";
            var text2 = "artificial intelligence";

            var similarity = client.TextSimilarity(text1, text2);

            Assert.True(similarity >= -1.0f && similarity <= 1.0f);
        }

        [Fact]
        public void GenerateEmbeddings_WithValidTexts_ReturnsEmbeddings()
        {
            // Happy path: batch generation
            var client = new FastEmbedClient(DefaultDimension);
            var texts = new[] { "text1", "text2", "text3" };

            var embeddings = client.GenerateEmbeddings(texts);

            Assert.NotNull(embeddings);
            Assert.Equal(3, embeddings.Length);
            foreach (var embedding in embeddings)
            {
                Assert.NotNull(embedding);
                Assert.Equal(DefaultDimension, embedding.Length);
            }
        }

        [Fact]
        public void GenerateEmbeddings_WithNullTexts_ThrowsArgumentNullException()
        {
            // Error handling: null pointer
            var client = new FastEmbedClient(DefaultDimension);
            Assert.Throws<ArgumentNullException>(() => client.GenerateEmbeddings(null!));
        }

        [Fact]
        public void GenerateEmbeddings_WithEmptyArray_ReturnsEmptyArray()
        {
            // Edge case: empty array
            var client = new FastEmbedClient(DefaultDimension);
            var embeddings = client.GenerateEmbeddings();

            Assert.NotNull(embeddings);
            Assert.Empty(embeddings);
        }
    }
}

