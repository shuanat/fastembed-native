@echo off
REM Build script for FastEmbed Windows DLL
REM Requires: Visual Studio Build Tools, NASM

setlocal enabledelayedexpansion

REM Get script directory and project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
cd /d "%PROJECT_ROOT%"

echo ========================================
echo FastEmbed Windows Build Script
echo ========================================
echo.

REM Настройка путей к Visual Studio (используем переменную окружения если доступна)
if defined ProgramFiles^(x86^) (
    set "VS_PATH=!ProgramFiles(x86)!\Microsoft Visual Studio\2022\BuildTools"
) else (
    set "VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
)

set "VS_VCVARS=!VS_PATH!\VC\Auxiliary\Build\vcvars64.bat"

if not exist "!VS_VCVARS!" (
    echo ERROR: Visual Studio Build Tools not found at:
    echo "!VS_PATH!"
    echo.
    echo Please install Visual Studio Build Tools from:
    echo https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
    echo.
    echo Make sure to install "Desktop development with C++" workload.
    exit /b 1
)

echo Setting up Visual Studio environment...
call "!VS_VCVARS!" >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Failed to setup Visual Studio environment
    exit /b 1
)

REM Проверка наличия NASM
set "NASM_EXE="
where nasm >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%i in ('where nasm') do set "NASM_EXE=%%i"
) else (
    REM Попробовать найти NASM в типичных местах установки
    if exist "%LOCALAPPDATA%\bin\NASM\nasm.exe" (
        set "NASM_EXE=%LOCALAPPDATA%\bin\NASM\nasm.exe"
    ) else if exist "C:\Program Files\NASM\nasm.exe" (
        set "NASM_EXE=C:\Program Files\NASM\nasm.exe"
    ) else if exist "C:\Program Files (x86)\NASM\nasm.exe" (
        set "NASM_EXE=C:\Program Files (x86)\NASM\nasm.exe"
    )
)

if "!NASM_EXE!"=="" (
    echo WARNING: NASM not found in PATH or standard locations.
    echo.
    echo Please install NASM from: https://www.nasm.us/
    echo And add it to your PATH environment variable.
    echo.
    echo Alternatively, you can use WSL to build Linux .so version:
    echo   wsl make shared
    exit /b 1
)

echo Found NASM: !NASM_EXE!

REM Определение путей к исходникам
set "SHARED_DIR=bindings\shared"
set "SRC_DIR=!SHARED_DIR!\src"
set "INC_DIR=!SHARED_DIR!\include"
set "BUILD_DIR=!SHARED_DIR!\build"

REM Создание директории build
if not exist "!BUILD_DIR!" (
    echo Creating build directory...
    mkdir "!BUILD_DIR!"
)

echo.
echo ========================================
echo Compiling Assembly files...
echo ========================================

"!NASM_EXE!" -f win64 "!SRC_DIR!\embedding_lib.asm" -o "!BUILD_DIR!\embedding_lib.obj"
if !errorlevel! neq 0 (
    echo ERROR: Failed to compile embedding_lib.asm
    exit /b 1
)

"!NASM_EXE!" -f win64 "!SRC_DIR!\embedding_generator.asm" -o "!BUILD_DIR!\embedding_generator.obj"
if !errorlevel! neq 0 (
    echo ERROR: Failed to compile embedding_generator.asm
    exit /b 1
)

echo.
echo ========================================
echo Compiling C files...
echo ========================================

cl /O2 /W3 /c /I"!INC_DIR!" "!SRC_DIR!\embedding_lib_c.c" /Fo:"!BUILD_DIR!\embedding_lib_c.obj" >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Failed to compile embedding_lib_c.c
    echo Running with verbose output...
    cl /O2 /W3 /c /I"!INC_DIR!" "!SRC_DIR!\embedding_lib_c.c" /Fo:"!BUILD_DIR!\embedding_lib_c.obj"
    exit /b 1
)

echo.
echo ========================================
echo Linking DLL...
echo ========================================

link /DLL /OUT:"!BUILD_DIR!\fastembed.dll" "!BUILD_DIR!\embedding_lib.obj" "!BUILD_DIR!\embedding_generator.obj" "!BUILD_DIR!\embedding_lib_c.obj" /LIBPATH:"!VCToolsInstallDir!lib\x64" msvcrt.lib >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Failed to link DLL
    echo Running with verbose output...
    link /DLL /OUT:"!BUILD_DIR!\fastembed.dll" "!BUILD_DIR!\embedding_lib.obj" "!BUILD_DIR!\embedding_generator.obj" "!BUILD_DIR!\embedding_lib_c.obj" /LIBPATH:"!VCToolsInstallDir!lib\x64" msvcrt.lib
    exit /b 1
)

echo.
echo ========================================
echo Build successful!
echo ========================================
echo.
echo Built: !BUILD_DIR!\fastembed.dll
echo.
echo The native library is ready for use with:
echo   - Node.js: Native N-API module (bindings/nodejs)
echo   - Python: pybind11 extension (bindings/python)
echo   - C#: P/Invoke wrapper (bindings/csharp)
echo   - Java: JNI wrapper (bindings/java)
echo.
echo Alternative: Use universal build script for cross-platform support:
echo   python scripts\build_native.py
echo.

endlocal
