@echo off
setlocal enabledelayedexpansion

echo.
echo ========================================
echo Java JNI DLL Build Script
echo ========================================
echo.

REM Use short paths
set "JAVA_HOME=C:\Progra~1\Microsoft\jdk-17.0.17.10-hotspot"
echo JAVA_HOME: %JAVA_HOME%

REM Check if we are in Developer Command Prompt (VCINSTALLDIR is set)
if defined VCINSTALLDIR (
    echo Detected Developer Command Prompt environment
    echo VCINSTALLDIR: !VCINSTALLDIR!
    
    REM Find cl.exe using VCINSTALLDIR - try multiple methods
    echo Searching for cl.exe...
    set "CL_CMD="
    
    REM Method 1: Search in all MSVC versions
    set "MSVC_BASE=!VCINSTALLDIR!Tools\MSVC"
    if exist "!MSVC_BASE!" (
        echo Searching in: !MSVC_BASE!
        for /d %%v in ("!MSVC_BASE!\*") do (
            set "POTENTIAL_CL=%%v\bin\Hostx64\x64\cl.exe"
            if exist "!POTENTIAL_CL!" (
                set "CL_CMD=!POTENTIAL_CL!"
                echo Found compiler: !CL_CMD!
                goto :cl_found_vcinstall
            )
        )
    ) else (
        echo WARNING: MSVC directory not found at: !MSVC_BASE!
    )
    
    :cl_found_vcinstall
    if not defined CL_CMD (
        echo ERROR: cl.exe not found in any MSVC version
        echo Please check Visual Studio installation
        exit /b 1
    )
    
    REM Find link.exe in the same directory
    for %%f in ("!CL_CMD!") do set "CL_DIR=%%~dpf"
    set "LINK_CMD=!CL_DIR!link.exe"
    
    if not exist "!LINK_CMD!" (
        echo ERROR: link.exe not found at: !LINK_CMD!
        exit /b 1
    )
    
    echo Found linker: !LINK_CMD!
    
    REM Setup INCLUDE and LIB paths for compiler
    echo Setting up compiler environment...
    
    REM Get MSVC version directory from cl.exe path
    REM cl.exe is at: ...\MSVC\14.44.xxxxx\bin\Hostx64\x64\cl.exe
    REM We need: ...\MSVC\14.44.xxxxx\
    for %%f in ("!CL_CMD!") do set "MSVC_BIN=%%~dpf"
    for %%f in ("!MSVC_BIN!..\..\..\") do set "MSVC_ROOT=%%~ff"
    
    echo MSVC root: !MSVC_ROOT!
    
    REM Find Windows Kits
    set "KIT_ROOT=C:\Program Files (x86)\Windows Kits\10"
    if not exist "!KIT_ROOT!" set "KIT_ROOT=C:\Progra~2\Windows Kits\10"
    
    REM Find latest Windows SDK version
    set "SDK_VERSION="
    if exist "!KIT_ROOT!\Include" (
        for /f "delims=" %%v in ('dir /b /ad /o-n "!KIT_ROOT!\Include\10.*" 2^>nul') do (
            if not defined SDK_VERSION set "SDK_VERSION=%%v"
        )
    )
    
    if not defined SDK_VERSION (
        echo ERROR: Windows SDK not found
        exit /b 1
    )
    
    echo Windows SDK version: !SDK_VERSION!
    
    REM Setup INCLUDE paths
    set "INCLUDE=!MSVC_ROOT!\include;!KIT_ROOT!\Include\!SDK_VERSION!\ucrt;!KIT_ROOT!\Include\!SDK_VERSION!\um;!KIT_ROOT!\Include\!SDK_VERSION!\shared"
    
    REM Setup LIB paths
    set "LIB=!MSVC_ROOT!\lib\x64;!KIT_ROOT!\Lib\!SDK_VERSION!\ucrt\x64;!KIT_ROOT!\Lib\!SDK_VERSION!\um\x64"
    
    echo INCLUDE paths configured
    echo LIB paths configured
    
    goto :tools_ready
)

REM Find Visual Studio automatically
set "VS="
if exist "C:\Progra~2\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    set "VS=C:\Progra~2\Microsoft Visual Studio\2022\BuildTools"
) else if exist "C:\Progra~1\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" (
    set "VS=C:\Progra~1\Microsoft Visual Studio\2022\BuildTools"
) else if exist "C:\Progra~2\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VS=C:\Progra~2\Microsoft Visual Studio\2022\Community"
) else if exist "C:\Progra~1\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VS=C:\Progra~1\Microsoft Visual Studio\2022\Community"
)

if "%VS%"=="" (
    echo ERROR: Visual Studio not found and not in Developer Command Prompt
    exit /b 1
)

echo Visual Studio found: %VS%
echo Please run this script from Developer Command Prompt for VS 2022
echo Or the environment will be too complex to set up via vcvars64.bat
exit /b 1

:tools_ready
echo Build tools configured.

REM Get current directory and calculate relative paths
cd /d "%~dp0"
echo Current directory: %CD%
set "CURDIR=%CD%"
pushd ..\..\..
set "PROJ=%CD%"
popd
cd /d "%CURDIR%"

set "SHARED=%PROJ%\bindings\shared"
set "NATIVE=%CURDIR%\native"
set "BDIR=%CURDIR%\target\native"
set "ONNX=%PROJ%\onnxruntime"

echo.
echo Build configuration:
echo   Project root: %PROJ%
echo   Shared dir: %SHARED%
echo   Native dir: %NATIVE%
echo   Build dir: %BDIR%
echo   ONNX dir: %ONNX%
echo.

if not exist "%BDIR%" (
    echo Creating build directory: %BDIR%
    mkdir "%BDIR%"
)

REM Verify prerequisites (we don't need fastembed.dll anymore, only object files)
if not exist "%SHARED%\build\embedding_lib.obj" (
    echo ERROR: embedding_lib.obj not found at: %SHARED%\build\embedding_lib.obj
    exit /b 1
)
if not exist "%SHARED%\build\embedding_generator.obj" (
    echo ERROR: embedding_generator.obj not found at: %SHARED%\build\embedding_generator.obj
    exit /b 1
)

if not exist "%ONNX%\lib\onnxruntime.lib" (
    echo ERROR: ONNX Runtime not found at: %ONNX%\lib\onnxruntime.lib
    exit /b 1
)

echo Prerequisites check passed.
echo.

REM Verify INCLUDE and LIB environment variables are set
if not defined INCLUDE (
    echo ERROR: INCLUDE environment variable not set
    echo Please ensure you are in Developer Command Prompt with vcvars64 loaded
    exit /b 1
)

if not defined LIB (
    echo ERROR: LIB environment variable not set
    echo Please ensure you are in Developer Command Prompt with vcvars64 loaded
    exit /b 1
)

echo Environment check passed.
echo.

REM Verify vcruntime.h exists
echo Checking MSVC structure...
echo MSVC root contents:
dir /b "!MSVC_ROOT!" 2>nul

REM Try to find vcruntime.h
echo.
echo Searching for vcruntime.h in MSVC root...
dir /b /s "!MSVC_ROOT!\vcruntime.h" 2>nul

REM Check if include directory exists and build include flags
set "MSVC_INCLUDE_FLAG="
if exist "!MSVC_ROOT!include\" (
    echo Include directory exists: !MSVC_ROOT!include\
    set "MSVC_INCLUDE_FLAG=/I"!MSVC_ROOT!include""
) else (
    echo WARNING: MSVC include directory not found: !MSVC_ROOT!include\
    echo Searching for vcruntime.h in VCINSTALLDIR...
    
    REM Search in entire VCINSTALLDIR (this will take a moment)
    for /f "delims=" %%f in ('dir /b /s "!VCINSTALLDIR!vcruntime.h" 2^>nul') do (
        for %%d in ("%%~dpf.") do set "MSVC_INCLUDE_FLAG=/I"%%~fd""
        echo Found vcruntime.h at: %%f
        goto :msvc_include_found
    )
    
    :msvc_include_found
    if not defined MSVC_INCLUDE_FLAG (
        echo.
        echo ERROR: vcruntime.h not found anywhere in Visual Studio installation
        echo.
        echo This usually means the "MSVC v143 - VS 2022 C++ x64/x86 build tools" component
        echo is not installed. To fix this:
        echo   1. Open Visual Studio Installer
        echo   2. Click "Modify" on Visual Studio 2022 Community
        echo   3. Go to "Individual components" tab
        echo   4. Check "MSVC v143 - VS 2022 C++ x64/x86 build tools (Latest)"
        echo   5. Check "Windows 11 SDK (10.0.26100.0)" if not already installed
        echo   6. Click "Modify" to install
        echo.
        exit /b 1
    )
)

echo MSVC include flag: !MSVC_INCLUDE_FLAG!
echo.

echo Compiling fastembed_jni.c...
"!CL_CMD!" /c /O2 !MSVC_INCLUDE_FLAG! /I"!KIT_ROOT!\Include\!SDK_VERSION!\ucrt" /I"!KIT_ROOT!\Include\!SDK_VERSION!\um" /I"!KIT_ROOT!\Include\!SDK_VERSION!\shared" /I"%JAVA_HOME%\include" /I"%JAVA_HOME%\include\win32" /I"%SHARED%\include" /I"%ONNX%\include" /DUSE_ONNX_RUNTIME /DFASTEMBED_BUILDING_LIB "%NATIVE%\fastembed_jni.c" /Fo"%BDIR%\fjni.obj"
if errorlevel 1 goto :err

echo Compiling embedding_lib_c.c...
"!CL_CMD!" /c /O2 !MSVC_INCLUDE_FLAG! /I"!KIT_ROOT!\Include\!SDK_VERSION!\ucrt" /I"!KIT_ROOT!\Include\!SDK_VERSION!\um" /I"!KIT_ROOT!\Include\!SDK_VERSION!\shared" /I"%SHARED%\include" /I"%ONNX%\include" /DUSE_ONNX_RUNTIME /DFASTEMBED_BUILDING_LIB "%SHARED%\src\embedding_lib_c.c" /Fo"%BDIR%\elib.obj"
if errorlevel 1 goto :err

echo Compiling onnx_embedding_loader.c...
"!CL_CMD!" /c /O2 !MSVC_INCLUDE_FLAG! /I"!KIT_ROOT!\Include\!SDK_VERSION!\ucrt" /I"!KIT_ROOT!\Include\!SDK_VERSION!\um" /I"!KIT_ROOT!\Include\!SDK_VERSION!\shared" /I"%SHARED%\include" /I"%ONNX%\include" /DUSE_ONNX_RUNTIME /DFASTEMBED_BUILDING_LIB "%SHARED%\src\onnx_embedding_loader.c" /Fo"%BDIR%\onnx.obj"
if errorlevel 1 goto :err

echo Linking...
REM Link WITHOUT fastembed.lib to avoid old ONNX Runtime dependency
REM All code is already compiled into fjni.obj, elib.obj, onnx.obj
"!LINK_CMD!" /DLL /OUT:"%BDIR%\fastembed_jni.dll" "%BDIR%\fjni.obj" "%BDIR%\elib.obj" "%BDIR%\onnx.obj" "%SHARED%\build\embedding_lib.obj" "%SHARED%\build\embedding_generator.obj" "%ONNX%\lib\onnxruntime.lib" /LIBPATH:"!MSVC_ROOT!lib\x64" /LIBPATH:"!KIT_ROOT!\Lib\!SDK_VERSION!\ucrt\x64" /LIBPATH:"!KIT_ROOT!\Lib\!SDK_VERSION!\um\x64"
if errorlevel 1 goto :err

copy /Y "%ONNX%\lib\onnxruntime.dll" "%BDIR%\" >nul
REM Don't copy fastembed.dll - we don't need it anymore, all code is in fastembed_jni.dll

echo.
echo SUCCESS: %BDIR%\fastembed_jni.dll
exit /b 0

:err
echo.
echo BUILD FAILED
exit /b 1

