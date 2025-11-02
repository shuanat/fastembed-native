/**
 * FastEmbed Node.js Example - Basic Usage
 * 
 * Install dependencies:
 *   npm install ffi-napi ref-napi
 * 
 * Run:
 *   node basic.js
 */

const ffi = require('ffi-napi');
const ref = require('ref-napi');

// Define C types
const floatPtr = ref.refType('float');
const charPtr = 'string';
const int = 'int';
const float = 'float';

// Load FastEmbed library
const libPath = process.platform === 'win32'
  ? '../build/fastembed.dll'
  : '../build/fastembed.so';

const fastembed = ffi.Library(libPath, {
  'fastembed_generate': [int, [charPtr, floatPtr, int]],
  'fastembed_cosine_similarity': [float, [floatPtr, floatPtr, int]],
  'fastembed_dot_product': [float, [floatPtr, floatPtr, int]],
  'fastembed_normalize': ['void', [floatPtr, int]],
  'fastembed_vector_norm': [float, [floatPtr, int]]
});

const DIMENSION = 768;

function generateEmbedding(text) {
  const embedding = Buffer.allocUnsafe(DIMENSION * 4); // float = 4 bytes
  const result = fastembed.fastembed_generate(text, embedding, DIMENSION);

  if (result !== 0) {
    throw new Error(`Failed to generate embedding (code: ${result})`);
  }

  // Convert buffer to array
  const floats = new Float32Array(embedding.buffer, embedding.byteOffset, DIMENSION);
  return Array.from(floats);
}

function cosineSimilarity(vec1, vec2) {
  const buf1 = Buffer.from(new Float32Array(vec1).buffer);
  const buf2 = Buffer.from(new Float32Array(vec2).buffer);

  return fastembed.fastembed_cosine_similarity(buf1, buf2, DIMENSION);
}

function dotProduct(vec1, vec2) {
  const buf1 = Buffer.from(new Float32Array(vec1).buffer);
  const buf2 = Buffer.from(new Float32Array(vec2).buffer);

  return fastembed.fastembed_dot_product(buf1, buf2, DIMENSION);
}

// Main example
console.log('FastEmbed Node.js Example');
console.log('========================\n');

try {
  // Generate embeddings
  console.log('1. Generating embeddings...');
  const embedding1 = generateEmbedding('Hello, world! This is a test.');
  const embedding2 = generateEmbedding('Goodbye, world! Another test.');

  console.log(`   ✓ Generated embeddings (dimension: ${DIMENSION})`);
  console.log(`   First 5 values: [${embedding1.slice(0, 5).map(v => v.toFixed(4)).join(', ')}]`);

  // Calculate similarity
  console.log('\n2. Calculating cosine similarity...');
  const similarity = cosineSimilarity(embedding1, embedding2);
  console.log(`   ✓ Cosine similarity: ${similarity.toFixed(4)}`);

  // Calculate dot product
  console.log('\n3. Calculating dot product...');
  const dot = dotProduct(embedding1, embedding2);
  console.log(`   ✓ Dot product: ${dot.toFixed(4)}`);

  console.log('\n✓ All operations completed successfully!');
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}

