#!/bin/bash
# Quick Docker testing script for FastEmbed builds

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "==================================="
echo "FastEmbed Docker Local Testing"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    
    if [ "$status" = "info" ]; then
        echo -e "${YELLOW}[INFO]${NC} $message"
    elif [ "$status" = "success" ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $message"
    elif [ "$status" = "error" ]; then
        echo -e "${RED}[ERROR]${NC} $message"
    fi
}

# Detect Docker and Docker Compose
detect_docker_compose() {
    # Check if docker command exists
    if ! command -v docker &> /dev/null; then
        print_status "error" "Docker is not installed or not in PATH"
        print_status "error" "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        print_status "info" "Alternatively, you can test builds in GitHub Actions (push to test branch)"
        exit 1
    fi
    
    # Try new format first (docker compose - integrated in Docker CLI v2.0+)
    if docker compose version &> /dev/null; then
        echo "docker compose"
        return 0
    fi
    
    # Try old format (docker-compose - standalone)
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
        return 0
    fi
    
    print_status "error" "Docker Compose is not available"
    print_status "error" "Please ensure Docker Desktop is installed and running"
    print_status "info" "Docker Desktop includes Docker Compose"
    exit 1
}

# Get Docker Compose command
DOCKER_COMPOSE=$(detect_docker_compose)
print_status "info" "Using: $DOCKER_COMPOSE"

# Parse command line arguments
TEST_TYPE=${1:-"all"}

case $TEST_TYPE in
    "linux")
        print_status "info" "Building Linux artifacts..."
        $DOCKER_COMPOSE build linux-build
        $DOCKER_COMPOSE run --rm linux-build
        print_status "success" "Linux build completed!"
        ;;
    
    "python")
        print_status "info" "Building Python wheel..."
        $DOCKER_COMPOSE build python-build
        $DOCKER_COMPOSE run --rm python-build
        print_status "success" "Python wheel build completed!"
        ;;
    
    "shell")
        print_status "info" "Starting interactive shell..."
        $DOCKER_COMPOSE build linux-shell
        $DOCKER_COMPOSE run --rm linux-shell
        ;;
    
    "all")
        print_status "info" "Running all tests..."
        
        # Linux build
        print_status "info" "1/2 - Building Linux artifacts..."
        $DOCKER_COMPOSE build linux-build
        if $DOCKER_COMPOSE run --rm linux-build; then
            print_status "success" "Linux build: PASSED"
        else
            print_status "error" "Linux build: FAILED"
            exit 1
        fi
        
        # Python build
        print_status "info" "2/2 - Building Python wheel..."
        $DOCKER_COMPOSE build python-build
        if $DOCKER_COMPOSE run --rm python-build; then
            print_status "success" "Python build: PASSED"
        else
            print_status "error" "Python build: FAILED"
            exit 1
        fi
        
        print_status "success" "All tests passed!"
        ;;
    
    "clean")
        print_status "info" "Cleaning Docker artifacts..."
        $DOCKER_COMPOSE down -v
        docker system prune -f
        print_status "success" "Cleanup completed!"
        ;;
    
    *)
        echo "Usage: $0 {linux|python|shell|all|clean}"
        echo ""
        echo "  linux   - Test Linux build only"
        echo "  python  - Test Python wheel build only"
        echo "  shell   - Start interactive shell for debugging"
        echo "  all     - Run all tests (default)"
        echo "  clean   - Clean Docker artifacts"
        exit 1
        ;;
esac

