// Test hash-based embedding patterns
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const nativeModule = require('./build/Release/fastembed_native.node');

console.log('Testing hash-based embedding patterns...\n');

const texts = [
  'machine learning artificial intelligence',
  'deep learning neural networks',
  'completely different text here',
  'another unique sentence',
];

texts.forEach((text, i) => {
  const emb = nativeModule.generateEmbedding(text, 768);
  const first10 = Array.from(emb.slice(0, 10));
  const unique = new Set(first10).size;
  console.log(`Text ${i + 1}: '${text.substring(0, 30)}...'`);
  console.log(`  First 10 values: [${first10.map(v => v.toFixed(4)).join(', ')}]`);
  console.log(`  Unique values in first 10: ${unique}/10`);
  console.log('');
});

console.log('Note: Hash-based embeddings may have patterns.');
console.log('For real embeddings, use generateOnnxEmbedding() with ONNX model.');

