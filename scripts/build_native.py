#!/usr/bin/env python3
"""
Universal build script for FastEmbed native library
Supports: Windows (.dll), Linux (.so), macOS (.dylib)
"""

import sys
import os
import platform
import subprocess
import shutil
from pathlib import Path

# Platform detection
IS_WINDOWS = platform.system() == "Windows"
IS_LINUX = platform.system() == "Linux"
IS_MACOS = platform.system() == "Darwin"

# Get script directory and project root
SCRIPT_DIR = Path(__file__).parent.resolve()
PROJECT_ROOT = SCRIPT_DIR.parent
SHARED_DIR = PROJECT_ROOT / "bindings" / "shared"
SRC_DIR = SHARED_DIR / "src"
INC_DIR = SHARED_DIR / "include"
BUILD_DIR = SHARED_DIR / "build"

def find_nasm():
    """Find NASM executable"""
    nasm = shutil.which("nasm")
    if nasm:
        return nasm
    
    # Try common Windows locations
    if IS_WINDOWS:
        common_paths = [
            Path(os.environ.get("LOCALAPPDATA", "")) / "bin" / "NASM" / "nasm.exe",
            Path("C:\\Program Files\\NASM\\nasm.exe"),
            Path("C:\\Program Files (x86)\\NASM\\nasm.exe"),
        ]
        for path in common_paths:
            if path.exists():
                return str(path)
    
    return None

def check_nasm():
    """Check if NASM is available"""
    nasm = find_nasm()
    if not nasm:
        print("❌ ERROR: NASM not found!")
        print()
        print("Please install NASM:")
        if IS_WINDOWS:
            print("  1. Download from: https://www.nasm.us/")
            print("  2. Add to PATH or install to default location")
        elif IS_MACOS:
            print("  brew install nasm")
        else:
            print("  sudo apt install nasm  # Ubuntu/Debian")
            print("  sudo yum install nasm   # RHEL/CentOS")
        return None
    return nasm

def check_compiler():
    """Check if compiler is available"""
    if IS_WINDOWS:
        # Check for Visual Studio
        vs_paths = [
            Path(os.environ.get("ProgramFiles(x86)", "")) / "Microsoft Visual Studio" / "2022" / "BuildTools",
            Path("C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools"),
        ]
        for vs_path in vs_paths:
            vcvars = vs_path / "VC" / "Auxiliary" / "Build" / "vcvars64.bat"
            if vcvars.exists():
                return True
        print("❌ ERROR: Visual Studio Build Tools not found!")
        print()
        print("Please install Visual Studio Build Tools from:")
        print("  https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022")
        print()
        print("Make sure to install 'Desktop development with C++' workload.")
        return False
    else:
        # Check for GCC or Clang
        gcc = shutil.which("gcc")
        clang = shutil.which("clang")
        if not gcc and not clang:
            print("❌ ERROR: C compiler not found!")
            print()
            if IS_MACOS:
                print("Install Xcode Command Line Tools:")
                print("  xcode-select --install")
            else:
                print("Install GCC:")
                print("  sudo apt install build-essential  # Ubuntu/Debian")
            return False
        return True

def compile_assembly(nasm_exe):
    """Compile assembly files"""
    print("Compiling Assembly files...")
    
    if IS_WINDOWS:
        nasm_format = "win64"
        obj_ext = ".obj"
    elif IS_MACOS:
        nasm_format = "macho64"
        obj_ext = ".o"
    else:  # Linux
        nasm_format = "elf64"
        obj_ext = ".o"
    
    asm_files = [
        ("embedding_lib.asm", "embedding_lib" + obj_ext),
        ("embedding_generator.asm", "embedding_generator" + obj_ext),
    ]
    
    for asm_file, obj_file in asm_files:
        asm_path = SRC_DIR / asm_file
        obj_path = BUILD_DIR / obj_file
        
        cmd = [nasm_exe, "-f", nasm_format, str(asm_path), "-o", str(obj_path)]
        print(f"  {asm_file} -> {obj_file}")
        
        try:
            subprocess.run(cmd, check=True, capture_output=True)
        except subprocess.CalledProcessError as e:
            print(f"❌ ERROR: Failed to compile {asm_file}")
            print(f"   Command: {' '.join(cmd)}")
            if e.stderr:
                print(f"   Error: {e.stderr.decode()}")
            return False
    
    return True

def compile_c_files():
    """Compile C files"""
    print("Compiling C files...")
    
    c_file = "embedding_lib_c.c"
    c_path = SRC_DIR / c_file
    
    if IS_WINDOWS:
        obj_file = BUILD_DIR / "embedding_lib_c.obj"
        # Find vcvars64.bat
        vs_paths = [
            Path(os.environ.get("ProgramFiles(x86)", "")) / "Microsoft Visual Studio" / "2022" / "BuildTools",
            Path("C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools"),
        ]
        vcvars = None
        for vs_path in vs_paths:
            vc = vs_path / "VC" / "Auxiliary" / "Build" / "vcvars64.bat"
            if vc.exists():
                vcvars = vc
                break
        
        if not vcvars:
            print("❌ ERROR: Visual Studio Build Tools not found!")
            return False
        
        # Check if ONNX Runtime is available
        onnx_dir = PROJECT_ROOT / "onnxruntime"
        onnx_include = onnx_dir / "include"
        onnx_lib = onnx_dir / "lib"
        use_onnx = (onnx_lib / "onnxruntime.lib").exists()
        
        # Build compile command with ONNX support if available
        include_flags = f'/I"{INC_DIR}"'
        if use_onnx and onnx_include.exists():
            include_flags += f' /I"{onnx_include}"'
            define_flags = '/DUSE_ONNX_RUNTIME /DFASTEMBED_BUILDING_LIB'
        else:
            define_flags = '/DFASTEMBED_BUILDING_LIB'
        
        # Compile using cl via vcvars
        print(f"  {c_file} -> {obj_file.name}")
        cmd = f'call "{vcvars}" && cl /O2 /W3 /c {include_flags} {define_flags} "{c_path}" /Fo:"{obj_file}"'
        try:
            subprocess.run(cmd, shell=True, check=True, capture_output=True)
        except subprocess.CalledProcessError as e:
            print(f"❌ ERROR: Failed to compile {c_file}")
            if e.stderr:
                print(f"   Error: {e.stderr.decode()}")
            # Try again with verbose output
            cmd_verbose = f'call "{vcvars}" && cl /O2 /W3 /c {include_flags} {define_flags} "{c_path}" /Fo:"{obj_file}"'
            subprocess.run(cmd_verbose, shell=True)
            return False
        
        # Compile ONNX loader if ONNX Runtime is available
        if use_onnx:
            onnx_c_file = "onnx_embedding_loader.c"
            onnx_c_path = SRC_DIR / onnx_c_file
            onnx_obj_file = BUILD_DIR / "onnx_embedding_loader.obj"
            
            print(f"  {onnx_c_file} -> {onnx_obj_file.name} (ONNX Runtime support)")
            onnx_cmd = f'call "{vcvars}" && cl /O2 /W3 /c {include_flags} {define_flags} "{onnx_c_path}" /Fo:"{onnx_obj_file}"'
            try:
                subprocess.run(onnx_cmd, shell=True, check=True, capture_output=True)
            except subprocess.CalledProcessError as e:
                print(f"⚠️  WARN: Failed to compile {onnx_c_file} - ONNX support disabled")
                if e.stderr:
                    print(f"   Error: {e.stderr.decode()}")
                use_onnx = False
        
        return True, use_onnx
    else:
        obj_file = BUILD_DIR / "embedding_lib_c.o"
        gcc = shutil.which("gcc") or shutil.which("clang")
        
        # Check if ONNX Runtime is available
        onnx_dir = PROJECT_ROOT / "onnxruntime"
        onnx_include = onnx_dir / "include"
        onnx_lib = onnx_dir / "lib"
        use_onnx = (onnx_lib / "onnxruntime.so").exists() or (onnx_lib / "libonnxruntime.so").exists()
        
        # Build compile command with ONNX support if available
        cmd = [
            gcc, "-O2", "-Wall", "-c",
            f"-I{INC_DIR}",
            "-DFASTEMBED_BUILDING_LIB",
        ]
        if use_onnx and onnx_include.exists():
            cmd.extend([f"-I{onnx_include}", "-DUSE_ONNX_RUNTIME"])
        cmd.extend([
            str(c_path),
            "-o", str(obj_file)
        ])
        
        print(f"  {c_file} -> {obj_file.name}")
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError:
            print(f"❌ ERROR: Failed to compile {c_file}")
            return False
        
        # Compile ONNX loader if ONNX Runtime is available
        if use_onnx:
            onnx_c_file = "onnx_embedding_loader.c"
            onnx_c_path = SRC_DIR / onnx_c_file
            onnx_obj_file = BUILD_DIR / "onnx_embedding_loader.o"
            
            onnx_cmd = [
                gcc, "-O2", "-Wall", "-c",
                f"-I{INC_DIR}",
                "-DFASTEMBED_BUILDING_LIB",
            ]
            if onnx_include.exists():
                onnx_cmd.extend([f"-I{onnx_include}", "-DUSE_ONNX_RUNTIME"])
            onnx_cmd.extend([
                str(onnx_c_path),
                "-o", str(onnx_obj_file)
            ])
            
            print(f"  {onnx_c_file} -> {onnx_obj_file.name} (ONNX Runtime support)")
            try:
                subprocess.run(onnx_cmd, check=True)
            except subprocess.CalledProcessError:
                print(f"⚠️  WARN: Failed to compile {onnx_c_file} - ONNX support disabled")
                use_onnx = False
    
    return True, use_onnx

def link_library(use_onnx=False):
    """Link native library"""
    print("Linking native library...")
    
    if IS_WINDOWS:
        dll_file = BUILD_DIR / "fastembed_native.dll"
        obj_files = [
            BUILD_DIR / "embedding_lib.obj",
            BUILD_DIR / "embedding_generator.obj",
            BUILD_DIR / "embedding_lib_c.obj",
        ]
        
        # Add ONNX loader object if ONNX Runtime is available
        if use_onnx:
            onnx_obj = BUILD_DIR / "onnx_embedding_loader.obj"
            if onnx_obj.exists():
                obj_files.append(onnx_obj)
        
        # Find vcvars64.bat
        vs_paths = [
            Path(os.environ.get("ProgramFiles(x86)", "")) / "Microsoft Visual Studio" / "2022" / "BuildTools",
            Path("C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools"),
        ]
        vcvars = None
        for vs_path in vs_paths:
            vc = vs_path / "VC" / "Auxiliary" / "Build" / "vcvars64.bat"
            if vc.exists():
                vcvars = vc
                break
        
        if not vcvars:
            print("❌ ERROR: Visual Studio Build Tools not found!")
            return False
        
        # Link using link.exe via vcvars
        # vcvars is at: VC\Auxiliary\Build\vcvars64.bat
        # We need: VC\Tools\MSVC\<version>\lib\x64
        vc_dir = vcvars.parent.parent.parent  # Go from Build\vcvars64.bat to VC
        tools_dir = vc_dir / "Tools"
        
        # Find MSVC version directory
        lib_path = None
        if tools_dir.exists():
            msvc_dir = tools_dir / "MSVC"
            if msvc_dir.exists():
                # Find latest version directory
                versions = sorted([d for d in msvc_dir.iterdir() if d.is_dir()], reverse=True)
                for version_dir in versions:
                    lib_candidate = version_dir / "lib" / "x64"
                    if lib_candidate.exists():
                        lib_path = lib_candidate
                        break
        
        if not lib_path:
            # Fallback: use environment variable if available
            vctools_install_dir = os.environ.get("VCToolsInstallDir")
            if vctools_install_dir:
                lib_path = Path(vctools_install_dir) / "lib" / "x64"
            else:
                print("❌ ERROR: Could not find VC++ library path")
                print(f"   Searched: {tools_dir}")
                return False
        
        # Check if ONNX Runtime is available for linking
        onnx_dir = PROJECT_ROOT / "onnxruntime"
        onnx_lib = onnx_dir / "lib"
        lib_paths = [f'/LIBPATH:"{lib_path}"']
        libs = ["msvcrt.lib"]
        
        if use_onnx and (onnx_lib / "onnxruntime.lib").exists():
            lib_paths.append(f'/LIBPATH:"{onnx_lib}"')
            libs.append("onnxruntime.lib")
        
        obj_str = " ".join(f'"{obj}"' for obj in obj_files)
        lib_paths_str = " ".join(lib_paths)
        libs_str = " ".join(libs)
        
        # Use .def file if available
        def_file = SRC_DIR / "fastembed.def"
        if def_file.exists():
            cmd = f'call "{vcvars}" && link /DLL /DEF:"{def_file}" /OUT:"{dll_file}" {obj_str} {lib_paths_str} {libs_str}'
        else:
            cmd = f'call "{vcvars}" && link /DLL /OUT:"{dll_file}" {obj_str} {lib_paths_str} {libs_str}'
        
        try:
            subprocess.run(cmd, shell=True, check=True, capture_output=True)
            print(f"✅ Built: {dll_file}")
            
            # Copy ONNX Runtime DLL if available
            if use_onnx:
                onnx_dll = onnx_lib / "onnxruntime.dll"
                if onnx_dll.exists():
                    import shutil
                    shutil.copy2(onnx_dll, BUILD_DIR)
                    print(f"✅ Copied ONNX Runtime DLL to build directory")
            
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ ERROR: Failed to link DLL")
            if e.stderr:
                print(f"   Error: {e.stderr.decode()}")
            # Try again with verbose output
            if def_file.exists():
                cmd_verbose = f'call "{vcvars}" && link /DLL /DEF:"{def_file}" /OUT:"{dll_file}" {obj_str} {lib_paths_str} {libs_str}'
            else:
                cmd_verbose = f'call "{vcvars}" && link /DLL /OUT:"{dll_file}" {obj_str} {lib_paths_str} {libs_str}'
            subprocess.run(cmd_verbose, shell=True)
            return False
    
    elif IS_MACOS:
        dylib_file = BUILD_DIR / "libfastembed.dylib"
        obj_files = [
            BUILD_DIR / "embedding_lib.o",
            BUILD_DIR / "embedding_generator.o",
            BUILD_DIR / "embedding_lib_c.o",
        ]
        
        cmd = [
            "gcc" if shutil.which("gcc") else "clang",
            "-shared",
            "-o", str(dylib_file),
            *[str(obj) for obj in obj_files],
            "-lm"
        ]
        
        try:
            subprocess.run(cmd, check=True)
            print(f"✅ Built: {dylib_file}")
            return True
        except subprocess.CalledProcessError:
            print(f"❌ ERROR: Failed to link dylib")
            return False
    
    else:  # Linux
        so_file = BUILD_DIR / "libfastembed.so"
        obj_files = [
            BUILD_DIR / "embedding_lib.o",
            BUILD_DIR / "embedding_generator.o",
            BUILD_DIR / "embedding_lib_c.o",
        ]
        
        cmd = [
            "gcc" if shutil.which("gcc") else "clang",
            "-shared",
            "-o", str(so_file),
            *[str(obj) for obj in obj_files],
            "-lm"
        ]
        
        try:
            subprocess.run(cmd, check=True)
            print(f"✅ Built: {so_file}")
            return True
        except subprocess.CalledProcessError:
            print(f"❌ ERROR: Failed to link .so")
            return False

def main():
    """Main build function"""
    print("=" * 60)
    print("FastEmbed Native Library Build Script")
    print("=" * 60)
    print()
    print(f"Platform: {platform.system()} {platform.machine()}")
    print(f"Project root: {PROJECT_ROOT}")
    print()
    
    # Check prerequisites
    nasm = check_nasm()
    if not nasm:
        return 1
    
    if not check_compiler():
        return 1
    
    # Create build directory
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    
    # Compile assembly
    if not compile_assembly(nasm):
        return 1
    
    print()
    
    # Compile C files
    compile_result = compile_c_files()
    if not compile_result:
        return 1
    
    success, use_onnx = compile_result
    if not success:
        return 1
    
    print()
    
    # Link library
    if not link_library(use_onnx):
        return 1
    
    print()
    print("=" * 60)
    print("Build successful!")
    print("=" * 60)
    print()
    
    if IS_WINDOWS:
        lib_file = BUILD_DIR / "fastembed.dll"
    elif IS_MACOS:
        lib_file = BUILD_DIR / "libfastembed.dylib"
    else:
        lib_file = BUILD_DIR / "libfastembed.so"
    
    print(f"Built: {lib_file}")
    print()
    print("The native library is ready for use with:")
    print("  - Node.js: Native N-API module (bindings/nodejs)")
    print("  - Python: pybind11 extension (bindings/python)")
    print("  - C#: P/Invoke wrapper (bindings/csharp)")
    print("  - Java: JNI wrapper (bindings/java)")
    print()
    print("To build language bindings:")
    if IS_WINDOWS:
        print("  scripts\\build_all_windows.bat  # Build all bindings")
        print("  Or use language-specific commands:")
        print("    cd bindings\\nodejs && npm install && npm run build")
        print("    cd bindings\\python && python setup.py build_ext --inplace")
        print("    cd bindings\\csharp\\src && dotnet build")
        print("    cd bindings\\java\\java && mvn compile")
    else:
        print("  make all          # Build all bindings")
        print("  make shared       # Build shared library only")
    print()
    print("To run tests:")
    if IS_WINDOWS:
        print("  scripts\\test_all_windows.bat")
    else:
        print("  make test")
    print()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

