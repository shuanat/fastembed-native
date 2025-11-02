@echo off
setlocal enabledelayedexpansion

echo ========================================
echo FastEmbed Windows Clean Script
echo ========================================
echo.

REM Root to project
set "ROOT=%~dp0.."
cd /d "%ROOT%"

REM 1) Shared (native) build artifacts
if exist "bindings\shared\build" (
  echo Cleaning bindings\shared\build ...
  rmdir /s /q "bindings\shared\build" 2>nul
)

REM 2) Node.js artifacts
if exist "bindings\nodejs\build" (
  echo Cleaning bindings\nodejs\build ...
  rmdir /s /q "bindings\nodejs\build" 2>nul
)
for /r "bindings\nodejs" %%F in (*.node) do (
  del /f /q "%%F" 2>nul
)

REM 3) Python artifacts
if exist "bindings\python\build" (
  echo Cleaning bindings\python\build ...
  rmdir /s /q "bindings\python\build" 2>nul
)
for /r "bindings\python" %%F in (*.pyd) do (
  del /f /q "%%F" 2>nul
)
for /r "bindings\python" %%F in (*.so) do (
  del /f /q "%%F" 2>nul
)
for /d /r "bindings\python" %%D in (__pycache__) do (
  rmdir /s /q "%%D" 2>nul
)

REM 4) C# artifacts
if exist "bindings\csharp\bin" (
  echo Cleaning bindings\csharp\bin ...
  rmdir /s /q "bindings\csharp\bin" 2>nul
)
if exist "bindings\csharp\obj" (
  echo Cleaning bindings\csharp\obj ...
  rmdir /s /q "bindings\csharp\obj" 2>nul
)

REM 5) Java artifacts
if exist "bindings\java\target" (
  echo Cleaning bindings\java\target ...
  rmdir /s /q "bindings\java\target" 2>nul
)

echo.
echo Done.
endlocal

