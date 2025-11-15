using System;
using System.Linq;

namespace FastEmbed
{
    /// <summary>
    /// High-level C# wrapper for FastEmbed native library
    /// Provides type-safe, idiomatic C# API for embedding generation
    /// </summary>
    public class FastEmbedClient
    {
        private readonly int _dimension;

        /// <summary>
        /// Initialize FastEmbed client
        /// </summary>
        /// <param name="dimension">Embedding dimension (default: 768)</param>
        public FastEmbedClient(int dimension = 768)
        {
            if (dimension <= 0)
                throw new ArgumentException("Dimension must be positive", nameof(dimension));

            _dimension = dimension;
        }

        /// <summary>
        /// Gets the embedding dimension
        /// </summary>
        public int Dimension => _dimension;

        /// <summary>
        /// Generate hash-based embedding for text
        /// </summary>
        /// <param name="text">Input text</param>
        /// <returns>Embedding vector as float array</returns>
        /// <exception cref="ArgumentNullException">If text is null</exception>
        /// <exception cref="FastEmbedException">If generation fails</exception>
        public float[] GenerateEmbedding(string text)
        {
            if (text == null)
                throw new ArgumentNullException(nameof(text));

            var output = new float[_dimension];
            int result = FastEmbedNative.fastembed_generate(text, output, _dimension);

            if (result != 0)
                throw new FastEmbedException($"Failed to generate embedding (error code: {result})");

            return output;
        }

        /// <summary>
        /// Calculate cosine similarity between two vectors
        /// </summary>
        /// <param name="vectorA">First vector</param>
        /// <param name="vectorB">Second vector</param>
        /// <returns>Cosine similarity in range [-1, 1]</returns>
        /// <exception cref="ArgumentException">If vector dimensions don't match</exception>
        public float CosineSimilarity(float[] vectorA, float[] vectorB)
        {
            ValidateVectors(vectorA, vectorB);
            return FastEmbedNative.fastembed_cosine_similarity(vectorA, vectorB, _dimension);
        }

        /// <summary>
        /// Calculate dot product of two vectors
        /// </summary>
        /// <param name="vectorA">First vector</param>
        /// <param name="vectorB">Second vector</param>
        /// <returns>Dot product</returns>
        /// <exception cref="ArgumentException">If vector dimensions don't match</exception>
        public float DotProduct(float[] vectorA, float[] vectorB)
        {
            ValidateVectors(vectorA, vectorB);
            return FastEmbedNative.fastembed_dot_product(vectorA, vectorB, _dimension);
        }

        /// <summary>
        /// Calculate L2 norm of a vector
        /// </summary>
        /// <param name="vector">Input vector</param>
        /// <returns>L2 norm</returns>
        /// <exception cref="ArgumentException">If vector dimension doesn't match</exception>
        public float VectorNorm(float[] vector)
        {
            ValidateVector(vector);
            return FastEmbedNative.fastembed_vector_norm(vector, _dimension);
        }

        /// <summary>
        /// Normalize a vector (L2 normalization)
        /// </summary>
        /// <param name="vector">Input vector</param>
        /// <returns>Normalized vector (new array)</returns>
        /// <exception cref="ArgumentException">If vector dimension doesn't match</exception>
        public float[] NormalizeVector(float[] vector)
        {
            ValidateVector(vector);
            var result = (float[])vector.Clone();
            FastEmbedNative.fastembed_normalize(result, _dimension);
            return result;
        }

        /// <summary>
        /// Add two vectors element-wise
        /// </summary>
        /// <param name="vectorA">First vector</param>
        /// <param name="vectorB">Second vector</param>
        /// <returns>Sum vector</returns>
        /// <exception cref="ArgumentException">If vector dimensions don't match</exception>
        public float[] AddVectors(float[] vectorA, float[] vectorB)
        {
            ValidateVectors(vectorA, vectorB);
            var result = new float[_dimension];
            FastEmbedNative.fastembed_add_vectors(vectorA, vectorB, result, _dimension);
            return result;
        }

        /// <summary>
        /// Calculate semantic similarity between two texts
        /// </summary>
        /// <param name="text1">First text</param>
        /// <param name="text2">Second text</param>
        /// <returns>Cosine similarity between embeddings</returns>
        public float TextSimilarity(string text1, string text2)
        {
            var emb1 = GenerateEmbedding(text1);
            var emb2 = GenerateEmbedding(text2);
            return CosineSimilarity(emb1, emb2);
        }

        /// <summary>
        /// Generate embeddings for multiple texts in batch
        /// </summary>
        /// <param name="texts">Array of input texts</param>
        /// <returns>Array of embedding vectors</returns>
        public float[][] GenerateEmbeddings(params string[] texts)
        {
            if (texts == null)
                throw new ArgumentNullException(nameof(texts));

            return texts.Select(GenerateEmbedding).ToArray();
        }

        /// <summary>
        /// Generate ONNX-based embedding for text using ML model
        /// </summary>
        /// <param name="modelPath">Path to ONNX model file</param>
        /// <param name="text">Input text</param>
        /// <returns>Embedding vector as float array</returns>
        /// <exception cref="ArgumentNullException">If modelPath or text is null</exception>
        /// <exception cref="FastEmbedException">If generation fails</exception>
        public float[] GenerateOnnxEmbedding(string modelPath, string text)
        {
            if (modelPath == null)
                throw new ArgumentNullException(nameof(modelPath));
            if (text == null)
                throw new ArgumentNullException(nameof(text));

            var output = new float[_dimension];
            int result = FastEmbedNative.fastembed_onnx_generate(modelPath, text, output, _dimension);

            if (result != 0)
                throw new FastEmbedException($"Failed to generate ONNX embedding (error code: {result})");

            return output;
        }

        /// <summary>
        /// Unload ONNX model from memory
        /// </summary>
        /// <returns>0 on success, -1 on error</returns>
        public int UnloadOnnxModel()
        {
            return FastEmbedNative.fastembed_onnx_unload();
        }

        private void ValidateVector(float[] vector)
        {
            if (vector == null)
                throw new ArgumentNullException(nameof(vector));
            if (vector.Length != _dimension)
                throw new ArgumentException(
                    $"Vector dimension mismatch: expected {_dimension}, got {vector.Length}",
                    nameof(vector));
        }

        private void ValidateVectors(float[] vectorA, float[] vectorB)
        {
            ValidateVector(vectorA);
            ValidateVector(vectorB);
        }
    }

    /// <summary>
    /// Exception thrown when FastEmbed native operation fails
    /// </summary>
    public class FastEmbedException : Exception
    {
        /// <summary>
        /// Initializes a new instance of the FastEmbedException class with a specified error message
        /// </summary>
        /// <param name="message">The message that describes the error</param>
        public FastEmbedException(string message) : base(message) { }

        /// <summary>
        /// Initializes a new instance of the FastEmbedException class with a specified error message and a reference to the inner exception
        /// </summary>
        /// <param name="message">The error message that explains the reason for the exception</param>
        /// <param name="innerException">The exception that is the cause of the current exception</param>
        public FastEmbedException(string message, Exception innerException)
            : base(message, innerException) { }
    }
}

