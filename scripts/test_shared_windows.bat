@echo off
REM Test script for FastEmbed shared library tests on Windows
REM Tests: test_hash_functions, test_embedding_generation, test_quality_improvement, test_onnx_dimension

setlocal enabledelayedexpansion

REM Get script directory and project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
cd /d "%PROJECT_ROOT%"

set "SHARED_DIR=bindings\shared"
set "BUILD_DIR=%SHARED_DIR%\build"
set "TEST_DIR=%PROJECT_ROOT%\tests"

echo ========================================
echo FastEmbed Shared Library Tests (Windows)
echo ========================================
echo.

REM Check if build directory exists
if not exist "%BUILD_DIR%" (
    echo ERROR: Build directory not found: %BUILD_DIR%
    echo Please build the library first:
    echo   cd %SHARED_DIR%
    echo   make all
    echo   OR
    echo   scripts\build_windows.bat
    exit /b 1
)

REM Check if library exists (Windows can have .lib or .dll)
set "LIB_FOUND=0"
if exist "%BUILD_DIR%\fastembed.lib" (
    set "LIB_FOUND=1"
    echo Found library: fastembed.lib
)
if exist "%BUILD_DIR%\fastembed.dll" (
    set "LIB_FOUND=1"
    echo Found library: fastembed.dll
)
if !LIB_FOUND! equ 0 (
    echo Library not found. Attempting to build...
    cd "%SHARED_DIR%"
    make all
    if !errorlevel! neq 0 (
        echo ERROR: Failed to build library
        echo Please build manually:
        echo   cd %SHARED_DIR%
        echo   make all
        echo   OR
        echo   scripts\build_windows.bat
        exit /b 1
    )
    cd "%PROJECT_ROOT%"
    REM Check again after build
    if not exist "%BUILD_DIR%\fastembed.lib" (
        if not exist "%BUILD_DIR%\fastembed.dll" (
            echo ERROR: Library still not found after build attempt
            exit /b 1
        )
    )
)

REM Check if tests are built, if not, try to build them
if not exist "%BUILD_DIR%\test_hash_functions.exe" (
    echo Tests not found. Attempting to build tests...
    cd "%SHARED_DIR%"
    make test-build
    if !errorlevel! neq 0 (
        echo ERROR: Failed to build tests
        echo Please build manually:
        echo   cd %SHARED_DIR%
        echo   make test-build
        exit /b 1
    )
    cd "%PROJECT_ROOT%"
)

set "FAILED=0"
set "PASSED=0"

REM Test 1: test_hash_functions
echo [1/4] Running test_hash_functions...
if exist "%BUILD_DIR%\test_hash_functions.exe" (
    cd "%BUILD_DIR%"
    test_hash_functions.exe
    if !errorlevel! equ 0 (
        echo ✓ test_hash_functions PASSED
        set /a PASSED+=1
    ) else (
        echo ✗ test_hash_functions FAILED
        set /a FAILED+=1
    )
    cd "%PROJECT_ROOT%"
) else (
    echo ✗ test_hash_functions.exe not found. Build it first with: make test-build
    set /a FAILED+=1
)
echo.

REM Test 2: test_embedding_generation
echo [2/4] Running test_embedding_generation...
if exist "%BUILD_DIR%\test_embedding_generation.exe" (
    cd "%BUILD_DIR%"
    test_embedding_generation.exe
    if !errorlevel! equ 0 (
        echo ✓ test_embedding_generation PASSED
        set /a PASSED+=1
    ) else (
        echo ✗ test_embedding_generation FAILED
        set /a FAILED+=1
    )
    cd "%PROJECT_ROOT%"
) else (
    echo ✗ test_embedding_generation.exe not found. Build it first with: make test-build
    set /a FAILED+=1
)
echo.

REM Test 3: test_quality_improvement
echo [3/4] Running test_quality_improvement...
if exist "%BUILD_DIR%\test_quality_improvement.exe" (
    cd "%BUILD_DIR%"
    test_quality_improvement.exe
    if !errorlevel! equ 0 (
        echo ✓ test_quality_improvement PASSED
        set /a PASSED+=1
    ) else (
        echo ✗ test_quality_improvement FAILED
        set /a FAILED+=1
    )
    cd "%PROJECT_ROOT%"
) else (
    echo ✗ test_quality_improvement.exe not found. Build it first with: make test-build
    set /a FAILED+=1
)
echo.

REM Test 4: test_onnx_dimension (optional, only if ONNX is available)
echo [4/4] Running test_onnx_dimension...
if exist "%BUILD_DIR%\test_onnx_dimension.exe" (
    cd "%BUILD_DIR%"
    test_onnx_dimension.exe
    if !errorlevel! equ 0 (
        echo ✓ test_onnx_dimension PASSED
        set /a PASSED+=1
    ) else (
        echo ✗ test_onnx_dimension FAILED
        set /a FAILED+=1
    )
    cd "%PROJECT_ROOT%"
) else (
    echo ⚠ test_onnx_dimension.exe not found (ONNX Runtime not available - skipping)
)
echo.

echo ========================================
echo Test Summary
echo ========================================
echo Passed: !PASSED!
echo Failed: !FAILED!
echo ========================================
if !FAILED! equ 0 (
    echo All tests PASSED ✓
    exit /b 0
) else (
    echo !FAILED! test(s) FAILED ✗
    exit /b 1
)

endlocal

