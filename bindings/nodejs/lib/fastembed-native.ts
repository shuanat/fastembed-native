/**
 * FastEmbed Native Module TypeScript Wrapper
 * 
 * Provides type-safe interface to the native N-API module
 */

import { createRequire } from 'module';
import * as path from 'path';
import { fileURLToPath } from 'url';

// Native module interface
interface FastEmbedNativeModule {
  generateEmbedding(text: string, dimension?: number): Float32Array;
  generateOnnxEmbedding(modelPath: string, text: string, dimension?: number): Float32Array;
  unloadOnnxModel(): number;
  cosineSimilarity(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): number;
  dotProduct(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): number;
  vectorNorm(vector: Float32Array | number[]): number;
  normalizeVector(vector: Float32Array | number[]): Float32Array;
  addVectors(vectorA: Float32Array | number[], vectorB: Float32Array | number[]): Float32Array;
}

let nativeModule: FastEmbedNativeModule | null = null;

/**
 * Load the native module
 * @returns True if successfully loaded, false otherwise
 */
export function loadNativeModule(): boolean {
  if (nativeModule) {
    return true;
  }

  try {
    // Get __dirname equivalent for ES modules
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);

    // Use createRequire for ES module compatibility
    const require = createRequire(import.meta.url);

    // Try to load the native module
    const modulePath = path.resolve(__dirname, '../build/Release/fastembed_native.node');
    nativeModule = require(modulePath) as FastEmbedNativeModule;
    return true;
  } catch (error: any) {
    console.warn('Failed to load native module:', error.message);
    return false;
  }
}

/**
 * Check if native module is available
 */
export function isNativeModuleAvailable(): boolean {
  return nativeModule !== null;
}

/**
 * Generate embedding from text using native module
 * 
 * @param text - Input text
 * @param dimension - Embedding dimension (default: 768)
 * @returns Embedding vector as Float32Array
 */
export function generateEmbedding(text: string, dimension: number = 768): Float32Array {
  if (!nativeModule) {
    throw new Error('Native module not loaded. Call loadNativeModule() first.');
  }

  return nativeModule.generateEmbedding(text, dimension);
}

/**
 * Calculate cosine similarity between two vectors
 * 
 * @param vectorA - First vector
 * @param vectorB - Second vector
 * @returns Cosine similarity (-1 to 1)
 */
export function cosineSimilarity(
  vectorA: Float32Array | number[],
  vectorB: Float32Array | number[]
): number {
  if (!nativeModule) {
    throw new Error('Native module not loaded. Call loadNativeModule() first.');
  }

  return nativeModule.cosineSimilarity(vectorA, vectorB);
}

/**
 * Calculate dot product of two vectors
 * 
 * @param vectorA - First vector
 * @param vectorB - Second vector
 * @returns Dot product value
 */
export function dotProduct(
  vectorA: Float32Array | number[],
  vectorB: Float32Array | number[]
): number {
  if (!nativeModule) {
    throw new Error('Native module not loaded. Call loadNativeModule() first.');
  }

  return nativeModule.dotProduct(vectorA, vectorB);
}

/**
 * Calculate L2 norm of a vector
 * 
 * @param vector - Input vector
 * @returns Vector norm
 */
export function vectorNorm(vector: Float32Array | number[]): number {
  if (!nativeModule) {
    throw new Error('Native module not loaded. Call loadNativeModule() first.');
  }

  return nativeModule.vectorNorm(vector);
}

/**
 * Normalize vector (L2 normalization)
 * 
 * @param vector - Input vector
 * @returns Normalized vector
 */
export function normalizeVector(vector: Float32Array | number[]): Float32Array {
  if (!nativeModule) {
    throw new Error('Native module not loaded. Call loadNativeModule() first.');
  }

  return nativeModule.normalizeVector(vector);
}

/**
 * Add two vectors element-wise
 * 
 * @param vectorA - First vector
 * @param vectorB - Second vector
 * @returns Result vector
 */
export function addVectors(
  vectorA: Float32Array | number[],
  vectorB: Float32Array | number[]
): Float32Array {
  if (!nativeModule) {
    throw new Error('Native module not loaded. Call loadNativeModule() first.');
  }

  return nativeModule.addVectors(vectorA, vectorB);
}

/**
 * FastEmbed Native Client
 * 
 * High-performance client using native N-API module
 */
export class FastEmbedNativeClient {
  private dimension: number;
  private loaded: boolean = false;

  constructor(dimension: number = 768) {
    this.dimension = dimension;
    this.loaded = loadNativeModule();
  }

  /**
   * Check if native module is available
   */
  isAvailable(): boolean {
    return this.loaded;
  }

  /**
   * Generate embedding from text
   */
  async generateEmbedding(text: string): Promise<number[]> {
    if (!this.loaded) {
      throw new Error('Native module not available');
    }

    const embedding = generateEmbedding(text, this.dimension);
    return Array.from(embedding);
  }

  /**
   * Calculate cosine similarity
   */
  cosineSimilarity(vectorA: number[], vectorB: number[]): number {
    if (!this.loaded) {
      throw new Error('Native module not available');
    }

    return cosineSimilarity(vectorA, vectorB);
  }

  /**
   * Calculate dot product
   */
  dotProduct(vectorA: number[], vectorB: number[]): number {
    if (!this.loaded) {
      throw new Error('Native module not available');
    }

    return dotProduct(vectorA, vectorB);
  }

  /**
   * Get vector norm
   */
  vectorNorm(vector: number[]): number {
    if (!this.loaded) {
      throw new Error('Native module not available');
    }

    return vectorNorm(vector);
  }
}

// Auto-load on import (optional)
if (typeof process !== 'undefined' && process.env.FASTEMBED_AUTO_LOAD_NATIVE !== 'false') {
  loadNativeModule();
}

