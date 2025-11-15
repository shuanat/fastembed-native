<#
.SYNOPSIS
    FastEmbed Windows Build Script (PowerShell)

.DESCRIPTION
    Builds FastEmbed native DLL (fastembed_native.dll) for Windows
    using Visual Studio Build Tools and NASM assembler.
    
    This script replaces the fragile batch script with robust PowerShell
    implementation featuring:
    - Native error handling (try/catch)
    - Better MSVC detection (vswhere.exe)
    - Structured logging
    - Clear variable scoping

.PARAMETER Clean
    Clean build artifacts before building

.EXAMPLE
    .\scripts\build_windows.ps1
    
.EXAMPLE
    .\scripts\build_windows.ps1 -Clean

.NOTES
    Requirements:
    - Visual Studio Build Tools 2022 (with "Desktop development with C++")
    - NASM (>= 2.14) - Assembly compiler
    - Windows OS (x64)
    
    Exit Codes:
    - 0: Success
    - 1: Error (missing dependencies, compilation failure, etc.)
    
    Author: FastEmbed Team
    Version: 2.0 (PowerShell rewrite for Phase 1, Task 1.2)
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Clean build artifacts before building')]
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ============================================================================
# Logging Functions
# ============================================================================

function Write-BuildLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    $color = switch ($Level) {
        'SUCCESS' {
            'Green' 
        }
        'WARNING' {
            'Yellow' 
        }
        'ERROR' {
            'Red' 
        }
        'DEBUG' {
            'Gray' 
        }
        default {
            'White' 
        }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# ============================================================================
# Environment Detection
# ============================================================================

function Find-RepositoryRoot {
    Write-BuildLog 'Searching for repository root...' -Level DEBUG
    
    $currentDir = Get-Location
    $maxDepth = 10
    $depth = 0
    
    while ($depth -lt $maxDepth) {
        # Check for .git or characteristic files
        if ((Test-Path (Join-Path $currentDir '.git')) -or 
            (Test-Path (Join-Path $currentDir 'bindings\shared\src\embedding_lib.asm'))) {
            Write-BuildLog "Repository root found: $currentDir" -Level DEBUG
            return $currentDir
        }
        
        $parent = Split-Path $currentDir -Parent
        if (-not $parent -or $parent -eq $currentDir) {
            break
        }
        
        $currentDir = $parent
        $depth++
    }
    
    throw "Cannot find repository root directory (searched up $depth levels)"
}

function Find-MSVC {
    <#
    .SYNOPSIS
        Detect Visual Studio and initialize MSVC environment
    .DESCRIPTION
        Uses multiple strategies to find Visual Studio:
        1. Check if cl.exe already in PATH (from setup-msbuild@v2)
        2. Use vswhere.exe (same as setup-msbuild@v2)
        3. Check VCToolsInstallDir environment variable
        4. Check MSBuild environment variable path
        5. Fallback to standard installation paths
    #>
    
    Write-BuildLog 'Detecting Visual Studio Build Tools...' -Level INFO
    
    # Strategy 1: Check if cl.exe already in PATH (setup-msbuild@v2 sets this)
    if (Get-Command cl -ErrorAction SilentlyContinue) {
        Write-BuildLog 'cl.exe found in PATH (GitHub Actions: setup-msbuild@v2)' -Level SUCCESS
        return $true
    }
    
    # Strategy 2: Use vswhere.exe (same tool as setup-msbuild@v2)
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        Write-BuildLog 'Using vswhere.exe to locate Visual Studio...' -Level DEBUG
        
        try {
            # Get latest Visual Studio installation (any edition)
            $vsPath = & $vswhere -latest -property installationPath 2>$null
            
            if ($vsPath -and (Test-Path $vsPath)) {
                Write-BuildLog "Visual Studio found: $vsPath" -Level DEBUG
                
                # Check for vcvarsall.bat
                $vcvarsall = Join-Path $vsPath 'VC\Auxiliary\Build\vcvarsall.bat'
                if (Test-Path $vcvarsall) {
                    Write-BuildLog 'Initializing MSVC environment via vcvarsall.bat...' -Level INFO
                    
                    # Execute vcvarsall and import environment variables
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    cmd /c "`"$vcvarsall`" x64 >nul 2>&1 && set" | Out-File $tempFile -Encoding ASCII
                    
                    Get-Content $tempFile | ForEach-Object {
                        if ($_ -match '^([^=]+)=(.*)$') {
                            $name = $matches[1]
                            $value = $matches[2]
                            Set-Item -Path "env:$name" -Value $value -ErrorAction SilentlyContinue
                        }
                    }
                    
                    Remove-Item $tempFile -ErrorAction SilentlyContinue
                    
                    # Verify cl.exe is now available
                    if (Get-Command cl -ErrorAction SilentlyContinue) {
                        $clVersion = (cl 2>&1 | Select-String 'Version').ToString()
                        Write-BuildLog "MSVC initialized successfully: $clVersion" -Level SUCCESS
                        return $true
                    }
                }
            }
        } catch {
            Write-BuildLog "vswhere.exe failed: $_" -Level DEBUG
        }
    }
    
    # Strategy 3: Check VCToolsInstallDir (set by setup-msbuild@v2 or Developer Command Prompt)
    if ($env:VCToolsInstallDir) {
        Write-BuildLog "Checking VCToolsInstallDir: $env:VCToolsInstallDir" -Level DEBUG
        $clPath = Join-Path $env:VCToolsInstallDir 'bin\Hostx64\x64\cl.exe'
        if (Test-Path $clPath) {
            $vcBinPath = Split-Path $clPath -Parent
            $env:PATH = "$vcBinPath;$env:PATH"
            Write-BuildLog 'Added VCToolsInstallDir to PATH' -Level SUCCESS
            return $true
        }
    }
    
    # Strategy 4: Extract path from MSBuild variable (set by setup-msbuild@v2)
    if ($env:MSBuild) {
        Write-BuildLog "Checking MSBuild path: $env:MSBuild" -Level DEBUG
        $msbuildDir = Split-Path $env:MSBuild -Parent
        $vsRoot = Split-Path (Split-Path (Split-Path $msbuildDir -Parent) -Parent) -Parent
        $vcvarsall = Join-Path $vsRoot 'VC\Auxiliary\Build\vcvarsall.bat'
        
        if (Test-Path $vcvarsall) {
            Write-BuildLog 'Found vcvarsall.bat via MSBuild path' -Level DEBUG
            
            # Execute vcvarsall (same as Strategy 2)
            $tempFile = [System.IO.Path]::GetTempFileName()
            cmd /c "`"$vcvarsall`" x64 >nul 2>&1 && set" | Out-File $tempFile -Encoding ASCII
            
            Get-Content $tempFile | ForEach-Object {
                if ($_ -match '^([^=]+)=(.*)$') {
                    Set-Item -Path "env:$($matches[1])" -Value $matches[2] -ErrorAction SilentlyContinue
                }
            }
            
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            
            if (Get-Command cl -ErrorAction SilentlyContinue) {
                Write-BuildLog 'MSVC initialized via MSBuild path' -Level SUCCESS
                return $true
            }
        }
    }
    
    # Strategy 5: Fallback to standard installation paths
    $standardPaths = @(
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Enterprise",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Professional",
        "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools"
    )
    
    foreach ($path in $standardPaths) {
        $vcvarsall = Join-Path $path 'VC\Auxiliary\Build\vcvarsall.bat'
        if (Test-Path $vcvarsall) {
            Write-BuildLog "Found Visual Studio at: $path" -Level DEBUG
            
            # Execute vcvarsall
            $tempFile = [System.IO.Path]::GetTempFileName()
            cmd /c "`"$vcvarsall`" x64 >nul 2>&1 && set" | Out-File $tempFile -Encoding ASCII
            
            Get-Content $tempFile | ForEach-Object {
                if ($_ -match '^([^=]+)=(.*)$') {
                    Set-Item -Path "env:$($matches[1])" -Value $matches[2] -ErrorAction SilentlyContinue
                }
            }
            
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            
            if (Get-Command cl -ErrorAction SilentlyContinue) {
                Write-BuildLog "MSVC initialized from: $path" -Level SUCCESS
                return $true
            }
        }
    }
    
    # All strategies failed
    Write-Host '::error::[Windows] [MSVC] Error: Visual Studio Build Tools not found'
    Write-Host '::error::Details: Required for C/C++ compilation on Windows'
    Write-Host "::error::Solution: Install Visual Studio 2022 with 'Desktop development with C++' workload"
    Write-BuildLog 'Searched locations:' -Level ERROR
    Write-BuildLog '  1. PATH (setup-msbuild@v2)' -Level ERROR
    Write-BuildLog '  2. vswhere.exe' -Level ERROR
    Write-BuildLog "  3. VCToolsInstallDir: $env:VCToolsInstallDir" -Level ERROR
    Write-BuildLog "  4. MSBuild: $env:MSBuild" -Level ERROR
    Write-BuildLog "  5. Standard paths: $($standardPaths -join ', ')" -Level ERROR
    
    return $false
}

function Find-NASM {
    Write-BuildLog 'Detecting NASM assembler...' -Level INFO
    
    # Check if nasm is in PATH
    $nasm = Get-Command nasm -ErrorAction SilentlyContinue
    if ($nasm) {
        $version = (nasm -v 2>&1 | Select-String 'version').ToString()
        Write-BuildLog "NASM found: $version" -Level SUCCESS
        return $nasm.Source
    }
    
    # Common installation paths
    $nasmPaths = @(
        "${env:ProgramFiles}\NASM\nasm.exe",
        "${env:ProgramFiles(x86)}\NASM\nasm.exe",
        'C:\nasm\nasm.exe'
    )
    
    foreach ($path in $nasmPaths) {
        if (Test-Path $path) {
            Write-BuildLog "NASM found at: $path" -Level SUCCESS
            return $path
        }
    }
    
    Write-Host '::error::[Windows] [NASM] Error: NASM not found in PATH'
    Write-Host '::error::Details: Required for assembly compilation'
    Write-Host "::error::Solution: Install NASM from https://www.nasm.us/ or run 'choco install nasm'"
    throw 'NASM assembler not found'
}

# ============================================================================
# Build Functions
# ============================================================================

function Invoke-Clean {
    param([string]$BuildDir)
    
    Write-BuildLog "Cleaning build directory: $BuildDir" -Level INFO
    
    if (Test-Path $BuildDir) {
        try {
            Remove-Item $BuildDir -Recurse -Force -ErrorAction Stop
            Write-BuildLog 'Build directory cleaned' -Level SUCCESS
        } catch {
            Write-BuildLog "Failed to clean build directory: $_" -Level WARNING
        }
    }
    
    # Create fresh build directory
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
    Write-BuildLog "Build directory created: $BuildDir" -Level SUCCESS
}

function Invoke-AssemblyCompilation {
    param(
        [string]$SourceDir,
        [string]$BuildDir,
        [string]$NasmPath
    )
    
    Write-SectionHeader 'Compiling Assembly Files'
    
    $asmFiles = @(
        @{Source = 'embedding_lib.asm'; Output = 'embedding_lib.obj' },
        @{Source = 'embedding_generator.asm'; Output = 'embedding_generator.obj' }
    )
    
    foreach ($file in $asmFiles) {
        $srcPath = Join-Path $SourceDir $file.Source
        $objPath = Join-Path $BuildDir $file.Output
        
        if (-not (Test-Path $srcPath)) {
            throw "Assembly source file not found: $srcPath"
        }
        
        Write-BuildLog "Compiling: $($file.Source) -> $($file.Output)" -Level INFO
        
        $nasmArgs = @(
            '-f', 'win64',
            $srcPath,
            '-o', $objPath
        )
        
        $startTime = Get-Date
        & $NasmPath $nasmArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "NASM compilation failed for $($file.Source) (exit code: $LASTEXITCODE)"
        }
        
        $duration = (Get-Date) - $startTime
        Write-BuildLog "Compiled $($file.Source) in $($duration.TotalSeconds)s" -Level SUCCESS
        
        # Verify output
        if (-not (Test-Path $objPath)) {
            throw "NASM output file not created: $objPath"
        }
        
        $size = (Get-Item $objPath).Length
        Write-BuildLog "Output: $objPath ($([math]::Round($size/1KB, 2)) KB)" -Level DEBUG
    }
}

function Invoke-CCompilation {
    param(
        [string]$SourceDir,
        [string]$IncludeDir,
        [string]$BuildDir
    )
    
    Write-SectionHeader 'Compiling C Sources'
    
    $cFiles = @('embedding_lib_c.c', 'onnx_embedding_loader.c')
    
    foreach ($file in $cFiles) {
        $srcPath = Join-Path $SourceDir $file
        
        # Skip onnx_embedding_loader.c if it doesn't exist (ONNX optional)
        if (-not (Test-Path $srcPath)) {
            if ($file -eq 'onnx_embedding_loader.c') {
                Write-BuildLog "Skipping optional $file (not found)" -Level WARNING
                continue
            }
            throw "C source file not found: $srcPath"
        }
        
        $objFile = [System.IO.Path]::ChangeExtension($file, '.obj')
        $objPath = Join-Path $BuildDir $objFile
        
        Write-BuildLog "Compiling: $file -> $objFile" -Level INFO
        
        # Check if ONNX Runtime is available
        $onnxInclude = Join-Path (Join-Path $RepoRoot 'bindings') 'onnxruntime\include'
        $useOnnx = Test-Path $onnxInclude
        
        $clArgs = @(
            '/c',           # Compile only
            '/O2',          # Optimize for speed
            '/W3',          # Warning level 3
            '/nologo',      # Suppress copyright message
            "/I$IncludeDir", # Include directory
            '/DFASTEMBED_BUILDING_LIB', # Define for building library (not importing)
            "/Fo:$objPath",  # Output object file
            $srcPath
        )
        
        # Add ONNX Runtime support if available
        if ($useOnnx -and $file -eq 'onnx_embedding_loader.c') {
            $clArgs += "/I$onnxInclude"
            $clArgs += '/DUSE_ONNX_RUNTIME'
        }
        
        $startTime = Get-Date
        cl @clArgs 2>&1 | ForEach-Object {
            if ($_ -match 'error') {
                Write-BuildLog $_ -Level ERROR
            } elseif ($_ -match 'warning') {
                Write-BuildLog $_ -Level WARNING
            }
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "C compilation failed for $file (exit code: $LASTEXITCODE)"
        }
        
        $duration = (Get-Date) - $startTime
        Write-BuildLog "Compiled $file in $($duration.TotalSeconds)s" -Level SUCCESS
        
        # Verify output
        if (-not (Test-Path $objPath)) {
            throw "Compiler output file not created: $objPath"
        }
        
        $size = (Get-Item $objPath).Length
        Write-BuildLog "Output: $objPath ($([math]::Round($size/1KB, 2)) KB)" -Level DEBUG
    }
}

function Invoke-Linking {
    param(
        [string]$BuildDir,
        [string]$OutputDll
    )
    
    Write-SectionHeader 'Linking DLL'
    
    # Get all object files
    $objFiles = Get-ChildItem -Path $BuildDir -Filter '*.obj' | Select-Object -ExpandProperty FullName
    
    if ($objFiles.Count -eq 0) {
        throw "No object files found in build directory: $BuildDir"
    }
    
    Write-BuildLog "Linking $($objFiles.Count) object files..." -Level INFO
    foreach ($obj in $objFiles) {
        Write-BuildLog "  - $(Split-Path $obj -Leaf)" -Level DEBUG
    }
    
    $linkArgs = @(
        '/DLL',                    # Create DLL
        '/NOLOGO',                 # Suppress copyright
        "/OUT:$OutputDll"          # Output file
    ) + $objFiles
    
    $startTime = Get-Date
    link @linkArgs 2>&1 | ForEach-Object {
        if ($_ -match 'error') {
            Write-BuildLog $_ -Level ERROR
        } elseif ($_ -match 'warning') {
            Write-BuildLog $_ -Level WARNING
        }
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Linking failed (exit code: $LASTEXITCODE)"
    }
    
    $duration = (Get-Date) - $startTime
    Write-BuildLog "Linking completed in $($duration.TotalSeconds)s" -Level SUCCESS
    
    # Verify output
    if (-not (Test-Path $OutputDll)) {
        throw "DLL not created: $OutputDll"
    }
    
    $size = (Get-Item $OutputDll).Length
    Write-BuildLog "Output DLL: $OutputDll ($([math]::Round($size/1KB, 2)) KB)" -Level SUCCESS
}

# ============================================================================
# Main Build Process
# ============================================================================

try {
    $buildStartTime = Get-Date
    
    Write-SectionHeader 'FastEmbed Windows Build (PowerShell)'
    Write-BuildLog "Build started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
    Write-BuildLog "PowerShell version: $($PSVersionTable.PSVersion)" -Level DEBUG
    Write-BuildLog "OS: $([Environment]::OSVersion.VersionString)" -Level DEBUG
    
    # Find repository root
    $repoRoot = Find-RepositoryRoot
    Write-BuildLog "Repository root: $repoRoot" -Level INFO
    
    # Define paths
    $sharedDir = Join-Path $repoRoot 'bindings\shared'
    $sourceDir = Join-Path $sharedDir 'src'
    $includeDir = Join-Path $sharedDir 'include'
    $buildDir = Join-Path $sharedDir 'build'
    $outputDll = Join-Path $buildDir 'fastembed_native.dll'
    
    # Validate directories
    if (-not (Test-Path $sourceDir)) {
        throw "Source directory not found: $sourceDir"
    }
    if (-not (Test-Path $includeDir)) {
        throw "Include directory not found: $includeDir"
    }
    
    Write-BuildLog "Source directory: $sourceDir" -Level DEBUG
    Write-BuildLog "Include directory: $includeDir" -Level DEBUG
    Write-BuildLog "Build directory: $buildDir" -Level DEBUG
    
    # Clean if requested
    if ($Clean) {
        Invoke-Clean -BuildDir $buildDir
    } elseif (-not (Test-Path $buildDir)) {
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
        Write-BuildLog 'Created build directory' -Level INFO
    }
    
    # Detect MSVC
    if (-not (Find-MSVC)) {
        Write-Host '::error::[Windows] [MSVC] Error: Visual Studio Build Tools not found'
        Write-Host '::error::Details: Required for native library compilation'
        Write-Host "::error::Solution: Install Visual Studio 2022 with 'Desktop development with C++' workload"
        throw 'Visual Studio Build Tools not found'
    }
    
    # Detect NASM
    $nasmPath = Find-NASM
    
    # Compile assembly files
    Invoke-AssemblyCompilation -SourceDir $sourceDir -BuildDir $buildDir -NasmPath $nasmPath
    
    # Compile C sources
    Invoke-CCompilation -SourceDir $sourceDir -IncludeDir $includeDir -BuildDir $buildDir
    
    # Link DLL
    Invoke-Linking -BuildDir $buildDir -OutputDll $outputDll
    
    # Copy DLL to lib directory (for C# and other bindings)
    $libDir = Join-Path $sharedDir 'lib'
    if (-not (Test-Path $libDir)) {
        New-Item -ItemType Directory -Path $libDir | Out-Null
        Write-BuildLog "Created lib directory: $libDir" -Level DEBUG
    }
    
    $finalDll = Join-Path $libDir 'fastembed_native.dll'
    Write-BuildLog "Copying DLL to lib directory..." -Level INFO
    Copy-Item -Path $outputDll -Destination $finalDll -Force
    Write-BuildLog "DLL copied to: $finalDll" -Level SUCCESS
    
    # Copy ONNX Runtime DLL if available
    $onnxDll = Join-Path (Join-Path $repoRoot 'bindings\onnxruntime\lib') 'onnxruntime.dll'
    if (Test-Path $onnxDll) {
        $onnxDest = Join-Path $libDir 'onnxruntime.dll'
        Copy-Item -Path $onnxDll -Destination $onnxDest -Force
        Write-BuildLog "ONNX Runtime DLL copied to: $onnxDest" -Level SUCCESS
    } else {
        Write-BuildLog "ONNX Runtime DLL not found, skipping copy" -Level WARNING
    }
    
    # Build summary
    $buildDuration = (Get-Date) - $buildStartTime
    Write-SectionHeader 'Build Completed Successfully'
    Write-BuildLog "Total build time: $($buildDuration.TotalSeconds)s" -Level SUCCESS
    Write-BuildLog "Build output: $outputDll" -Level SUCCESS
    Write-BuildLog "Final output: $finalDll" -Level SUCCESS
    Write-BuildLog "Size: $([math]::Round((Get-Item $outputDll).Length/1KB, 2)) KB" -Level SUCCESS
    
    exit 0
} catch {
    Write-Host '::error::[Windows] [Build] Error: Build failed'
    Write-Host "::error::Details: $_"
    Write-Host '::error::Solution: Check error details above and verify all dependencies are installed'
    Write-BuildLog "Stack trace: $($_.ScriptStackTrace)" -Level DEBUG
    exit 1
}

