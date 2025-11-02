@echo off
setlocal enabledelayedexpansion
REM Wrapper script for NASM to handle path with spaces correctly
REM Usage: nasm_wrapper.bat -f format input.asm -o output.obj

REM Find NASM
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
    echo ERROR: NASM not found >&2
    exit /b 1
)

REM Call NASM with all arguments
"!NASM_EXE!" %*
endlocal

