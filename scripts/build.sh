#!/bin/bash

# Build script for User Management Service
# Usage: ./scripts/build.sh [OPTIONS]
#   -c, --clean     Clean build (mvn clean)
#   -d, --docker    Build Docker image
#   -t, --test      Run tests before build
#   -h, --help      Show help

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="user-management-service"
DOCKER_IMAGE="visionboard/${PROJECT_NAME}"
VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

# Default options
CLEAN=false
DOCKER=false
TEST=false

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show help
show_help() {
    cat << EOF
Build script for User Management Service

Usage: ./scripts/build.sh [OPTIONS]

OPTIONS:
    -c, --clean     Clean build (mvn clean)
    -d, --docker    Build Docker image
    -t, --test      Run tests before build
    -h, --help      Show this help message

EXAMPLES:
    ./scripts/build.sh                  # Basic build
    ./scripts/build.sh -c -t -d         # Clean build with tests and Docker image
    ./scripts/build.sh --docker         # Build with Docker image

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -d|--docker)
            DOCKER=true
            shift
            ;;
        -t|--test)
            TEST=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

print_status "Building ${PROJECT_NAME} version ${VERSION}"

# Clean build if requested
if [[ "$CLEAN" == true ]]; then
    print_status "Cleaning previous builds..."
    mvn clean
fi

# Run tests if requested
if [[ "$TEST" == true ]]; then
    print_status "Running tests..."
    mvn test
fi

# Build the application
print_status "Building application..."
mvn package -DskipTests=${TEST}

# Verify JAR was created
if [[ ! -f "target/${PROJECT_NAME}.jar" ]]; then
    print_error "Build failed - JAR file not found"
    exit 1
fi

print_status "Build completed successfully"
print_status "JAR location: target/${PROJECT_NAME}.jar"

# Build Docker image if requested
if [[ "$DOCKER" == true ]]; then
    print_status "Building Docker image..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    
    # Build Docker image
    docker build -t "${DOCKER_IMAGE}:${VERSION}" -t "${DOCKER_IMAGE}:latest" .
    
    print_status "Docker image built successfully"
    print_status "Image tags:"
    print_status "  - ${DOCKER_IMAGE}:${VERSION}"
    print_status "  - ${DOCKER_IMAGE}:latest"
    
    # Show image size
    IMAGE_SIZE=$(docker images "${DOCKER_IMAGE}:latest" --format "table {{.Size}}" | tail -n +2)
    print_status "Image size: ${IMAGE_SIZE}"
fi

print_status "Build process completed!"

# Show next steps
echo
print_status "Next steps:"
echo "  - Run locally: mvn spring-boot:run"
echo "  - Run with Docker: docker-compose up"
echo "  - Run tests: ./scripts/test.sh"
echo "  - Deploy: ./scripts/deploy.sh"