"""
FastEmbed Native Python Extension Module
Build script using setuptools and pybind11
"""

import os
import sys
import platform
from pathlib import Path
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext

# Detect platform
IS_WINDOWS = platform.system() == "Windows"
IS_LINUX = platform.system() == "Linux"
IS_MACOS = platform.system() == "Darwin"

class CMakeBuild(build_ext):
    """Custom build_ext command that compiles with proper settings"""
    
    def build_extensions(self):
        # Get pybind11 includes
        try:
            import pybind11
            pybind11_include = pybind11.get_include()
        except ImportError:
            raise RuntimeError("pybind11 is required for building FastEmbed native module")
        
        # Source files
        sources = [
            "src/fastembed_native.cpp",
            "../shared/src/embedding_lib_c.c"
        ]
        
        # Include directories
        include_dirs = [
            pybind11_include,
            "../shared/include",
        ]
        
        # Platform-specific settings
        extra_compile_args = []
        extra_link_args = []
        extra_objects = []
        
        if IS_WINDOWS:
            # Windows: Link with pre-compiled assembly object files from shared build
            import os
            shared_build_dir = os.path.normpath(os.path.join(os.getcwd(), "..", "shared", "build"))
            emb_lib_obj = os.path.join(shared_build_dir, "embedding_lib.obj")
            emb_gen_obj = os.path.join(shared_build_dir, "embedding_generator.obj")
            if not (os.path.exists(emb_lib_obj) and os.path.exists(emb_gen_obj)):
                raise RuntimeError(
                    "Assembly object files not found.\n"
                    f"Expected: {emb_lib_obj} and {emb_gen_obj}\n"
                    "Please build shared library first:\n"
                    "  scripts\\build_windows.bat  (Windows)\n"
                    "or\n"
                    "  python scripts\\build_native.py"
                )
            
            extra_objects = [emb_lib_obj, emb_gen_obj]
            
            extra_compile_args = [
                "/std:c++17",
                "/O2",
                "/W3"
            ]
        
        elif IS_LINUX or IS_MACOS:
            # Linux/macOS: Compile assembly files with NASM
            import os
            obj_dir = os.path.join(os.getcwd(), "build", "temp")
            os.makedirs(obj_dir, exist_ok=True)
            
            # Compile assembly files
            import subprocess
            
            asm_files = [
                ("../shared/src/embedding_lib.asm", os.path.join(obj_dir, "embedding_lib.o")),
                ("../shared/src/embedding_generator.asm", os.path.join(obj_dir, "embedding_generator.o"))
            ]
            
            for asm_src, asm_obj in asm_files:
                if not os.path.exists(asm_obj):
                    nasm_format = "elf64" if IS_LINUX else "macho64"
                    cmd = ["nasm", "-f", nasm_format, asm_src, "-o", asm_obj]
                    
                    try:
                        subprocess.run(cmd, check=True)
                    except subprocess.CalledProcessError:
                        raise RuntimeError(f"Failed to compile {asm_src}")
                    except FileNotFoundError:
                        raise RuntimeError(
                            "NASM not found. Please install NASM:\n"
                            "  Ubuntu/Debian: sudo apt install nasm\n"
                            "  macOS: brew install nasm"
                        )
            
            extra_objects = [obj for _, obj in asm_files]
            
            extra_compile_args = [
                "-std=c++17",
                "-O3",
                "-fPIC",
                "-march=native"
            ]
            # Note: C files will show warning about -std=c++17, but compile correctly
            
            extra_link_args = ["-lm"]
        
        # Update extension with all settings
        for ext in self.extensions:
            ext.sources = sources
            ext.include_dirs = include_dirs
            ext.extra_compile_args = extra_compile_args
            ext.extra_link_args = extra_link_args
            ext.extra_objects = extra_objects
            ext.language = "c++"
        
        # Build using parent class
        build_ext.build_extensions(self)


# Read README
readme_file = Path("README.md")
long_description = readme_file.read_text(encoding="utf-8") if readme_file.exists() else ""

setup(
    name="fastembed-native",
    version="1.0.0",
    author="FastEmbed Team",
    description="Ultra-fast native embedding library with SIMD optimizations",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/fastembed",
    ext_modules=[Extension("fastembed_native", sources=[])],
    cmdclass={"build_ext": CMakeBuild},
    install_requires=[
        "numpy>=1.20.0",
        "pybind11>=2.10.0"
    ],
    python_requires=">=3.7",
    license="AGPL-3.0",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: C++",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
    keywords="embeddings vector simd machine-learning",
    zip_safe=False,
)

