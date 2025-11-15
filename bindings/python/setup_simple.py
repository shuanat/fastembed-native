"""
Simplified FastEmbed Native Python Extension Module
Build script using setuptools
"""

import os
import sys
from setuptools import setup, Extension

# Check if assembly object files exist
if os.name == 'nt':  # Windows
    obj_dir = os.path.join(os.getcwd(), "obj")
    if not os.path.exists(obj_dir):
        print("=" * 70)
        print("ERROR: Assembly object files not found!")
        print("=" * 70)
        print("\nPlease run build_windows.bat first to compile assembly files:")
        print("  1. build_windows.bat")
        print("  2. python setup_simple.py build_ext --inplace")
        print()
        sys.exit(1)
    
    extra_objects = [
        os.path.join(obj_dir, "embedding_lib.obj"),
        os.path.join(obj_dir, "embedding_generator.obj")
    ]
    
    extra_compile_args = ["/std:c++17", "/O2", "/W3"]
    extra_link_args = []

else:  # Linux/macOS - not implemented yet
    print("Linux/macOS build not implemented in simple setup")
    print("Please use setup.py instead")
    sys.exit(1)

# Get pybind11 includes
try:
    import pybind11
    pybind11_include = pybind11.get_include()
except ImportError:
    print("pybind11 is required. Install: pip install pybind11")
    sys.exit(1)

# Define extension
ext_modules = [
    Extension(
        'fastembed_native',
        sources=[
            'python/fastembed_native.cpp',
            'src/embedding_lib_c.c'
        ],
        include_dirs=[
            pybind11_include,
            'include',
        ],
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
        extra_objects=extra_objects,
        language='c++'
    )
]

setup(
    name='fastembed-native',
    version='1.0.1',
    ext_modules=ext_modules,
    install_requires=['numpy>=1.20.0', 'pybind11>=2.10.0'],
    python_requires='>=3.7',
    zip_safe=False,
)

