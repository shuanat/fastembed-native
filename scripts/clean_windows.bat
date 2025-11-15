@echo off
REM ============================================================================
REM FastEmbed Windows Clean Script
REM ============================================================================
REM
REM Purpose:
REM     Removes all build artifacts and compiled files from FastEmbed project
REM     to prepare for a clean build.
REM
REM Usage:
REM     scripts\clean_windows.bat
REM
REM Requirements:
REM     - Windows OS
REM     - Administrator rights (optional, for some directories)
REM
REM Platform Support:
REM     - Windows only
REM
REM Exit Codes:
REM     0 - Success
REM     1 - Error (directory access denied, etc.)
REM
REM Author:
REM     FastEmbed Team
REM ============================================================================

setlocal enabledelayedexpansion

set "EXIT_CODE=0"

echo ========================================
echo FastEmbed Windows Clean Script
echo ========================================
echo.

REM Get script directory and project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
cd /d "%PROJECT_ROOT%"

if !errorlevel! neq 0 (
    echo [ERROR] Failed to change to project root directory
    echo [ERROR] Path: %PROJECT_ROOT%
    exit /b 1
)

REM 1) Shared (native) build artifacts
if exist "bindings\shared\build" (
    echo [INFO] Cleaning bindings\shared\build ...
    rmdir /s /q "bindings\shared\build" 2>nul
    if !errorlevel! neq 0 (
        echo [WARN] Failed to remove bindings\shared\build (may be in use)
        set "EXIT_CODE=1"
    )
)

REM 2) Node.js artifacts
if exist "bindings\nodejs\build" (
    echo [INFO] Cleaning bindings\nodejs\build ...
    rmdir /s /q "bindings\nodejs\build" 2>nul
    if !errorlevel! neq 0 (
        echo [WARN] Failed to remove bindings\nodejs\build (may be in use)
        set "EXIT_CODE=1"
    )
)
for /r "bindings\nodejs" %%F in (*.node) do (
    if exist "%%F" (
        del /f /q "%%F" 2>nul
        if !errorlevel! neq 0 (
            echo [WARN] Failed to delete %%F (may be in use)
            set "EXIT_CODE=1"
        )
    )
)

REM 3) Python artifacts
if exist "bindings\python\build" (
    echo [INFO] Cleaning bindings\python\build ...
    rmdir /s /q "bindings\python\build" 2>nul
    if !errorlevel! neq 0 (
        echo [WARN] Failed to remove bindings\python\build (may be in use)
        set "EXIT_CODE=1"
    )
)
for /r "bindings\python" %%F in (*.pyd) do (
    if exist "%%F" (
        del /f /q "%%F" 2>nul
        if !errorlevel! neq 0 (
            echo [WARN] Failed to delete %%F (may be in use)
            set "EXIT_CODE=1"
        )
    )
)
for /r "bindings\python" %%F in (*.so) do (
    if exist "%%F" (
        del /f /q "%%F" 2>nul
        if !errorlevel! neq 0 (
            echo [WARN] Failed to delete %%F (may be in use)
            set "EXIT_CODE=1"
        )
    )
)
for /d /r "bindings\python" %%D in (__pycache__) do (
    if exist "%%D" (
        rmdir /s /q "%%D" 2>nul
        if !errorlevel! neq 0 (
            echo [WARN] Failed to remove %%D (may be in use)
            set "EXIT_CODE=1"
        )
    )
)

REM 4) C# artifacts
if exist "bindings\csharp\bin" (
    echo [INFO] Cleaning bindings\csharp\bin ...
    rmdir /s /q "bindings\csharp\bin" 2>nul
    if !errorlevel! neq 0 (
        echo [WARN] Failed to remove bindings\csharp\bin (may be in use)
        set "EXIT_CODE=1"
    )
)
if exist "bindings\csharp\obj" (
    echo [INFO] Cleaning bindings\csharp\obj ...
    rmdir /s /q "bindings\csharp\obj" 2>nul
    if !errorlevel! neq 0 (
        echo [WARN] Failed to remove bindings\csharp\obj (may be in use)
        set "EXIT_CODE=1"
    )
)

REM 5) Java artifacts
if exist "bindings\java\target" (
    echo [INFO] Cleaning bindings\java\target ...
    rmdir /s /q "bindings\java\target" 2>nul
    if !errorlevel! neq 0 (
        echo [WARN] Failed to remove bindings\java\target (may be in use)
        set "EXIT_CODE=1"
    )
)

echo.
if !EXIT_CODE! equ 0 (
    echo [INFO] Clean completed successfully
) else (
    echo [WARN] Clean completed with warnings (some files may be in use)
    echo [WARN] Close any applications using these files and try again
)

endlocal
exit /b %EXIT_CODE%

