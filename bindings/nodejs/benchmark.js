/**
 * FastEmbed Node.js N-API Benchmark
 * 
 * Measures performance of embedding generation and vector operations
 */

// Use direct .node module loading
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const fastembedNative = require('./build/Release/fastembed_native.node');

class FastEmbedNativeClient {
  constructor(dimension) {
    this.dimension = dimension;
  }

  generateEmbedding(text) {
    return fastembedNative.generateEmbedding(text, this.dimension);
  }

  cosineSimilarity(vec1, vec2) {
    return fastembedNative.cosineSimilarity(vec1, vec2);
  }

  dotProduct(vec1, vec2) {
    return fastembedNative.dotProduct(vec1, vec2);
  }

  vectorNorm(vec) {
    return fastembedNative.vectorNorm(vec);
  }

  normalizeVector(vec) {
    return fastembedNative.normalizeVector(vec);
  }

  addVectors(vec1, vec2) {
    return fastembedNative.addVectors(vec1, vec2);
  }
}

const ITERATIONS = 1000;
const DIMENSION = 768;

console.log('FastEmbed Node.js N-API Benchmark');
console.log('=================================\n');
console.log(`Iterations: ${ITERATIONS}`);
console.log(`Dimension: ${DIMENSION}\n`);

const client = new FastEmbedNativeClient(DIMENSION);

// Test text samples
const texts = [
  "machine learning",
  "artificial intelligence and deep learning",
  "natural language processing with transformers",
  "computer vision and image recognition systems",
  "The quick brown fox jumps over the lazy dog and runs through the forest"
];

function benchmark(name, fn, iterations = ITERATIONS) {
  // Warmup
  for (let i = 0; i < 100; i++) {
    fn();
  }

  // Measure
  const start = process.hrtime.bigint();
  for (let i = 0; i < iterations; i++) {
    fn();
  }
  const end = process.hrtime.bigint();

  const totalNs = Number(end - start);
  const avgNs = totalNs / iterations;
  const avgMs = avgNs / 1_000_000;
  const throughput = 1_000_000_000 / avgNs;

  console.log(`${name}:`);
  console.log(`  Avg time: ${avgMs.toFixed(3)} ms`);
  console.log(`  Throughput: ${Math.round(throughput).toLocaleString()} ops/sec`);
  console.log();

  return { avgMs, throughput };
}

// Benchmark: Embedding Generation (various text lengths)
console.log('--- Embedding Generation ---\n');

const embResults = {};
texts.forEach((text, idx) => {
  const result = benchmark(
    `Text ${idx + 1} (${text.length} chars)`,
    () => client.generateEmbedding(text)
  );
  embResults[`text${idx + 1}`] = result;
});

// Pre-generate embeddings for vector operations
const emb1 = client.generateEmbedding(texts[0]);
const emb2 = client.generateEmbedding(texts[1]);

console.log('--- Vector Operations ---\n');

// Benchmark: Cosine Similarity
const cosineResult = benchmark(
  'Cosine Similarity',
  () => client.cosineSimilarity(emb1, emb2)
);

// Benchmark: Dot Product
const dotResult = benchmark(
  'Dot Product',
  () => client.dotProduct(emb1, emb2)
);

// Benchmark: Vector Norm
const normResult = benchmark(
  'Vector Norm',
  () => client.vectorNorm(emb1)
);

// Benchmark: Normalize Vector
const normalizeResult = benchmark(
  'Normalize Vector',
  () => client.normalizeVector(emb1)
);

// Benchmark: Add Vectors
const addResult = benchmark(
  'Add Vectors',
  () => client.addVectors(emb1, emb2)
);

// Summary
console.log('=================================');
console.log('Summary:');
console.log(`  Embedding (avg): ${embResults.text1.avgMs.toFixed(3)} ms`);
console.log(`  Cosine Similarity: ${cosineResult.avgMs.toFixed(3)} ms`);
console.log(`  Dot Product: ${dotResult.avgMs.toFixed(3)} ms`);
console.log(`  Vector Norm: ${normResult.avgMs.toFixed(3)} ms`);
console.log('=================================');

