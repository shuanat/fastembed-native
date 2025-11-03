/**
 * FastEmbed Node.js ONNX Benchmark
 * 
 * Compares hash-based vs ONNX embeddings for speed, memory, and quality.
 * Tests with realistic text sizes (100, 500, 2000 chars) and batch processing.
 */

import { existsSync, writeFileSync } from 'fs';
import { createRequire } from 'module';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const require = createRequire(import.meta.url);
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load native module
const fastembedNative = require('./build/Release/fastembed_native.node');

// Configuration
const DIMENSION = 768; // ONNX model only supports 768D
const ITERATIONS_SINGLE = 100;
const ITERATIONS_BATCH = 10;
const BATCH_SIZES = [1, 10, 100];

// ONNX model path
const MODEL_PATH = join(__dirname, '..', '..', 'models', 'nomic-embed-text.onnx');

// Realistic text samples
const TEXT_SAMPLES = {
  short: "machine learning algorithms and neural networks for artificial intelligence applications in computer science",
  medium: "Machine learning is a subset of artificial intelligence that focuses on developing algorithms capable of learning from data without being explicitly programmed. These algorithms can identify patterns, make predictions, and improve their performance over time through experience. Neural networks, a key component of modern machine learning, are inspired by the structure of the human brain and consist of interconnected nodes that process information in layers.",
  long: `Machine learning represents a revolutionary approach to artificial intelligence that has transformed numerous industries and applications. At its core, machine learning involves the creation of algorithms that can learn from data, identify patterns, and make decisions with minimal human intervention. This field encompasses various techniques, including supervised learning where models are trained on labeled datasets, unsupervised learning that discovers hidden patterns in unlabeled data, and reinforcement learning where agents learn through interaction with their environment.

Neural networks, particularly deep neural networks, have become the cornerstone of modern machine learning. These sophisticated systems consist of multiple layers of interconnected nodes, or neurons, that process information in a hierarchical manner. The depth and complexity of these networks enable them to capture intricate relationships in data, making them exceptionally powerful for tasks such as image recognition, natural language processing, and predictive analytics.

The applications of machine learning are vast and continue to expand. In healthcare, ML models assist in disease diagnosis and drug discovery. In finance, they power fraud detection systems and algorithmic trading. In transportation, they enable autonomous vehicles to navigate complex environments. As the field evolves, the integration of machine learning into everyday technology becomes increasingly seamless, promising a future where intelligent systems enhance human capabilities in unprecedented ways.`
};

class FastEmbedNativeClient {
  constructor(dimension) {
    this.dimension = dimension;
  }

  generateEmbedding(text) {
    return fastembedNative.generateEmbedding(text, this.dimension);
  }

  generateOnnxEmbedding(modelPath, text) {
    return fastembedNative.generateOnnxEmbedding(modelPath, text, this.dimension);
  }

  cosineSimilarity(vec1, vec2) {
    return fastembedNative.cosineSimilarity(vec1, vec2);
  }
}

function getMemoryUsage() {
  const usage = process.memoryUsage();
  return {
    rss: usage.rss / 1024 / 1024, // MB
    heapUsed: usage.heapUsed / 1024 / 1024, // MB
    heapTotal: usage.heapTotal / 1024 / 1024, // MB
    external: usage.external / 1024 / 1024 // MB
  };
}

function benchmarkFunction(name, fn, iterations, warmup = 10) {
  // Warmup
  for (let i = 0; i < warmup; i++) {
    fn();
  }

  // Force garbage collection if available
  if (global.gc) {
    global.gc();
  }

  // Measure time and memory
  const startMem = getMemoryUsage();
  const start = process.hrtime.bigint();

  const results = [];
  for (let i = 0; i < iterations; i++) {
    const result = fn();
    results.push(result);
  }

  const end = process.hrtime.bigint();
  const endMem = getMemoryUsage();

  const totalNs = Number(end - start);
  const avgNs = totalNs / iterations;
  const avgMs = avgNs / 1_000_000;
  const throughput = 1_000_000_000 / avgNs;
  const memDelta = endMem.rss - startMem.rss;

  return {
    name,
    avg_ms: avgMs,
    throughput,
    start_mem_mb: startMem.rss,
    end_mem_mb: endMem.rss,
    peak_mem_mb: endMem.rss,
    mem_delta_mb: memDelta,
    iterations,
    heap_used_mb: endMem.heapUsed,
    heap_total_mb: endMem.heapTotal
  };
}

function compareQuality(text, hashEmb, onnxEmb) {
  const similarity = fastembedNative.cosineSimilarity(hashEmb, onnxEmb);
  return similarity;
}

function main() {
  console.log('FastEmbed Node.js ONNX Benchmark');
  console.log('='.repeat(50));
  console.log(`Dimension: ${DIMENSION} (ONNX model limitation)`);
  console.log(`Model path: ${MODEL_PATH}`);
  console.log(`Model exists: ${existsSync(MODEL_PATH)}\n`);

  if (!existsSync(MODEL_PATH)) {
    console.error(`ERROR: ONNX model not found at ${MODEL_PATH}`);
    console.error('Please ensure the model is available.');
    process.exit(1);
  }

  const client = new FastEmbedNativeClient(DIMENSION);
  const results = {
    dimension: DIMENSION,
    timestamp: Date.now() / 1000,
    hash_based: {},
    onnx_based: {},
    quality_comparison: {},
    batch_performance: {}
  };

  // Single embedding benchmarks (speed + memory)
  console.log('--- Single Embedding Generation (Speed + Memory) ---\n');

  for (const [textType, text] of Object.entries(TEXT_SAMPLES)) {
    console.log(`\nText type: ${textType} (${text.length} chars)`);
    console.log('-'.repeat(50));

    // Hash-based embedding
    console.log('Hash-based:');
    const hashResult = benchmarkFunction(
      `hash_${textType}`,
      () => client.generateEmbedding(text),
      ITERATIONS_SINGLE
    );
    const hashEmb = client.generateEmbedding(text);
    console.log(`  Avg time: ${hashResult.avg_ms.toFixed(3)} ms`);
    console.log(`  Throughput: ${Math.round(hashResult.throughput).toLocaleString()} ops/sec`);
    console.log(`  Memory delta: ${hashResult.mem_delta_mb.toFixed(2)} MB`);
    results.hash_based[textType] = hashResult;

    // ONNX embedding
    console.log('\nONNX-based:');
    const onnxResult = benchmarkFunction(
      `onnx_${textType}`,
      () => client.generateOnnxEmbedding(MODEL_PATH, text),
      ITERATIONS_SINGLE
    );
    const onnxEmb = client.generateOnnxEmbedding(MODEL_PATH, text);
    console.log(`  Avg time: ${onnxResult.avg_ms.toFixed(3)} ms`);
    console.log(`  Throughput: ${Math.round(onnxResult.throughput).toLocaleString()} ops/sec`);
    console.log(`  Memory delta: ${onnxResult.mem_delta_mb.toFixed(2)} MB`);
    results.onnx_based[textType] = onnxResult;

    // Quality comparison
    const quality = compareQuality(text, hashEmb, onnxEmb);
    console.log(`\nQuality (hash vs ONNX cosine similarity): ${quality.toFixed(4)}`);
    results.quality_comparison[textType] = {
      cosine_similarity: quality,
      text_length: text.length
    };

    // Speedup ratio (how many times hash is faster than ONNX)
    const speedup = hashResult.avg_ms > 0 ? onnxResult.avg_ms / hashResult.avg_ms : 0;
    console.log(`\nSpeed ratio (hash/onnx): ${speedup.toFixed(2)}x`);
    if (speedup > 1) {
      console.log(`  Hash-based is ${speedup.toFixed(2)}x faster`);
    } else if (speedup < 1 && speedup > 0) {
      console.log(`  ONNX is ${(1 / speedup).toFixed(2)}x faster`);
    } else {
      console.log(`  Unable to calculate speed ratio`);
    }
  }

  // Batch processing benchmarks
  console.log('\n\n--- Batch Processing ---\n');

  const textList = Object.values(TEXT_SAMPLES);

  for (const batchSize of BATCH_SIZES) {
    console.log(`\nBatch size: ${batchSize}`);
    console.log('-'.repeat(50));

    // Hash-based batch
    console.log('Hash-based batch:');
    const hashBatchResult = benchmarkFunction(
      `hash_batch_${batchSize}`,
      () => {
        const results = [];
        for (let i = 0; i < batchSize; i++) {
          results.push(client.generateEmbedding(textList[i % textList.length]));
        }
        return results;
      },
      ITERATIONS_BATCH
    );
    console.log(`  Avg time per batch: ${hashBatchResult.avg_ms.toFixed(3)} ms`);
    console.log(`  Time per embedding: ${(hashBatchResult.avg_ms / batchSize).toFixed(3)} ms`);
    const hashThroughput = Math.round(1000.0 / (hashBatchResult.avg_ms / batchSize));
    console.log(`  Throughput: ${hashThroughput.toLocaleString()} embeddings/sec`);

    // ONNX batch
    console.log('\nONNX-based batch:');
    const onnxBatchResult = benchmarkFunction(
      `onnx_batch_${batchSize}`,
      () => {
        const results = [];
        for (let i = 0; i < batchSize; i++) {
          results.push(client.generateOnnxEmbedding(MODEL_PATH, textList[i % textList.length]));
        }
        return results;
      },
      ITERATIONS_BATCH
    );
    console.log(`  Avg time per batch: ${onnxBatchResult.avg_ms.toFixed(3)} ms`);
    console.log(`  Time per embedding: ${(onnxBatchResult.avg_ms / batchSize).toFixed(3)} ms`);
    const onnxThroughput = Math.round(1000.0 / (onnxBatchResult.avg_ms / batchSize));
    console.log(`  Throughput: ${onnxThroughput.toLocaleString()} embeddings/sec`);

    results.batch_performance[`batch_${batchSize}`] = {
      hash_based: hashBatchResult,
      onnx_based: onnxBatchResult
    };
  }

  // Save results to JSON
  const outputFile = join(__dirname, 'benchmark_onnx_results.json');
  writeFileSync(outputFile, JSON.stringify(results, null, 2), 'utf8');

  console.log(`\n\nResults saved to: ${outputFile}`);
  console.log('='.repeat(50));
  console.log('Benchmark completed!');
}

main();

