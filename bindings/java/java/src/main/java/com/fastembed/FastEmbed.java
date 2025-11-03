package com.fastembed;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

/**
 * High-performance hash-based text embedding library with native SIMD
 * acceleration
 * 
 * This class provides a Java interface to the FastEmbed native library,
 * which generates embeddings using hash-based methods and optimized assembly
 * code.
 * 
 * @author FastEmbed Team
 * @version 1.0.0
 */
public class FastEmbed {

    private static boolean nativeLoaded = false;
    private final int dimension;

    static {
        try {
            loadNativeLibrary();
            nativeLoaded = true;
        } catch (Exception e) {
            System.err.println("Failed to load native library: " + e.getMessage());
            nativeLoaded = false;
        }
    }

    /**
     * Load the native FastEmbed library
     * Attempts to extract and load the appropriate library for the current platform
     */
    private static void loadNativeLibrary() throws IOException {
        String os = System.getProperty("os.name").toLowerCase();
        String arch = System.getProperty("os.arch").toLowerCase();

        String libraryName;
        if (os.contains("win")) {
            libraryName = "fastembed_jni.dll";
        } else if (os.contains("mac")) {
            libraryName = "libfastembed_jni.dylib";
        } else {
            libraryName = "libfastembed_jni.so";
        }

        // Try to load from java.library.path first
        try {
            System.loadLibrary("fastembed_jni");
            return;
        } catch (UnsatisfiedLinkError e) {
            // Library not in java.library.path, try to extract from resources
        }

        // Extract from JAR resources
        String resourcePath = "/native/" + os + "/" + arch + "/" + libraryName;
        try (InputStream is = FastEmbed.class.getResourceAsStream(resourcePath)) {
            if (is == null) {
                throw new IOException("Native library not found in resources: " + resourcePath);
            }

            File tempFile = File.createTempFile("fastembed_", libraryName);
            tempFile.deleteOnExit();
            Files.copy(is, tempFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            System.load(tempFile.getAbsolutePath());
        }
    }

    /**
     * Check if native library is available
     * 
     * @return true if native library loaded successfully
     */
    public static boolean isAvailable() {
        return nativeLoaded;
    }

    /**
     * Create a new FastEmbed client
     * 
     * @param dimension Embedding dimension (default: 768)
     * @throws IllegalStateException    if native library not loaded
     * @throws IllegalArgumentException if dimension is invalid
     */
    public FastEmbed(int dimension) {
        if (!nativeLoaded) {
            throw new IllegalStateException("Native library not loaded");
        }
        if (dimension <= 0) {
            throw new IllegalArgumentException("Dimension must be positive");
        }
        this.dimension = dimension;
    }

    /**
     * Create a new FastEmbed client with default dimension (768)
     * 
     * @throws IllegalStateException if native library not loaded
     */
    public FastEmbed() {
        this(768);
    }

    /**
     * Get the embedding dimension
     * 
     * @return Embedding dimension
     */
    public int getDimension() {
        return dimension;
    }

    /**
     * Generate hash-based embedding for text
     * 
     * @param text Input text
     * @return Embedding vector as float array
     * @throws IllegalArgumentException if text is null
     * @throws FastEmbedException       if generation fails
     */
    public float[] generateEmbedding(String text) {
        if (text == null) {
            throw new IllegalArgumentException("Text cannot be null");
        }

        float[] output = new float[dimension];
        int result = nativeGenerateEmbedding(text, output, dimension);

        if (result != 0) {
            throw new FastEmbedException("Failed to generate embedding (error code: " + result + ")");
        }

        return output;
    }

    /**
     * Calculate cosine similarity between two vectors
     * 
     * @param vectorA First vector
     * @param vectorB Second vector
     * @return Cosine similarity in range [-1, 1]
     * @throws IllegalArgumentException if vectors are invalid
     */
    public float cosineSimilarity(float[] vectorA, float[] vectorB) {
        validateVectors(vectorA, vectorB);
        return nativeCosineSimilarity(vectorA, vectorB, dimension);
    }

    /**
     * Calculate dot product of two vectors
     * 
     * @param vectorA First vector
     * @param vectorB Second vector
     * @return Dot product
     * @throws IllegalArgumentException if vectors are invalid
     */
    public float dotProduct(float[] vectorA, float[] vectorB) {
        validateVectors(vectorA, vectorB);
        return nativeDotProduct(vectorA, vectorB, dimension);
    }

    /**
     * Calculate L2 norm of a vector
     * 
     * @param vector Input vector
     * @return L2 norm
     * @throws IllegalArgumentException if vector is invalid
     */
    public float vectorNorm(float[] vector) {
        validateVector(vector);
        return nativeVectorNorm(vector, dimension);
    }

    /**
     * Normalize a vector (L2 normalization)
     * 
     * @param vector Input vector
     * @return Normalized vector (new array)
     * @throws IllegalArgumentException if vector is invalid
     */
    public float[] normalizeVector(float[] vector) {
        validateVector(vector);
        float[] result = vector.clone();
        nativeNormalizeVector(result, dimension);
        return result;
    }

    /**
     * Add two vectors element-wise
     * 
     * @param vectorA First vector
     * @param vectorB Second vector
     * @return Sum vector
     * @throws IllegalArgumentException if vectors are invalid
     */
    public float[] addVectors(float[] vectorA, float[] vectorB) {
        validateVectors(vectorA, vectorB);
        float[] result = new float[dimension];
        nativeAddVectors(vectorA, vectorB, result, dimension);
        return result;
    }

    /**
     * Calculate semantic similarity between two texts
     * 
     * @param text1 First text
     * @param text2 Second text
     * @return Cosine similarity between embeddings
     */
    public float textSimilarity(String text1, String text2) {
        float[] emb1 = generateEmbedding(text1);
        float[] emb2 = generateEmbedding(text2);
        return cosineSimilarity(emb1, emb2);
    }

    /**
     * Generate embeddings for multiple texts in batch
     * 
     * @param texts Array of input texts
     * @return Array of embedding vectors
     */
    public float[][] generateEmbeddings(String... texts) {
        if (texts == null) {
            throw new IllegalArgumentException("Texts array cannot be null");
        }

        float[][] embeddings = new float[texts.length][];
        for (int i = 0; i < texts.length; i++) {
            embeddings[i] = generateEmbedding(texts[i]);
        }
        return embeddings;
    }

    /**
     * Generate ONNX-based embedding for text using ML model
     * 
     * @param modelPath Path to ONNX model file
     * @param text      Input text
     * @return Embedding vector as float array
     * @throws FastEmbedException       if generation fails
     * @throws IllegalArgumentException if modelPath or text is null
     */
    public float[] generateOnnxEmbedding(String modelPath, String text) {
        if (modelPath == null) {
            throw new IllegalArgumentException("Model path cannot be null");
        }
        if (text == null) {
            throw new IllegalArgumentException("Text cannot be null");
        }

        float[] output = new float[dimension];
        int result = nativeGenerateOnnxEmbedding(modelPath, text, output, dimension);

        if (result != 0) {
            throw new FastEmbedException("Failed to generate ONNX embedding (error code: " + result + ")");
        }

        return output;
    }

    /**
     * Unload cached ONNX model session
     * 
     * @return 0 on success, -1 on error
     */
    public int unloadOnnxModel() {
        return nativeUnloadOnnxModel();
    }

    private void validateVector(float[] vector) {
        if (vector == null) {
            throw new IllegalArgumentException("Vector cannot be null");
        }
        if (vector.length != dimension) {
            throw new IllegalArgumentException(
                    String.format("Vector dimension mismatch: expected %d, got %d", dimension, vector.length));
        }
    }

    private void validateVectors(float[] vectorA, float[] vectorB) {
        validateVector(vectorA);
        validateVector(vectorB);
    }

    // Native method declarations
    private native int nativeGenerateEmbedding(String text, float[] output, int dimension);

    private native float nativeCosineSimilarity(float[] vectorA, float[] vectorB, int dimension);

    private native float nativeDotProduct(float[] vectorA, float[] vectorB, int dimension);

    private native float nativeVectorNorm(float[] vector, int dimension);

    private native void nativeNormalizeVector(float[] vector, int dimension);

    private native void nativeAddVectors(float[] vectorA, float[] vectorB, float[] result, int dimension);

    private native int nativeGenerateOnnxEmbedding(String modelPath, String text, float[] output, int dimension);

    private native int nativeUnloadOnnxModel();

    /**
     * Exception thrown when FastEmbed native operation fails
     */
    public static class FastEmbedException extends RuntimeException {
        public FastEmbedException(String message) {
            super(message);
        }

        public FastEmbedException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
