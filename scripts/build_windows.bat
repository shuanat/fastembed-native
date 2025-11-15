@echo off
REM ============================================================================
REM FastEmbed Windows Build Script
REM ============================================================================
REM
REM Purpose:
REM     Builds FastEmbed native DLL (fastembed_native.dll) for Windows
REM     using Visual Studio Build Tools and NASM assembler.
REM
REM Usage:
REM     scripts\build_windows.bat
REM
REM Requirements:
REM     - Visual Studio Build Tools 2022 (with "Desktop development with C++")
REM     - NASM (>= 2.14) - Assembly compiler
REM     - Windows OS (x64)
REM
REM Platform Support:
REM     - Windows only (x64)
REM
REM Exit Codes:
REM     0 - Success
REM     1 - Error (missing dependencies, compilation failure, etc.)
REM
REM Author:
REM     FastEmbed Team
REM ============================================================================

setlocal enabledelayedexpansion

set "EXIT_CODE=0"

REM Get script directory and find repository root
set "SCRIPT_DIR=%~dp0"
REM Remove trailing backslash
set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"

REM Find repository root by looking for .git directory or bindings\shared\src\embedding_lib.asm
set "REPO_ROOT=%CD%"
:find_root
if exist "!REPO_ROOT!\.git" goto :found_root
if exist "!REPO_ROOT!\bindings\shared\src\embedding_lib.asm" goto :found_root
if "!REPO_ROOT!"=="!REPO_ROOT:~-1!" goto :not_found
set "REPO_ROOT=!REPO_ROOT!\.."
goto :find_root

:not_found
echo [ERROR] Cannot find repository root directory
echo [ERROR] Current directory: %CD%
echo [ERROR] Script directory: %SCRIPT_DIR%
echo [ERROR] Please run this script from the repository root or bindings\shared directory
exit /b 1

:found_root
REM Change to repository root
cd /d "!REPO_ROOT!"
if !errorlevel! neq 0 (
    echo [ERROR] Failed to change to repository root directory
    echo [ERROR] Path: !REPO_ROOT!
    exit /b 1
)

REM Verify we're in the right place
if not exist "bindings\shared\src\embedding_lib.asm" (
    echo [ERROR] Repository structure not found
    echo [ERROR] Expected: bindings\shared\src\embedding_lib.asm
    echo [ERROR] Current directory: %CD%
    exit /b 1
)

echo ========================================
echo FastEmbed Windows Build Script
echo ========================================
echo.

REM Setup Visual Studio paths (use environment variable if available)
if defined ProgramFiles^(x86^) (
    set "VS_PATH=!ProgramFiles(x86)!\Microsoft Visual Studio\2022\BuildTools"
) else (
    set "VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
)

set "VS_VCVARS=!VS_PATH!\VC\Auxiliary\Build\vcvars64.bat"

if not exist "!VS_VCVARS!" (
    echo [ERROR] Visual Studio Build Tools not found at:
    echo [ERROR] "!VS_PATH!"
    echo.
    echo [ERROR] Please install Visual Studio Build Tools from:
    echo [ERROR] https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
    echo.
    echo [ERROR] Make sure to install "Desktop development with C++" workload.
    exit /b 1
)

echo [INFO] Setting up Visual Studio environment...
call "!VS_VCVARS!" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Failed to setup Visual Studio environment
    echo [ERROR] Please verify Visual Studio Build Tools installation
    exit /b 1
)

REM Check for NASM
set "NASM_EXE="
where nasm >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%i in ('where nasm') do set "NASM_EXE=%%i"
) else (
    REM Try to find NASM in common installation locations
    if exist "%LOCALAPPDATA%\bin\NASM\nasm.exe" (
        set "NASM_EXE=%LOCALAPPDATA%\bin\NASM\nasm.exe"
    ) else if exist "C:\Program Files\NASM\nasm.exe" (
        set "NASM_EXE=C:\Program Files\NASM\nasm.exe"
    ) else if exist "C:\Program Files (x86)\NASM\nasm.exe" (
        set "NASM_EXE=C:\Program Files (x86)\NASM\nasm.exe"
    )
)

if "!NASM_EXE!"=="" (
    echo [ERROR] NASM not found in PATH or standard locations.
    echo.
    echo [ERROR] Please install NASM from: https://www.nasm.us/
    echo [ERROR] And add it to your PATH environment variable.
    echo.
    echo [ERROR] Alternatively, you can use WSL to build Linux .so version:
    echo [ERROR]   wsl make shared
    exit /b 1
)

echo [INFO] Found NASM: !NASM_EXE!

REM Define source paths
set "SHARED_DIR=bindings\shared"
set "SRC_DIR=!SHARED_DIR!\src"
set "INC_DIR=!SHARED_DIR!\include"
set "BUILD_DIR=!SHARED_DIR!\build"

REM Validate source directories
if not exist "!SRC_DIR!" (
    echo [ERROR] Source directory not found: !SRC_DIR!
    exit /b 1
)
if not exist "!INC_DIR!" (
    echo [ERROR] Include directory not found: !INC_DIR!
    exit /b 1
)

REM Create build directory
if not exist "!BUILD_DIR!" (
    echo [INFO] Creating build directory...
    mkdir "!BUILD_DIR!"
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to create build directory: !BUILD_DIR!
        exit /b 1
    )
)

echo.
echo ========================================
echo Compiling Assembly files...
echo ========================================

echo [INFO] Compiling embedding_lib.asm...
"!NASM_EXE!" -f win64 "!SRC_DIR!\embedding_lib.asm" -o "!BUILD_DIR!\embedding_lib.obj"
if !errorlevel! neq 0 (
    echo [ERROR] Failed to compile embedding_lib.asm
    echo [ERROR] Command: "!NASM_EXE!" -f win64 "!SRC_DIR!\embedding_lib.asm" -o "!BUILD_DIR!\embedding_lib.obj"
    exit /b 1
)

echo [INFO] Compiling embedding_generator.asm...
"!NASM_EXE!" -f win64 "!SRC_DIR!\embedding_generator.asm" -o "!BUILD_DIR!\embedding_generator.obj"
if !errorlevel! neq 0 (
    echo [ERROR] Failed to compile embedding_generator.asm
    echo [ERROR] Command: "!NASM_EXE!" -f win64 "!SRC_DIR!\embedding_generator.asm" -o "!BUILD_DIR!\embedding_generator.obj"
    exit /b 1
)

echo.
echo ========================================
echo Compiling C files...
echo ========================================

REM Check if ONNX Runtime is available (paths relative to PROJECT_ROOT)
set "ONNX_DIR=onnxruntime"
set "ONNX_INCLUDE=!PROJECT_ROOT!\!ONNX_DIR!\include"
set "ONNX_LIB=!PROJECT_ROOT!\!ONNX_DIR!\lib"
set "USE_ONNX=0"
if exist "!ONNX_LIB!\onnxruntime.lib" (
    set "USE_ONNX=1"
    echo ONNX Runtime found - enabling ONNX support
)

REM Compile embedding_lib_c.c with ONNX support if available
echo [INFO] Compiling embedding_lib_c.c...
if "!USE_ONNX!"=="1" (
    cl /O2 /W3 /c /I"!INC_DIR!" /I"!ONNX_INCLUDE!" /DUSE_ONNX_RUNTIME /DFASTEMBED_BUILDING_LIB "!SRC_DIR!\embedding_lib_c.c" /Fo:"!BUILD_DIR!\embedding_lib_c.obj" >nul 2>&1
) else (
    cl /O2 /W3 /c /I"!INC_DIR!" /DFASTEMBED_BUILDING_LIB "!SRC_DIR!\embedding_lib_c.c" /Fo:"!BUILD_DIR!\embedding_lib_c.obj" >nul 2>&1
)
if !errorlevel! neq 0 (
    echo [ERROR] Failed to compile embedding_lib_c.c
    echo [ERROR] Running with verbose output...
    if "!USE_ONNX!"=="1" (
        cl /O2 /W3 /c /I"!INC_DIR!" /I"!ONNX_INCLUDE!" /DUSE_ONNX_RUNTIME /DFASTEMBED_BUILDING_LIB "!SRC_DIR!\embedding_lib_c.c" /Fo:"!BUILD_DIR!\embedding_lib_c.obj"
    ) else (
        cl /O2 /W3 /c /I"!INC_DIR!" /DFASTEMBED_BUILDING_LIB "!SRC_DIR!\embedding_lib_c.c" /Fo:"!BUILD_DIR!\embedding_lib_c.obj"
    )
    exit /b 1
)

REM Compile ONNX loader if ONNX Runtime is available
if "!USE_ONNX!"=="1" (
    echo [INFO] Compiling onnx_embedding_loader.c with ONNX Runtime support...
    cl /O2 /W3 /c /I"!INC_DIR!" /I"!ONNX_INCLUDE!" /DUSE_ONNX_RUNTIME /DFASTEMBED_BUILDING_LIB "!SRC_DIR!\onnx_embedding_loader.c" /Fo:"!BUILD_DIR!\onnx_embedding_loader.obj" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [WARN] Failed to compile onnx_embedding_loader.c - ONNX support disabled
        set "USE_ONNX=0"
    ) else (
        echo [INFO] Compiled onnx_embedding_loader.c with ONNX Runtime support
    )
)

echo.
echo ========================================
echo Linking DLL...
echo ========================================

REM Build link command with ONNX support if available
set "LINK_OBJS=!BUILD_DIR!\embedding_lib.obj !BUILD_DIR!\embedding_generator.obj !BUILD_DIR!\embedding_lib_c.obj"
set "LINK_LIBS=msvcrt.lib"
set "LINK_LIBPATHS=/LIBPATH:"!VCToolsInstallDir!lib\x64""

if "!USE_ONNX!"=="1" (
    set "LINK_OBJS=!LINK_OBJS! !BUILD_DIR!\onnx_embedding_loader.obj"
    set "LINK_LIBPATHS=!LINK_LIBPATHS! /LIBPATH:"!ONNX_LIB!""
    set "LINK_LIBS=!LINK_LIBS! onnxruntime.lib"
)

REM Use .def file for proper function exports
set "DEF_FILE=!SRC_DIR!\fastembed.def"
if exist "!DEF_FILE!" (
    echo [INFO] Using DEF file: !DEF_FILE!
    link /DLL /DEF:"!DEF_FILE!" /OUT:"!BUILD_DIR!\fastembed_native.dll" !LINK_OBJS! !LINK_LIBPATHS! !LINK_LIBS! >nul 2>&1
) else (
    echo [WARN] DEF file not found, linking without exports
    link /DLL /OUT:"!BUILD_DIR!\fastembed_native.dll" !LINK_OBJS! !LINK_LIBPATHS! !LINK_LIBS! >nul 2>&1
)
if !errorlevel! neq 0 (
    echo [ERROR] Failed to link DLL
    echo [ERROR] Running with verbose output...
    if exist "!DEF_FILE!" (
        link /DLL /DEF:"!DEF_FILE!" /OUT:"!BUILD_DIR!\fastembed_native.dll" !LINK_OBJS! !LINK_LIBPATHS! !LINK_LIBS!
    ) else (
        link /DLL /OUT:"!BUILD_DIR!\fastembed_native.dll" !LINK_OBJS! !LINK_LIBPATHS! !LINK_LIBS!
    )
    exit /b 1
)

REM Copy ONNX Runtime DLL to build directory if available
if "!USE_ONNX!"=="1" (
    if exist "!ONNX_LIB!\onnxruntime.dll" (
        copy /Y "!ONNX_LIB!\onnxruntime.dll" "!BUILD_DIR!\" >nul 2>&1
        if !errorlevel! equ 0 (
            echo [INFO] Copied ONNX Runtime DLL to build directory
        ) else (
            echo [WARN] Failed to copy ONNX Runtime DLL (non-critical)
        )
    )
)

REM Verify DLL was created
if not exist "!BUILD_DIR!\fastembed_native.dll" (
    echo [ERROR] Build failed: DLL not found at !BUILD_DIR!\fastembed_native.dll
    exit /b 1
)

echo.
echo ========================================
echo [INFO] Build successful!
echo ========================================
echo.
echo [INFO] Built: !BUILD_DIR!\fastembed_native.dll
echo.
echo [INFO] The native library is ready for use with:
echo [INFO]   - Node.js: Native N-API module (bindings/nodejs)
echo [INFO]   - Python: pybind11 extension (bindings/python)
echo [INFO]   - C#: P/Invoke wrapper (bindings/csharp)
echo [INFO]   - Java: JNI wrapper (bindings/java)
echo.
if "!USE_ONNX!"=="1" (
    echo [INFO] ONNX Runtime support: Enabled
) else (
    echo [INFO] ONNX Runtime support: Disabled (install with: python scripts\setup_onnx.py)
)
echo.
echo [INFO] Alternative: Use universal build script for cross-platform support:
echo [INFO]   python scripts\build_native.py
echo.

endlocal
exit /b 0
