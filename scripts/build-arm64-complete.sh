#!/bin/bash

# Complete ARM64 Build Script for Docker Dev-Box
# Addresses DNS resolution issues and ensures successful ARM64 builds

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🏗️  Docker Dev-Box ARM64 Complete Builder${NC}"
    echo "=============================================="
    echo
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header

# Configuration
TAG="arm64-complete"
PLATFORM="linux/arm64"
HOST_DOCKER_GID=$(getent group docker 2>/dev/null | cut -d: -f3 || echo 988)

print_info "Building ARM64 Docker image with tag: $TAG"
print_info "Target platform: $PLATFORM"
print_info "Host Docker GID: $HOST_DOCKER_GID"

# Check prerequisites
print_info "Checking prerequisites..."

# Test network connectivity
print_info "Testing network connectivity..."
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    print_error "No internet connectivity available"
    exit 1
fi

if ! nslookup ports.ubuntu.com >/dev/null 2>&1; then
    print_error "DNS resolution failed for ports.ubuntu.com"
    exit 1
fi

print_success "Network connectivity verified"

# Ensure buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    print_error "Docker buildx is not available"
    exit 1
fi

# Create/ensure builder exists
print_info "Setting up multi-architecture builder..."
docker buildx create --name arm64-builder --use --driver docker-container || true
docker buildx inspect --bootstrap

print_success "Builder ready"

# Build the image with enhanced network configuration
print_info "Starting ARM64 build process..."
print_info "This may take 15-30 minutes depending on your system..."

# Build with explicit DNS configuration and network settings
docker buildx build \
    --platform "$PLATFORM" \
    --tag "wn1980/dev-box:arm64" \
    --build-arg HOST_DOCKER_GID="$HOST_DOCKER_GID" \
    --file Dockerfile.arm64-enhanced \
    --network host \
    --progress plain \
    --load \
    . 2>&1 | tee build-arm64.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    print_success "ARM64 build completed successfully!"
    print_info "Image tag: docker-dev-box-dev-box:$TAG"
    
    # Verify the built image
    print_info "Verifying built image..."
    docker image inspect "docker-dev-box-dev-box:$TAG" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Image verification successful"
        
        # Show image details
        print_info "Image details:"
        docker image ls "docker-dev-box-dev-box:$TAG"
        
        # Show architecture
        print_info "Architecture details:"
        docker image inspect "docker-dev-box-dev-box:$TAG" --format '{{.Architecture}}'
        
        print_success "ARM64 Docker image build complete!"
        print_info "You can now run the image with:"
        echo "docker run -d --name dev-box-arm64 -p 2222:22 -p 8443:8443 docker-dev-box-dev-box:$TAG"
        
    else
        print_error "Image verification failed"
        exit 1
    fi
else
    print_error "Build failed. Check build-arm64.log for details"
    exit 1
fi
