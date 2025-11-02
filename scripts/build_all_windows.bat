@echo off
REM Build all language bindings for Windows
REM Requires: Visual Studio Build Tools, NASM, Node.js, Python, .NET SDK, JDK

setlocal enabledelayedexpansion

REM Get script directory and project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
cd /d "%PROJECT_ROOT%"

echo ========================================
echo FastEmbed Windows Build Script - All Bindings
echo ========================================
echo.

REM Step 1: Build shared library
echo [1/5] Building shared native library...
call scripts\build_windows.bat
if !errorlevel! neq 0 (
    echo ERROR: Failed to build shared library
    exit /b 1
)
echo.

REM Step 2: Build Node.js binding
echo [2/5] Building Node.js binding...
cd bindings\nodejs
if exist node_modules (
    echo Node modules already installed
) else (
    echo Installing Node.js dependencies...
    call npm install
    if !errorlevel! neq 0 (
        echo ERROR: Failed to install Node.js dependencies
        cd ..\..
        exit /b 1
    )
)

REM Check for NASM (required for assembly compilation)
set "NASM_EXE="
where nasm >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%i in ('where nasm') do set "NASM_EXE=%%i"
) else (
    if exist "%LOCALAPPDATA%\bin\NASM\nasm.exe" (
        set "NASM_EXE=%LOCALAPPDATA%\bin\NASM\nasm.exe"
    ) else if exist "C:\Program Files\NASM\nasm.exe" (
        set "NASM_EXE=C:\Program Files\NASM\nasm.exe"
    ) else if exist "C:\Program Files (x86)\NASM\nasm.exe" (
        set "NASM_EXE=C:\Program Files (x86)\NASM\nasm.exe"
    )
)

if "!NASM_EXE!"=="" (
    echo ERROR: NASM not found!
    echo.
    echo Please install NASM and add it to your PATH, or install to:
    echo   %LOCALAPPDATA%\bin\NASM\nasm.exe
    echo   C:\Program Files\NASM\nasm.exe
    echo.
    echo Download from: https://www.nasm.us/
    exit /b 1
) else (
    echo Found NASM: !NASM_EXE!
    REM Add NASM directory to PATH for Node.js build
    for %%p in ("!NASM_EXE!") do set "PATH=%%~dp;%PATH%"
)
echo.

echo Building native module...
call npm run build
if !errorlevel! neq 0 (
    echo ERROR: Failed to build Node.js module
    echo.
    echo Troubleshooting:
    echo   1. Make sure NASM is in your PATH
    echo   2. Make sure Visual Studio Build Tools are installed
    echo   3. Try: npm run clean ^&^& npm run build
    cd ..\..
    exit /b 1
)
cd ..\..
echo ✓ Node.js binding built
echo.

REM Step 3: Build Python binding
echo [3/5] Building Python binding...
cd bindings\python
echo Building Python extension...
python setup.py build_ext --inplace
if !errorlevel! neq 0 (
    echo ERROR: Failed to build Python module
    cd ..\..
    exit /b 1
)
cd ..\..
echo ✓ Python binding built
echo.

REM Step 4: Build C# binding
echo [4/5] Building C# binding...
cd bindings\csharp\src
dotnet build FastEmbed.csproj
if !errorlevel! neq 0 (
    echo ERROR: Failed to build C# library
    cd ..\..\..
    exit /b 1
)
cd ..\..
echo ✓ C# binding built
echo.

REM Step 5: Build Java binding
echo [5/5] Building Java binding...
cd bindings\java\java
if exist target (
    echo Cleaning previous build...
    call mvn clean
)
echo Building JNI wrapper and Java classes...
call mvn compile
if !errorlevel! neq 0 (
    echo ERROR: Failed to build Java module
    cd ..\..\..
    exit /b 1
)
cd ..\..
echo ✓ Java binding built
echo.

echo ========================================
echo All bindings built successfully!
echo ========================================
echo.
echo Built components:
echo   - Shared library: bindings\shared\build\fastembed.dll
echo   - Node.js: bindings\nodejs\build\Release\fastembed_native.node
echo   - Python: bindings\python\fastembed_native*.pyd
echo   - C#: bindings\csharp\src\bin\Debug\net8.0\FastEmbed.dll
echo   - Java: bindings\java\java\target\classes
echo.
echo To run tests:
echo   python scripts\test_all_windows.bat
echo.

endlocal

