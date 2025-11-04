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

# ONNX Runtime is always enabled
ENABLE_ONNX = True

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
            "../shared/src/embedding_lib_c.c",
            "../shared/src/onnx_embedding_loader.c"
        ]
        
        # Include directories
        include_dirs = [
            pybind11_include,
            "../shared/include",
            "../../onnxruntime/include"
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
                "/W3",
                "/DUSE_ONNX_RUNTIME"
            ]
            
            # ONNX Runtime library
            onnx_lib_path = os.path.normpath(os.path.join(os.getcwd(), "..", "..", "onnxruntime", "lib", "onnxruntime.lib"))
            if os.path.exists(onnx_lib_path):
                extra_objects.append(onnx_lib_path)
            
            # Copy ONNX Runtime DLL to build output after compilation
            self.post_build_onnx_dll = True
            self.onnx_dll_src = os.path.normpath(os.path.join(os.getcwd(), "..", "..", "onnxruntime", "lib", "onnxruntime.dll"))
            self.onnx_dll_dst = None  # Will be set after build
        
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
                "-march=native",
                "-DUSE_ONNX_RUNTIME"
            ]
            # Note: C files will show warning about -std=c++17, but compile correctly
            
            # ONNX Runtime library
            onnx_lib_path = os.path.normpath(os.path.join(os.getcwd(), "..", "..", "onnxruntime", "lib"))
            if os.path.exists(onnx_lib_path):
                extra_link_args = [
                    "-lm",
                    f"-L{onnx_lib_path}",
                    "-lonnxruntime"
                ]
                # Add rpath for runtime library loading
                if IS_LINUX:
                    extra_link_args.append(f"-Wl,-rpath,{onnx_lib_path}")
                self.post_build_onnx_so = IS_LINUX
                self.onnx_so_src = os.path.join(onnx_lib_path, "libonnxruntime.so") if IS_LINUX else None
                self.onnx_so_dst = None  # Will be set after build
            else:
                extra_link_args = ["-lm"]
                self.post_build_onnx_so = False
        
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
        
        # Post-build: Copy ONNX Runtime DLL/SO to build output
        if IS_WINDOWS and hasattr(self, 'post_build_onnx_dll') and self.post_build_onnx_dll:
            import shutil
            for ext in self.extensions:
                # Find the built extension location
                build_lib = self.build_lib
                if build_lib:
                    ext_file = os.path.join(build_lib, self.get_ext_filename(ext.name))
                    ext_dir = os.path.dirname(ext_file)
                    
                    if os.path.exists(self.onnx_dll_src):
                        dll_dst = os.path.join(ext_dir, "onnxruntime.dll")
                        if os.path.exists(dll_dst):
                            os.remove(dll_dst)
                        shutil.copy2(self.onnx_dll_src, dll_dst)
                        print(f"Copied ONNX Runtime DLL to {dll_dst}")
        
        if (IS_LINUX or IS_MACOS) and hasattr(self, 'post_build_onnx_so') and self.post_build_onnx_so and self.onnx_so_src:
            import shutil
            for ext in self.extensions:
                build_lib = self.build_lib
                if build_lib:
                    ext_file = os.path.join(build_lib, self.get_ext_filename(ext.name))
                    ext_dir = os.path.dirname(ext_file)
                    
                    if os.path.exists(self.onnx_so_src):
                        # Find the actual .so file (might have version suffix)
                        import glob
                        so_pattern = os.path.join(os.path.dirname(self.onnx_so_src), "libonnxruntime.so*")
                        so_files = glob.glob(so_pattern)
                        if so_files:
                            so_file = sorted(so_files)[-1]  # Take the latest version
                            so_name = os.path.basename(so_file)
                            so_dst = os.path.join(ext_dir, so_name)
                            shutil.copy2(so_file, so_dst)
                            print(f"Copied ONNX Runtime library to {so_dst}")


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
    url="https://github.com/shuanat/fastembed-native",
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

