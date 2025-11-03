@echo off
REM Run ONNX benchmarks for all language bindings on Windows

setlocal enabledelayedexpansion

echo.
echo ========================================
echo FastEmbed ONNX Benchmark Suite
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "RESULTS_DIR=%PROJECT_ROOT%\benchmark_results"

if not exist "%RESULTS_DIR%" mkdir "%RESULTS_DIR%"

echo Results will be saved to: %RESULTS_DIR%
echo.

REM Node.js ONNX Benchmark
echo === Node.js (N-API + ONNX) ===
cd /d "%PROJECT_ROOT%\bindings\nodejs"
if exist "benchmark_onnx.js" (
    echo Running Node.js ONNX benchmark...
    node benchmark_onnx.js
    if exist "benchmark_onnx_results.json" (
        copy /Y "benchmark_onnx_results.json" "%RESULTS_DIR%\nodejs_onnx_results.json" >nul
        echo ✓ Results saved to: benchmark_results\nodejs_onnx_results.json
    )
    echo.
) else (
    echo ⚠ benchmark_onnx.js not found, skipping
    echo.
)

REM Python ONNX Benchmark
echo === Python (pybind11 + ONNX) ===
cd /d "%PROJECT_ROOT%\bindings\python"
if exist "benchmark_onnx.py" (
    echo Running Python ONNX benchmark...
    python benchmark_onnx.py
    if exist "benchmark_onnx_results.json" (
        copy /Y "benchmark_onnx_results.json" "%RESULTS_DIR%\python_onnx_results.json" >nul
        echo ✓ Results saved to: benchmark_results\python_onnx_results.json
    )
    echo.
) else (
    echo ⚠ benchmark_onnx.py not found, skipping
    echo.
)

REM C# ONNX Benchmark
echo === C# (P/Invoke + ONNX) ===
cd /d "%PROJECT_ROOT%\bindings\csharp"
if exist "benchmark_onnx.cs" (
    echo Building and running C# ONNX benchmark...
    dotnet run --configuration Release >nul 2>&1
    if exist "benchmark_onnx_results.json" (
        copy /Y "benchmark_onnx_results.json" "%RESULTS_DIR%\csharp_onnx_results.json" >nul
        echo ✓ Results saved to: benchmark_results\csharp_onnx_results.json
    )
    echo.
) else (
    echo ⚠ benchmark_onnx.cs not found, skipping
    echo.
)

REM Java ONNX Benchmark
echo === Java (JNI + ONNX) ===
cd /d "%PROJECT_ROOT%\bindings\java\java"
if exist "benchmark_onnx.java" (
    echo Compiling Java ONNX benchmark...
    javac -cp "src/main/java" benchmark_onnx.java src/main/java/com/fastembed/FastEmbed.java 2>nul
    if errorlevel 0 (
        echo Running Java ONNX benchmark...
        java -Djava.library.path=target\native -cp .;src/main/java benchmark_onnx
        if exist "benchmark_onnx_results.json" (
            copy /Y "benchmark_onnx_results.json" "%RESULTS_DIR%\java_onnx_results.json" >nul
            echo ✓ Results saved to: benchmark_results\java_onnx_results.json
        )
    ) else (
        echo ⚠ Java compilation failed
    )
    echo.
) else (
    echo ⚠ benchmark_onnx.java not found, skipping
    echo.
)

REM Aggregate results
echo === Aggregating Results ===
cd /d "%PROJECT_ROOT%\scripts"
if exist "aggregate_benchmarks.py" (
    echo Running aggregation script...
    python aggregate_benchmarks.py
    echo.
) else (
    echo ⚠ aggregate_benchmarks.py not found
    echo.
)

echo ========================================
echo ✅ All ONNX benchmarks completed!
echo ========================================
echo.
echo Results location: %RESULTS_DIR%
echo Aggregated report: BENCHMARK_RESULTS.md
echo.

cd /d "%PROJECT_ROOT%"

