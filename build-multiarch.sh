#!/bin/bash

# Multi-Architecture Build Script for Docker Dev-Box
# Supports building for AMD64, ARM64, or both architectures

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
    echo -e "${BLUE}🏗️  Docker Dev-Box Multi-Architecture Builder${NC}"
    echo "============================================="
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

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --platform PLATFORM    Build for specific platform(s)"
    echo "                         Options: amd64, arm64, linux/amd64, linux/arm64, all"
    echo "                         Default: current platform"
    echo "  --push                 Push to registry after build"
    echo "  --tag TAG              Custom tag for the image (default: latest)"
    echo "  --registry REGISTRY    Registry to push to (default: none)"
    echo "  --dry-run              Show commands without executing"
    echo "  --help                 Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Build for current platform"
    echo "  $0 --platform amd64                  # Build for AMD64 only"
    echo "  $0 --platform arm64                  # Build for ARM64 only"
    echo "  $0 --platform all                    # Build for both AMD64 and ARM64"
    echo "  $0 --platform all --push             # Build and push both architectures"
    echo "  $0 --platform arm64 --tag v1.0       # Build ARM64 with custom tag"
}

# Default values
PLATFORM=""
PUSH=false
TAG="latest"
REGISTRY=""
DRY_RUN=false
HOST_DOCKER_GID=$(getent group docker 2>/dev/null | cut -d: -f3 || echo 988)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
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

# Convert platform aliases
case "$PLATFORM" in
    "amd64")
        PLATFORM="linux/amd64"
        ;;
    "arm64")
        PLATFORM="linux/arm64"
        ;;
    "all"|"both")
        PLATFORM="linux/amd64,linux/arm64"
        ;;
    "")
        # Detect current platform
        CURRENT_ARCH=$(uname -m)
        case "$CURRENT_ARCH" in
            x86_64)
                PLATFORM="linux/amd64"
                ;;
            aarch64|arm64)
                PLATFORM="linux/arm64"
                ;;
            *)
                print_error "Unsupported architecture: $CURRENT_ARCH"
                exit 1
                ;;
        esac
        ;;
esac

# Determine image name
if [ -n "$REGISTRY" ]; then
    # If registry contains a slash, treat it as the full image name base
    if [[ "$REGISTRY" == */* ]]; then
        IMAGE_NAME="$REGISTRY:$TAG"
    else
        IMAGE_NAME="$REGISTRY/dev-box:$TAG"
    fi
else
    IMAGE_NAME="dev-box:$TAG"
fi

print_header

print_info "Configuration:"
echo "  Platform(s): $PLATFORM"
echo "  Image name:  $IMAGE_NAME"
echo "  Push:        $PUSH"
echo "  Docker GID:  $HOST_DOCKER_GID"
echo "  Dry run:     $DRY_RUN"
echo

# Check if buildx is available for multi-platform builds
if [[ "$PLATFORM" == *","* ]]; then
    if ! docker buildx version >/dev/null 2>&1; then
        print_error "Docker Buildx is required for multi-platform builds"
        print_info "Please install Docker Buildx or build for a single platform"
        exit 1
    fi
    
    # Create/use buildx builder
    BUILDER_NAME="multiarch-builder"
    if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
        print_info "Creating buildx builder: $BUILDER_NAME"
        if [ "$DRY_RUN" = false ]; then
            docker buildx create --name "$BUILDER_NAME" --use --platform linux/amd64,linux/arm64
        else
            echo "DRY RUN: docker buildx create --name $BUILDER_NAME --use --platform linux/amd64,linux/arm64"
        fi
    else
        print_info "Using existing buildx builder: $BUILDER_NAME"
        if [ "$DRY_RUN" = false ]; then
            docker buildx use "$BUILDER_NAME"
        else
            echo "DRY RUN: docker buildx use $BUILDER_NAME"
        fi
    fi
fi

# Build command
if [[ "$PLATFORM" == *","* ]]; then
    # Multi-platform build with buildx
    BUILD_CMD="docker buildx build"
    BUILD_CMD="$BUILD_CMD --platform $PLATFORM"
    BUILD_CMD="$BUILD_CMD --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID"
    BUILD_CMD="$BUILD_CMD -t $IMAGE_NAME"
    if [ "$PUSH" = true ]; then
        BUILD_CMD="$BUILD_CMD --push"
    else
        BUILD_CMD="$BUILD_CMD --load"
        print_warning "Multi-platform images cannot be loaded to local Docker"
        print_warning "Use --push to push to a registry, or build single platform"
    fi
    BUILD_CMD="$BUILD_CMD ."
else
    # Single platform build
    BUILD_CMD="docker build"
    BUILD_CMD="$BUILD_CMD --platform $PLATFORM"
    BUILD_CMD="$BUILD_CMD --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID"
    BUILD_CMD="$BUILD_CMD -t $IMAGE_NAME"
    BUILD_CMD="$BUILD_CMD ."
fi

print_info "Build command:"
echo "  $BUILD_CMD"
echo

if [ "$DRY_RUN" = true ]; then
    print_warning "DRY RUN - Not executing build command"
    exit 0
fi

# Execute build
print_info "Starting build..."
if eval "$BUILD_CMD"; then
    print_success "Build completed successfully!"
else
    print_error "Build failed!"
    exit 1
fi

# Push single-platform image if requested and not already pushed
if [ "$PUSH" = true ] && [[ "$PLATFORM" != *","* ]]; then
    print_info "Pushing image to registry..."
    if docker push "$IMAGE_NAME"; then
        print_success "Image pushed successfully!"
    else
        print_error "Push failed!"
        exit 1
    fi
fi

print_success "All operations completed successfully!"

# Show usage instructions
echo
print_info "Usage instructions:"
if [[ "$PLATFORM" == *","* ]]; then
    echo "  Multi-platform image built. Use with:"
    echo "  docker run --platform linux/amd64 $IMAGE_NAME  # For AMD64"
    echo "  docker run --platform linux/arm64 $IMAGE_NAME  # For ARM64"
else
    echo "  Single-platform image built for: $PLATFORM"
    echo "  docker run $IMAGE_NAME"
fi

if [ "$PUSH" = false ] && [[ "$PLATFORM" != *","* ]]; then
    echo
    print_info "Image available locally as: $IMAGE_NAME"
    echo "  Use 'docker images' to see all built images"
fi
