@echo off
REM CMake build script for Windows
REM Builds FastEmbed library, tests, and CLI tools using CMake

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "BUILD_DIR=%PROJECT_ROOT%\bindings\shared\build_cmake"

echo ========================================
echo FastEmbed CMake Build (Windows)
echo ========================================
echo.

REM Check if CMake is installed
where cmake >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: CMake not found. Please install CMake and add it to PATH.
    echo Download from: https://cmake.org/download/
    exit /b 1
)

REM Check if NASM is installed or find it in common locations
where nasm >nul 2>&1
if !errorlevel! neq 0 (
    echo NASM not in PATH, searching in common locations...
    
    REM Check common installation locations
    set "NASM_FOUND=0"
    set "NASM_PATH1=!LOCALAPPDATA!\bin\NASM"
    set "NASM_PATH2=!ProgramFiles!\NASM"
    set "NASM_PATH3=!ProgramFiles(x86)!\NASM"
    
    if exist "!NASM_PATH1!\nasm.exe" (
        set "PATH=!PATH!;!NASM_PATH1!"
        set "NASM_FOUND=1"
        echo Found NASM: !NASM_PATH1!\nasm.exe
    )
    
    if !NASM_FOUND!==0 if exist "!NASM_PATH2!\nasm.exe" (
        set "PATH=!PATH!;!NASM_PATH2!"
        set "NASM_FOUND=1"
        echo Found NASM: !NASM_PATH2!\nasm.exe
    )
    
    if !NASM_FOUND!==0 if exist "!NASM_PATH3!\nasm.exe" (
        set "PATH=!PATH!;!NASM_PATH3!"
        set "NASM_FOUND=1"
        echo Found NASM: !NASM_PATH3!\nasm.exe
    )
    
    if !NASM_FOUND!==0 (
        echo ERROR: NASM not found. Please install NASM:
        echo   winget install NASM.NASM
        echo Or download from: https://www.nasm.us/
        exit /b 1
    )
)

REM Create build directory
if not exist "%BUILD_DIR%" (
    mkdir "%BUILD_DIR%"
)

cd "%BUILD_DIR%"

echo.
echo [1/3] Configuring CMake project...
echo.

REM Configure CMake (detect Visual Studio or use default generator)
cmake "%PROJECT_ROOT%\bindings\shared" ^
    -DBUILD_SHARED_LIBS=ON ^
    -DBUILD_CLI_TOOLS=ON ^
    -DBUILD_TESTS=ON ^
    -DBUILD_BENCHMARKS=ON ^
    -DUSE_ONNX_RUNTIME=ON ^
    -DCMAKE_BUILD_TYPE=Release

if !errorlevel! neq 0 (
    echo.
    echo ERROR: CMake configuration failed
    exit /b 1
)

echo.
echo [2/3] Building project...
echo.

REM Build the project
cmake --build . --config Release

if !errorlevel! neq 0 (
    echo.
    echo ERROR: Build failed
    exit /b 1
)

echo.
echo [3/3] Build completed successfully!
echo.
echo ========================================
echo Build Summary
echo ========================================
echo Build directory: %BUILD_DIR%
echo.
echo Libraries:
dir /b "%BUILD_DIR%\Release\fastembed.*" 2>nul
echo.
echo CLI Tools:
dir /b "%BUILD_DIR%\Release\*_cli.exe" 2>nul
echo.
echo Tests:
dir /b "%BUILD_DIR%\Release\test_*.exe" 2>nul
echo.
echo Benchmarks:
dir /b "%BUILD_DIR%\Release\benchmark_*.exe" 2>nul
echo ========================================
echo.
echo To run tests:
echo   cd %BUILD_DIR%
echo   ctest -C Release
echo.
echo Or run individual tests:
echo   %BUILD_DIR%\Release\test_hash_functions.exe
echo   %BUILD_DIR%\Release\test_embedding_generation.exe
echo   %BUILD_DIR%\Release\test_quality_improvement.exe
echo.
echo To run benchmarks:
echo   %BUILD_DIR%\Release\benchmark_improved.exe
echo ========================================

cd "%PROJECT_ROOT%"

endlocal

