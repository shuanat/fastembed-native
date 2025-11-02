"""
FastEmbed Native Python Module

High-performance embedding generation and vector operations using native C++ extensions.
"""

from typing import Union, List
import numpy as np

try:
    from . import fastembed_native
    NATIVE_AVAILABLE = True
except ImportError:
    NATIVE_AVAILABLE = False
    fastembed_native = None


class FastEmbed:
    """
    FastEmbed Native Client
    
    High-performance embedding generation using native C++ SIMD-optimized code.
    
    Args:
        dimension: Embedding dimension (default: 768)
    
    Example:
        >>> fastembed = FastEmbed(768)
        >>> embedding = fastembed.generate_embedding("example text")
        >>> print(embedding.shape)
        (768,)
    """
    
    def __init__(self, dimension: int = 768):
        if not NATIVE_AVAILABLE:
            raise RuntimeError(
                "FastEmbed native module not available. "
                "Please build the module first:\n"
                "  python setup.py build_ext --inplace"
            )
        
        self._client = fastembed_native.FastEmbedNative(dimension)
        self.dimension = dimension
    
    def generate_embedding(self, text: str) -> np.ndarray:
        """
        Generate embedding from text
        
        Args:
            text: Input text string
        
        Returns:
            NumPy array with embedding vector
        """
        return self._client.generate_embedding(text)
    
    def cosine_similarity(
        self,
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> float:
        """
        Calculate cosine similarity between two vectors
        
        Args:
            vector_a: First vector
            vector_b: Second vector
        
        Returns:
            Cosine similarity value (-1 to 1)
        """
        vec_a = np.asarray(vector_a, dtype=np.float32)
        vec_b = np.asarray(vector_b, dtype=np.float32)
        return float(self._client.cosine_similarity(vec_a, vec_b))
    
    def dot_product(
        self,
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> float:
        """
        Calculate dot product of two vectors
        
        Args:
            vector_a: First vector
            vector_b: Second vector
        
        Returns:
            Dot product value
        """
        vec_a = np.asarray(vector_a, dtype=np.float32)
        vec_b = np.asarray(vector_b, dtype=np.float32)
        return float(self._client.dot_product(vec_a, vec_b))
    
    def vector_norm(self, vector: Union[np.ndarray, List[float]]) -> float:
        """
        Calculate L2 norm of a vector
        
        Args:
            vector: Input vector
        
        Returns:
            Norm value
        """
        vec = np.asarray(vector, dtype=np.float32)
        return float(self._client.vector_norm(vec))
    
    def normalize_vector(
        self,
        vector: Union[np.ndarray, List[float]]
    ) -> np.ndarray:
        """
        Normalize vector (L2 normalization)
        
        Args:
            vector: Input vector
        
        Returns:
            Normalized vector
        """
        vec = np.asarray(vector, dtype=np.float32)
        return self._client.normalize_vector(vec)
    
    def add_vectors(
        self,
        vector_a: Union[np.ndarray, List[float]],
        vector_b: Union[np.ndarray, List[float]]
    ) -> np.ndarray:
        """
        Add two vectors element-wise
        
        Args:
            vector_a: First vector
            vector_b: Second vector
        
        Returns:
            Result vector
        """
        vec_a = np.asarray(vector_a, dtype=np.float32)
        vec_b = np.asarray(vector_b, dtype=np.float32)
        return self._client.add_vectors(vec_a, vec_b)
    
    def is_available(self) -> bool:
        """Check if native module is available"""
        return NATIVE_AVAILABLE


# Module-level convenience functions
def is_available() -> bool:
    """Check if FastEmbed native module is available"""
    return NATIVE_AVAILABLE


def generate_embedding(text: str, dimension: int = 768) -> np.ndarray:
    """
    Generate embedding from text (module-level function)
    
    Args:
        text: Input text
        dimension: Embedding dimension
    
    Returns:
        NumPy array with embedding
    """
    if not NATIVE_AVAILABLE:
        raise RuntimeError("FastEmbed native module not available")
    
    return fastembed_native.generate_embedding(text, dimension)


__all__ = [
    "FastEmbed",
    "is_available",
    "generate_embedding",
    "NATIVE_AVAILABLE"
]

__version__ = "1.0.0"

