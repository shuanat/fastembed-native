package com.fastembed;

public class FastEmbed {
    private static boolean nativeLoaded = false;
    private final int dimension;

    static {
        try {
            System.loadLibrary("fastembed");
            nativeLoaded = true;
        } catch (UnsatisfiedLinkError e) {
            System.err.println("Failed to load native library: " + e.getMessage());
            nativeLoaded = false;
        }
    }

    public FastEmbed(int dimension) {
        if (!nativeLoaded) {
            throw new IllegalStateException("Native library not loaded");
        }
        if (dimension <= 0) {
            throw new IllegalArgumentException("Dimension must be positive");
        }
        this.dimension = dimension;
    }

    public float[] generateEmbedding(String text) {
        if (text == null) {
            throw new IllegalArgumentException("Text cannot be null");
        }
        float[] output = new float[dimension];
        int result = nativeGenerateEmbedding(text, output, dimension);
        if (result != 0) {
            throw new RuntimeException("Failed to generate embedding (error code: " + result + ")");
        }
        return output;
    }

    public float cosineSimilarity(float[] vectorA, float[] vectorB) {
        if (vectorA == null || vectorB == null || vectorA.length != dimension || vectorB.length != dimension) {
            throw new IllegalArgumentException("Invalid vectors");
        }
        return nativeCosineSimilarity(vectorA, vectorB, dimension);
    }

    public float dotProduct(float[] vectorA, float[] vectorB) {
        if (vectorA == null || vectorB == null || vectorA.length != dimension || vectorB.length != dimension) {
            throw new IllegalArgumentException("Invalid vectors");
        }
        return nativeDotProduct(vectorA, vectorB, dimension);
    }

    public float vectorNorm(float[] vector) {
        if (vector == null || vector.length != dimension) {
            throw new IllegalArgumentException("Invalid vector");
        }
        return nativeVectorNorm(vector, dimension);
    }

    public float[] normalizeVector(float[] vector) {
        if (vector == null || vector.length != dimension) {
            throw new IllegalArgumentException("Invalid vector");
        }
        float[] result = vector.clone();
        nativeNormalizeVector(result, dimension);
        return result;
    }

    public float[] addVectors(float[] vectorA, float[] vectorB) {
        if (vectorA == null || vectorB == null || vectorA.length != dimension || vectorB.length != dimension) {
            throw new IllegalArgumentException("Invalid vectors");
        }
        float[] result = new float[dimension];
        nativeAddVectors(vectorA, vectorB, result, dimension);
        return result;
    }

    private native int nativeGenerateEmbedding(String text, float[] output, int dimension);
    private native float nativeCosineSimilarity(float[] vectorA, float[] vectorB, int dimension);
    private native float nativeDotProduct(float[] vectorA, float[] vectorB, int dimension);
    private native float nativeVectorNorm(float[] vector, int dimension);
    private native void nativeNormalizeVector(float[] vector, int dimension);
    private native void nativeAddVectors(float[] vectorA, float[] vectorB, float[] result, int dimension);
}
