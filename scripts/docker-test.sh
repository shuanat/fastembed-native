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

# Parse command line arguments
TEST_TYPE=${1:-"all"}

case $TEST_TYPE in
    "linux")
        print_status "info" "Building Linux artifacts..."
        docker-compose build linux-build
        docker-compose run --rm linux-build
        print_status "success" "Linux build completed!"
        ;;
    
    "python")
        print_status "info" "Building Python wheel..."
        docker-compose build python-build
        docker-compose run --rm python-build
        print_status "success" "Python wheel build completed!"
        ;;
    
    "shell")
        print_status "info" "Starting interactive shell..."
        docker-compose build linux-shell
        docker-compose run --rm linux-shell
        ;;
    
    "all")
        print_status "info" "Running all tests..."
        
        # Linux build
        print_status "info" "1/2 - Building Linux artifacts..."
        docker-compose build linux-build
        if docker-compose run --rm linux-build; then
            print_status "success" "Linux build: PASSED"
        else
            print_status "error" "Linux build: FAILED"
            exit 1
        fi
        
        # Python build
        print_status "info" "2/2 - Building Python wheel..."
        docker-compose build python-build
        if docker-compose run --rm python-build; then
            print_status "success" "Python build: PASSED"
        else
            print_status "error" "Python build: FAILED"
            exit 1
        fi
        
        print_status "success" "All tests passed!"
        ;;
    
    "clean")
        print_status "info" "Cleaning Docker artifacts..."
        docker-compose down -v
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

