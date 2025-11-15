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
    }
}

switch ($TestType) {
    'linux' {
        Write-Status 'info' 'Building Linux artifacts...'
        docker-compose build linux-build
        docker-compose run --rm linux-build
        Write-Status 'success' 'Linux build completed!'
    }
    
    'python' {
        Write-Status 'info' 'Building Python wheel...'
        docker-compose build python-build
        docker-compose run --rm python-build
        Write-Status 'success' 'Python wheel build completed!'
    }
    
    'shell' {
        Write-Status 'info' 'Starting interactive shell...'
        docker-compose build linux-shell
        docker-compose run --rm linux-shell
    }
    
    'all' {
        Write-Status 'info' 'Running all tests...'
        
        # Linux build
        Write-Status 'info' '1/2 - Building Linux artifacts...'
        docker-compose build linux-build
        try {
            docker-compose run --rm linux-build
            Write-Status 'success' 'Linux build: PASSED'
        } catch {
            Write-Status 'error' 'Linux build: FAILED'
            exit 1
        }
        
        # Python build
        Write-Status 'info' '2/2 - Building Python wheel...'
        docker-compose build python-build
        try {
            docker-compose run --rm python-build
            Write-Status 'success' 'Python build: PASSED'
        } catch {
            Write-Status 'error' 'Python build: FAILED'
            exit 1
        }
        
        Write-Status 'success' 'All tests passed!'
    }
    
    'clean' {
        Write-Status 'info' 'Cleaning Docker artifacts...'
        docker-compose down -v
        docker system prune -f
        Write-Status 'success' 'Cleanup completed!'
    }
}

