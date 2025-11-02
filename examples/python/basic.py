#!/usr/bin/env python3
"""
FastEmbed Python Example - Basic Usage

Install dependencies:
    pip install ctypes numpy

Run:
    python basic.py
"""

import ctypes
import numpy as np
import os
import sys

# Add parent directory to path to find library
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Load FastEmbed library
def load_library():
    """Load FastEmbed shared library"""
    if sys.platform == 'win32':
        lib_path = '../build/fastembed.dll'
    else:
        lib_path = '../build/fastembed.so'
    
    lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), lib_path))
    return lib

# Initialize library
lib = load_library()

# Define function signatures
DIMENSION = 768

# fastembed_generate(text, output, dimension) -> int
lib.fastembed_generate.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_float), ctypes.c_int]
lib.fastembed_generate.restype = ctypes.c_int

# fastembed_cosine_similarity(vec1, vec2, dimension) -> float
lib.fastembed_cosine_similarity.argtypes = [
    ctypes.POINTER(ctypes.c_float),
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_int
]
lib.fastembed_cosine_similarity.restype = ctypes.c_float

# fastembed_dot_product(vec1, vec2, dimension) -> float
lib.fastembed_dot_product.argtypes = [
    ctypes.POINTER(ctypes.c_float),
    ctypes.POINTER(ctypes.c_float),
    ctypes.c_int
]
lib.fastembed_dot_product.restype = ctypes.c_float

def generate_embedding(text):
    """Generate embedding for text"""
    embedding = np.zeros(DIMENSION, dtype=np.float32)
    result = lib.fastembed_generate(
        text.encode('utf-8'),
        embedding.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        DIMENSION
    )
    if result != 0:
        raise RuntimeError(f"Failed to generate embedding (code: {result})")
    return embedding

def cosine_similarity(vec1, vec2):
    """Calculate cosine similarity"""
    return lib.fastembed_cosine_similarity(
        vec1.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        vec2.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        DIMENSION
    )

def dot_product(vec1, vec2):
    """Calculate dot product"""
    return lib.fastembed_dot_product(
        vec1.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        vec2.ctypes.data_as(ctypes.POINTER(ctypes.c_float)),
        DIMENSION
    )

if __name__ == '__main__':
    print("FastEmbed Python Example")
    print("=======================\n")
    
    # Generate embeddings
    print("1. Generating embeddings...")
    embedding1 = generate_embedding("Hello, world! This is a test.")
    embedding2 = generate_embedding("Goodbye, world! Another test.")
    
    print(f"   ✓ Generated embeddings (dimension: {DIMENSION})")
    print(f"   First 5 values: {embedding1[:5]}")
    
    # Calculate similarity
    print("\n2. Calculating cosine similarity...")
    similarity = cosine_similarity(embedding1, embedding2)
    print(f"   ✓ Cosine similarity: {similarity:.4f}")
    
    # Calculate dot product
    print("\n3. Calculating dot product...")
    dot = dot_product(embedding1, embedding2)
    print(f"   ✓ Dot product: {dot:.4f}")
    
    print("\n✓ All operations completed successfully!")

