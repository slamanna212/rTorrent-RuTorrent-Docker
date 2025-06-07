#!/bin/bash

# rTorrent-ruTorrent Docker Build Script
# This script provides various build options for the Docker container

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
BUILD_TYPE="local"
PLATFORM=""
PUSH=false
LOAD=true
TAG="rtorrent-rutorrent:local"
CACHE=true

# Function to display usage
usage() {
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -t, --type TYPE         Build type: local, multi-platform, or all (default: local)"
    echo "  -p, --platform PLATFORM Specific platform to build (e.g., linux/amd64)"
    echo "  --push                  Push image to registry"
    echo "  --no-cache              Disable build cache"
    echo "  --tag TAG               Custom tag for the image (default: rtorrent-rutorrent:local)"
    echo "  -h, --help              Display this help message"
    echo ""
    echo -e "${YELLOW}Build Types:${NC}"
    echo "  local                   Build for local platform only (default)"
    echo "  multi-platform          Build for all supported platforms"
    echo "  all                     Build and export to docker for all platforms"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0                      # Build for local platform"
    echo "  $0 --type multi-platform --push  # Build multi-platform and push"
    echo "  $0 --platform linux/arm64        # Build for ARM64 only"
    echo "  $0 --tag my-rtorrent:v1.0        # Build with custom tag"
}

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker buildx version &> /dev/null; then
        print_error "Docker Buildx is not available"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Function to setup buildx
setup_buildx() {
    print_status "Setting up Docker Buildx..."
    
    # Create a new builder instance if it doesn't exist
    if ! docker buildx inspect rtorrent-builder &> /dev/null; then
        print_status "Creating new buildx builder instance..."
        docker buildx create --name rtorrent-builder --use
    else
        print_status "Using existing buildx builder instance..."
        docker buildx use rtorrent-builder
    fi
    
    # Bootstrap the builder
    docker buildx inspect --bootstrap
}

# Function to build the image
build_image() {
    local bake_target=""
    local bake_args=""
    
    print_status "Starting Docker build..."
    
    case $BUILD_TYPE in
        "local")
            bake_target="image-local"
            if [ "$LOAD" = true ]; then
                bake_args="--load"
            fi
            ;;
        "multi-platform")
            bake_target="image-all"
            if [ "$PUSH" = true ]; then
                bake_args="--push"
            fi
            ;;
        "all")
            bake_target="image-all"
            bake_args="--load"
            ;;
    esac
    
    # Build cache arguments
    if [ "$CACHE" = false ]; then
        bake_args="$bake_args --no-cache"
    fi
    
    # Platform specific build
    if [ -n "$PLATFORM" ]; then
        bake_args="$bake_args --set *.platform=$PLATFORM"
    fi
    
    # Custom tag
    if [ "$TAG" != "rtorrent-rutorrent:local" ]; then
        bake_args="$bake_args --set *.tag=$TAG"
    fi
    
    print_status "Build command: docker buildx bake $bake_target $bake_args"
    docker buildx bake $bake_target $bake_args
    
    print_status "Build completed successfully!"
}

# Function to run basic tests
run_tests() {
    if [ "$BUILD_TYPE" = "local" ] && [ "$LOAD" = true ]; then
        print_status "Running basic container tests..."
        
        # Create temporary directories for testing
        mkdir -p /tmp/rtorrent-test/{data,downloads,passwd}
        
        # Run container in background
        docker run -d --name rtorrent-test \
            -e PUID=1000 -e PGID=1000 \
            -v /tmp/rtorrent-test/data:/data \
            -v /tmp/rtorrent-test/downloads:/downloads \
            -v /tmp/rtorrent-test/passwd:/passwd \
            -p 8080:8080 -p 8000:8000 \
            "$TAG" || {
                print_error "Failed to start test container"
                return 1
            }
        
        # Wait for container to start
        sleep 10
        
        # Check if container is running
        if docker ps | grep -q rtorrent-test; then
            print_status "Container is running successfully"
        else
            print_error "Container failed to start properly"
            docker logs rtorrent-test
            docker rm -f rtorrent-test 2>/dev/null || true
            rm -rf /tmp/rtorrent-test
            return 1
        fi
        
        # Basic health check
        if curl -f -s http://localhost:8080 > /dev/null; then
            print_status "Web interface is accessible"
        else
            print_warning "Web interface health check failed (this might be normal during initial startup)"
        fi
        
        # Cleanup
        docker stop rtorrent-test
        docker rm rtorrent-test
        rm -rf /tmp/rtorrent-test
        
        print_status "Tests completed"
    else
        print_status "Skipping tests for non-local build"
    fi
}

# Function to display build information
show_build_info() {
    print_status "Build Information:"
    echo "  Build Type: $BUILD_TYPE"
    echo "  Platform: ${PLATFORM:-'default'}"
    echo "  Tag: $TAG"
    echo "  Push: $PUSH"
    echo "  Cache: $CACHE"
    echo "  Load: $LOAD"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            LOAD=false
            shift
            ;;
        --no-cache)
            CACHE=false
            shift
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate build type
case $BUILD_TYPE in
    "local"|"multi-platform"|"all")
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE"
        usage
        exit 1
        ;;
esac

# Main execution
main() {
    print_status "rTorrent-ruTorrent Docker Build Script"
    echo ""
    
    show_build_info
    echo ""
    
    check_prerequisites
    setup_buildx
    build_image
    run_tests
    
    print_status "All operations completed successfully!"
    
    if [ "$BUILD_TYPE" = "local" ] && [ "$LOAD" = true ]; then
        echo ""
        print_status "To run the container:"
        echo "  docker run -d --name rtorrent-rutorrent \\"
        echo "    -e PUID=1000 -e PGID=1000 \\"
        echo "    -v ./data:/data \\"
        echo "    -v ./downloads:/downloads \\"
        echo "    -v ./passwd:/passwd \\"
        echo "    -p 8080:8080 -p 8000:8000 \\"
        echo "    $TAG"
    fi
}

# Run main function
main "$@" 