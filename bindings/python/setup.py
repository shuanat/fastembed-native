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
        
        # Check if ONNX Runtime is available
        import os
        onnx_include = os.path.normpath(os.path.join(os.getcwd(), "..", "onnxruntime", "include"))
        use_onnx = os.path.exists(onnx_include) and os.path.exists(os.path.join(onnx_include, "onnxruntime_c_api.h"))
        
        # Source files
        sources = [
            "src/fastembed_native.cpp",
            "../shared/src/embedding_lib_c.c"
        ]
        
        # Add ONNX loader only if ONNX Runtime is available
        if use_onnx:
            sources.append("../shared/src/onnx_embedding_loader.c")
        
        # Include directories
        include_dirs = [
            pybind11_include,
            "../shared/include"
        ]
        
        if use_onnx:
            include_dirs.append(onnx_include)
        
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
                "/DFASTEMBED_BUILDING_LIB"
            ]
            
            # ONNX Runtime support (conditional)
            if use_onnx:
                extra_compile_args.append("/DUSE_ONNX_RUNTIME")
                onnx_lib_path = os.path.normpath(os.path.join(os.getcwd(), "..", "onnxruntime", "lib", "onnxruntime.lib"))
                if os.path.exists(onnx_lib_path):
                    extra_objects.append(onnx_lib_path)
            
            # Copy ONNX Runtime DLL to build output after compilation
            self.post_build_onnx_dll = True
            self.onnx_dll_src = os.path.normpath(os.path.join(os.getcwd(), "..", "onnxruntime", "lib", "onnxruntime.dll"))
            self.onnx_dll_dst = None  # Will be set after build
        
        elif IS_LINUX or IS_MACOS:
            # Check if we're on macOS arm64 (Apple Silicon)
            import platform
            is_macos_arm64 = IS_MACOS and platform.machine() == 'arm64'
            
            import os
            import subprocess
            obj_dir = os.path.join(os.getcwd(), "build", "temp")
            os.makedirs(obj_dir, exist_ok=True)
            
            if is_macos_arm64:
                # macOS arm64: Use native ARM64 NEON assembly
                print("macOS arm64 detected - using ARM64 NEON assembly")
                
                asm_files = [
                    ("../shared/src/embedding_lib_arm64.s", os.path.join(obj_dir, "embedding_lib_arm64.o")),
                    ("../shared/src/embedding_generator_arm64.s", os.path.join(obj_dir, "embedding_generator_arm64.o"))
                ]
                
                for asm_src, asm_obj in asm_files:
                    if not os.path.exists(asm_obj):
                        cmd = ["as", "-arch", "arm64", asm_src, "-o", asm_obj]
                        
                        try:
                            subprocess.run(cmd, check=True)
                        except subprocess.CalledProcessError:
                            raise RuntimeError(f"Failed to compile {asm_src}")
                        except FileNotFoundError:
                            raise RuntimeError(
                                "ARM64 assembler (as) not found. Please install Xcode Command Line Tools:\n"
                                "  xcode-select --install"
                            )
                
                extra_objects = [obj for _, obj in asm_files]
            else:
                # Linux or macOS x86_64: Compile assembly files with NASM
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
            
            # Compile flags for Linux/macOS
            # Note: -march=native doesn't work on Apple Silicon (M1/M2/M3)
            extra_compile_args = [
                "-O3",
                "-fPIC"
            ]
            
            # macOS arm64: Use ARM64 NEON assembly (already compiled above)
            # DO NOT add -DUSE_ONLY_C - we want to use ARM64 assembly, not C-only fallback!
            
            if use_onnx:
                extra_compile_args.append("-DUSE_ONNX_RUNTIME")
            
            # ONNX Runtime library
            onnx_lib_path = os.path.normpath(os.path.join(os.getcwd(), "..", "onnxruntime", "lib"))
            if os.path.exists(onnx_lib_path):
                extra_link_args = [
                    "-lm",
                    f"-L{onnx_lib_path}",
                    "-lonnxruntime"
                ]
                # Add rpath for runtime library loading (Linux only)
                if IS_LINUX:
                    extra_link_args.append(f"-Wl,-rpath,{onnx_lib_path}")
                # Enable post-build copy for both Linux and macOS
                self.post_build_onnx_so = IS_LINUX or IS_MACOS
                # Set correct library path based on platform
                if IS_LINUX:
                    self.onnx_so_src = os.path.join(onnx_lib_path, "libonnxruntime.so")
                elif IS_MACOS:
                    self.onnx_so_src = os.path.join(onnx_lib_path, "libonnxruntime.dylib")
                else:
                    self.onnx_so_src = None
                self.onnx_so_dst = None  # Will be set after build
            else:
                extra_link_args = ["-lm"]
                self.post_build_onnx_so = False
        
        # Update extension with all settings
        for ext in self.extensions:
            ext.sources = sources
            ext.include_dirs = include_dirs
            ext.extra_link_args = extra_link_args
            ext.extra_objects = extra_objects
            ext.language = "c++"
            
            # Set compile args per source file to avoid C++17 flag on C files
            # setuptools will handle this automatically based on file extension
            ext.extra_compile_args = extra_compile_args
        
        # Build using parent class
        build_ext.build_extensions(self)
        
        # Post-build: Copy extension module to current directory
        # This ensures the module is available for direct import in tests
        # setuptools copies to src/, but tests run from bindings/python/
        import shutil
        import glob
        for ext in self.extensions:
            # Find the built extension in build_lib
            build_lib = self.build_lib
            if build_lib:
                ext_filename = self.get_ext_filename(ext.name)
                built_ext = os.path.join(build_lib, ext_filename)
                
                # Also check for versioned extensions (e.g., .cpython-311-darwin.so)
                if not os.path.exists(built_ext):
                    # Try to find any matching extension file
                    ext_pattern = os.path.join(build_lib, f"{ext.name}.*")
                    matches = glob.glob(ext_pattern)
                    if matches:
                        built_ext = matches[0]
                
                if os.path.exists(built_ext):
                    # Copy to current directory (where tests run)
                    current_dir_ext = os.path.join(os.getcwd(), os.path.basename(built_ext))
                    if os.path.exists(current_dir_ext):
                        os.remove(current_dir_ext)
                    shutil.copy2(built_ext, current_dir_ext)
                    print(f"Copied extension module to {current_dir_ext} for tests")
                    
                    # macOS: Fix rpath references using install_name_tool
                    if IS_MACOS:
                        import subprocess
                        onnx_dylibs = ['libonnxruntime.1.23.2.dylib', 'libonnxruntime.dylib']
                        for dylib in onnx_dylibs:
                            try:
                                # Change @rpath reference to @loader_path (same directory)
                                cmd = ['install_name_tool', '-change', f'@rpath/{dylib}', f'@loader_path/{dylib}', current_dir_ext]
                                subprocess.run(cmd, check=True, capture_output=True)
                                print(f"Fixed rpath for {dylib} in extension module")
                            except subprocess.CalledProcessError:
                                # Ignore if reference doesn't exist
                                pass
                        
                        # Copy ONNX Runtime dylibs to current directory
                        onnx_lib_dir = os.path.normpath(os.path.join(os.getcwd(), "..", "onnxruntime", "lib"))
                        for dylib in onnx_dylibs:
                            dylib_src = os.path.join(onnx_lib_dir, dylib)
                            dylib_dst = os.path.join(os.getcwd(), dylib)
                            if os.path.exists(dylib_src):
                                if os.path.exists(dylib_dst):
                                    os.remove(dylib_dst)
                                shutil.copy2(dylib_src, dylib_dst)
                                print(f"Copied {dylib} to test directory")
                else:
                    print(f"Warning: Could not find built extension at {built_ext}")
        
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
                        # Find the actual library file (might have version suffix)
                        import glob
                        lib_dir = os.path.dirname(self.onnx_so_src)
                        if IS_LINUX:
                            lib_pattern = os.path.join(lib_dir, "libonnxruntime.so*")
                        elif IS_MACOS:
                            lib_pattern = os.path.join(lib_dir, "libonnxruntime*.dylib")
                        else:
                            lib_pattern = None
                        
                        if lib_pattern:
                            lib_files = glob.glob(lib_pattern)
                            if lib_files:
                                lib_file = sorted(lib_files)[-1]  # Take the latest version
                                lib_name = os.path.basename(lib_file)
                                lib_dst = os.path.join(ext_dir, lib_name)
                                shutil.copy2(lib_file, lib_dst)
                                print(f"Copied ONNX Runtime library to {lib_dst}")


# Read README
readme_file = Path("README.md")
long_description = readme_file.read_text(encoding="utf-8") if readme_file.exists() else ""

setup(
    name="fastembed-native",
    version="1.0.1",
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

