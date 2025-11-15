# PowerShell script for Docker testing on Windows
param(
    [Parameter(Position = 0)]
    [ValidateSet('linux', 'python', 'shell', 'all', 'clean')]
    [string]$TestType = 'all'
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Set-Location $ProjectRoot

Write-Host '===================================' -ForegroundColor Cyan
Write-Host 'FastEmbed Docker Local Testing' -ForegroundColor Cyan
Write-Host '===================================' -ForegroundColor Cyan
Write-Host ''

function Write-Status {
    param(
        [string]$Status,
        [string]$Message
    )
    
    switch ($Status) {
        'info' {
            Write-Host "[INFO] $Message" -ForegroundColor Yellow 
        }
        'success' {
            Write-Host "[SUCCESS] $Message" -ForegroundColor Green 
        }
        'error' {
            Write-Host "[ERROR] $Message" -ForegroundColor Red 
        }
        'warn' {
            Write-Host "[WARN] $Message" -ForegroundColor Magenta 
        }
    }
}

# Detect Docker and Docker Compose
function Get-DockerComposeCommand {
    # Check if docker command exists (multiple methods)
    $dockerFound = $false
    $dockerCmd = $null
    
    # Method 1: Try Get-Command
    try {
        $dockerCmd = Get-Command docker -ErrorAction Stop
        $dockerFound = $true
    } catch {
        # Method 2: Try Get-Command with .exe extension
        try {
            $dockerCmd = Get-Command docker.exe -ErrorAction Stop
            $dockerFound = $true
        } catch {
            # Method 3: Try where.exe (Windows command)
            $whereResult = where.exe docker 2>&1
            if ($LASTEXITCODE -eq 0 -and $whereResult -notmatch 'INFO:') {
                $dockerFound = $true
                $dockerCmd = $whereResult
            } else {
                # Method 4: Check common Docker Desktop paths
                $dockerPaths = @(
                    "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe",
                    "${env:ProgramFiles(x86)}\Docker\Docker\resources\bin\docker.exe",
                    "$env:LOCALAPPDATA\Docker\resources\bin\docker.exe"
                )
                
                foreach ($path in $dockerPaths) {
                    if (Test-Path $path) {
                        $dockerFound = $true
                        $dockerCmd = $path
                        break
                    }
                }
            }
        }
    }
    
    if (-not $dockerFound) {
        Write-Status 'error' 'Docker is not found in PATH'
        Write-Status 'error' 'Please ensure Docker Desktop is installed and running'
        Write-Status 'info' 'If Docker Desktop is installed, try restarting PowerShell or your terminal'
        Write-Status 'info' 'Alternatively, you can test builds in GitHub Actions (push to test branch)'
        exit 1
    }
    
    # If Docker found via path, add it to PATH for this session
    if ($dockerCmd -is [string] -and $dockerCmd -match '\.exe$') {
        $dockerDir = Split-Path -Parent $dockerCmd
        if ($env:PATH -notlike "*$dockerDir*") {
            $env:PATH = "$dockerDir;$env:PATH"
            Write-Status 'info' "Added Docker to PATH: $dockerDir"
        }
        
        # Also add docker-credential-desktop if it exists in the same directory
        $credentialHelper = Join-Path $dockerDir 'docker-credential-desktop.exe'
        if (Test-Path $credentialHelper) {
            $credentialDir = Split-Path -Parent $credentialHelper
            if ($env:PATH -notlike "*$credentialDir*") {
                # Already added above, but ensure it's accessible
                Write-Status 'info' 'Docker credential helper available'
            }
        }
    }
    
    # Verify Docker is actually working (not just found)
    try {
        # Try direct execution first
        $dockerExe = if ($dockerCmd -is [string] -and $dockerCmd -match '\.exe$') {
            $dockerCmd
        } elseif ($dockerCmd -is [System.Management.Automation.CommandInfo]) {
            $dockerCmd.Source
        } else {
            'docker'
        }
        
        $null = & $dockerExe --version 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Docker is found but not responding'
            Write-Status 'error' 'Please ensure Docker Desktop is running'
            Write-Status 'info' 'Start Docker Desktop and try again'
            exit 1
        }
        
        # Check if Docker daemon is running
        $null = & $dockerExe info 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Docker is installed but daemon is not running'
            Write-Status 'error' 'Please start Docker Desktop'
            Write-Status 'info' 'Wait for Docker Desktop to fully start, then try again'
            exit 1
        }
    } catch {
        Write-Status 'error' 'Docker is found but cannot execute'
        Write-Status 'error' 'Please ensure Docker Desktop is running'
        exit 1
    }
    
    # Try new format first (docker compose - integrated in Docker CLI v2.0+)
    # Use the same dockerExe we verified works
    try {
        $composeTest = & $dockerExe compose version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status 'info' 'Found Docker Compose (integrated format: docker compose)'
            # Return object with both command string and docker executable path
            return @{
                Command   = 'docker compose'
                DockerExe = $dockerExe
            }
        }
    } catch {
        # Continue to check old format
    }
    
    # Try old format (docker-compose - standalone)
    # Check in same directory as docker.exe
    $dockerDir = Split-Path -Parent $dockerExe
    $dockerComposeExe = Join-Path $dockerDir 'docker-compose.exe'
    
    if (Test-Path $dockerComposeExe) {
        Write-Status 'info' 'Found Docker Compose (standalone: docker-compose)'
        return @{
            Command    = 'docker-compose'
            DockerExe  = $dockerExe
            ComposeExe = $dockerComposeExe
        }
    }
    
    # Try Get-Command for docker-compose
    try {
        $composeCmd = Get-Command docker-compose -ErrorAction Stop
        Write-Status 'info' 'Found Docker Compose (standalone: docker-compose)'
        return @{
            Command    = 'docker-compose'
            DockerExe  = $dockerExe
            ComposeExe = $composeCmd.Source
        }
    } catch {
        # Try docker-compose.exe
        try {
            $composeCmd = Get-Command docker-compose.exe -ErrorAction Stop
            Write-Status 'info' 'Found Docker Compose (standalone: docker-compose.exe)'
            return @{
                Command    = 'docker-compose'
                DockerExe  = $dockerExe
                ComposeExe = $composeCmd.Source
            }
        } catch {
            Write-Status 'error' 'Docker Compose is not available'
            Write-Status 'error' 'Docker was found, but Docker Compose could not be detected'
            Write-Status 'info' 'Tried: docker compose (integrated) and docker-compose (standalone)'
            Write-Status 'info' 'Please ensure Docker Desktop is fully installed and running'
            Write-Status 'info' 'You may need to restart Docker Desktop or your terminal'
            exit 1
        }
    }
}

# Get Docker Compose command and Docker executable path
$DockerComposeResult = Get-DockerComposeCommand
$DockerCompose = $DockerComposeResult.Command
$DockerExePath = $DockerComposeResult.DockerExe
Write-Status 'info' "Using: $DockerCompose"

# Function to execute docker compose commands
function Invoke-DockerCompose {
    param(
        [string[]]$Arguments
    )
    
    if ($DockerCompose -eq 'docker compose') {
        # Use integrated format: docker compose <args>
        & $DockerExePath compose $Arguments
    } else {
        # Use standalone format: docker-compose <args>
        if ($DockerComposeResult.ComposeExe) {
            & $DockerComposeResult.ComposeExe $Arguments
        } else {
            # Fallback to docker-compose in PATH
            & docker-compose $Arguments
        }
    }
}

# Pre-pull base images to avoid credential issues
function PrePullImages {
    Write-Status 'info' 'Pre-pulling base images...'
    try {
        & $DockerExePath pull ubuntu:24.04 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Status 'info' 'Base images ready'
        } else {
            Write-Status 'warn' 'Could not pre-pull images, will try during build'
        }
    } catch {
        Write-Status 'warn' 'Could not pre-pull images, will try during build'
    }
}

switch ($TestType) {
    'linux' {
        Write-Status 'info' 'Building Linux artifacts...'
        Invoke-DockerCompose -Arguments @('build', 'linux-build')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Docker build failed'
            exit 1
        }
        Invoke-DockerCompose -Arguments @('run', '--rm', 'linux-build')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Linux build failed'
            exit 1
        }
        Write-Status 'success' 'Linux build completed!'
    }
    
    'python' {
        Write-Status 'info' 'Building Python wheel...'
        Invoke-DockerCompose -Arguments @('build', 'python-build')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Docker build failed'
            exit 1
        }
        Invoke-DockerCompose -Arguments @('run', '--rm', 'python-build')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Python build failed'
            exit 1
        }
        Write-Status 'success' 'Python wheel build completed!'
    }
    
    'shell' {
        Write-Status 'info' 'Starting interactive shell...'
        Invoke-DockerCompose -Arguments @('build', 'linux-shell')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Docker build failed'
            exit 1
        }
        Invoke-DockerCompose -Arguments @('run', '--rm', 'linux-shell')
    }
    
    'all' {
        Write-Status 'info' 'Running all tests...'
        
        # Pre-pull images to avoid credential issues
        PrePullImages
        
        # Linux build
        Write-Status 'info' '1/2 - Building Linux artifacts...'
        Invoke-DockerCompose -Arguments @('build', 'linux-build')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Linux build: FAILED (Docker build error)'
            exit 1
        }
        
        Invoke-DockerCompose -Arguments @('run', '--rm', 'linux-build')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Linux build: FAILED (Build execution error)'
            exit 1
        }
        Write-Status 'success' 'Linux build: PASSED'
        
        # Python build
        Write-Status 'info' '2/2 - Building Python wheel...'
        Invoke-DockerCompose -Arguments @('build', 'python-build')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Python build: FAILED (Docker build error)'
            exit 1
        }
        
        Invoke-DockerCompose -Arguments @('run', '--rm', 'python-build')
        if ($LASTEXITCODE -ne 0) {
            Write-Status 'error' 'Python build: FAILED (Build execution error)'
            exit 1
        }
        Write-Status 'success' 'Python build: PASSED'
        
        Write-Status 'success' 'All tests passed!'
    }
    
    'clean' {
        Write-Status 'info' 'Cleaning Docker artifacts...'
        Invoke-DockerCompose -Arguments @('down', '-v')
        & $DockerExePath system prune -f
        Write-Status 'success' 'Cleanup completed!'
    }
}

