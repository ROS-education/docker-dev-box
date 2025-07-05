#!/bin/bash

# Multi-Architecture Build Script for Docker Dev-Box
# Supports building for AMD64, ARM64, or both architectures

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

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
REGISTRY="wn1980"
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
        # Use architecture-specific tags for multi-platform builds
        if [[ "$PLATFORM" == *","* ]]; then
            # Multi-platform build - will create separate arch tags
            IMAGE_NAME="$REGISTRY/dev-box"
        else
            # Single platform - determine arch-specific tag
            case "$PLATFORM" in
                "linux/amd64")
                    IMAGE_NAME="$REGISTRY/dev-box:amd64"
                    ;;
                "linux/arm64")
                    IMAGE_NAME="$REGISTRY/dev-box:arm64"
                    ;;
                *)
                    IMAGE_NAME="$REGISTRY/dev-box:$TAG"
                    ;;
            esac
        fi
    fi
else
    IMAGE_NAME="dev-box:$TAG"
fi

print_header

print_info "Configuration:"
echo "  Platform(s): $PLATFORM"
if [[ "$PLATFORM" == *","* ]]; then
    echo "  Image base:  $IMAGE_NAME"
    echo "  Will create: ${IMAGE_NAME}:amd64 and ${IMAGE_NAME}:arm64"
else
    echo "  Image name:  $IMAGE_NAME"
fi
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
    if [ "$PUSH" = true ]; then
        # Build and push multi-platform manifest with arch-specific tags
        BUILD_CMD="docker buildx build"
        BUILD_CMD="$BUILD_CMD --platform $PLATFORM"
        BUILD_CMD="$BUILD_CMD --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID"
        BUILD_CMD="$BUILD_CMD -t ${IMAGE_NAME}:amd64 -t ${IMAGE_NAME}:arm64"
        BUILD_CMD="$BUILD_CMD --push"
        BUILD_CMD="$BUILD_CMD ."
    else
        # Build each platform separately for local use with arch-specific tags
        print_info "Building each platform separately for local Docker with arch-specific tags"
        BUILD_PLATFORMS=(${PLATFORM//,/ })
        MULTI_PLATFORM_BUILD=true
    fi
else
    # Single platform build
    BUILD_CMD="docker build"
    BUILD_CMD="$BUILD_CMD --platform $PLATFORM"
    BUILD_CMD="$BUILD_CMD --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID"
    BUILD_CMD="$BUILD_CMD -t $IMAGE_NAME"
    BUILD_CMD="$BUILD_CMD ."
fi

print_info "Build command:"
if [ -n "${MULTI_PLATFORM_BUILD:-}" ]; then
    echo "  Building multiple platforms separately with arch-specific tags:"
    for platform in "${BUILD_PLATFORMS[@]}"; do
        # Extract architecture from platform (linux/amd64 -> amd64)
        arch_name="${platform#*/}"
        echo "    docker buildx build --platform $platform --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID -t ${IMAGE_NAME}:${arch_name} --load ."
    done
else
    echo "  $BUILD_CMD"
fi
echo

if [ "$DRY_RUN" = true ]; then
    print_warning "DRY RUN - Not executing build command"
    exit 0
fi

# Execute build
print_info "Starting build..."
if [ -n "${MULTI_PLATFORM_BUILD:-}" ]; then
    # Build each platform separately with arch-specific tags
    for platform in "${BUILD_PLATFORMS[@]}"; do
        # Extract architecture from platform (linux/amd64 -> amd64)
        arch_name="${platform#*/}"
        platform_tag="${IMAGE_NAME}:${arch_name}"
        print_info "Building for platform: $platform"
        build_cmd="docker buildx build --platform $platform --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID -t $platform_tag --load ."
        if eval "$build_cmd"; then
            print_success "Build completed for $platform: $platform_tag"
        else
            print_error "Build failed for platform: $platform"
            exit 1
        fi
    done
    
    # Create additional tags if needed
    print_info "Images created with arch-specific tags:"
    print_success "AMD64: ${IMAGE_NAME}:amd64"
    print_success "ARM64: ${IMAGE_NAME}:arm64"
    
else
    # Single build command
    if eval "$BUILD_CMD"; then
        print_success "Build completed successfully!"
    else
        print_error "Build failed!"
        exit 1
    fi
fi

# Push images if requested and not already pushed
if [ "$PUSH" = true ]; then
    if [ -n "${MULTI_PLATFORM_BUILD:-}" ]; then
        # Push both arch-specific images
        print_info "Pushing arch-specific images to registry..."
        for platform in "${BUILD_PLATFORMS[@]}"; do
            arch_name="${platform#*/}"
            platform_tag="${IMAGE_NAME}:${arch_name}"
            print_info "Pushing $platform_tag..."
            if docker push "$platform_tag"; then
                print_success "Pushed $platform_tag successfully!"
            else
                print_error "Push failed for $platform_tag!"
                exit 1
            fi
        done
    elif [[ "$PLATFORM" != *","* ]]; then
        # Push single-platform image
        print_info "Pushing image to registry..."
        if docker push "$IMAGE_NAME"; then
            print_success "Image pushed successfully!"
        else
            print_error "Push failed!"
            exit 1
        fi
    fi
fi

print_success "All operations completed successfully!"

# Show usage instructions
echo
print_info "Usage instructions:"
if [ -n "${MULTI_PLATFORM_BUILD:-}" ]; then
    echo "  Multi-platform images built with arch-specific tags:"
    echo "  docker run ${IMAGE_NAME}:amd64                     # For AMD64"
    echo "  docker run ${IMAGE_NAME}:arm64                     # For ARM64"
elif [[ "$PLATFORM" == *","* ]]; then
    echo "  Multi-platform manifest pushed to registry:"
    echo "  docker run --platform linux/amd64 ${IMAGE_NAME}:amd64  # For AMD64"
    echo "  docker run --platform linux/arm64 ${IMAGE_NAME}:arm64  # For ARM64"
else
    echo "  Single-platform image built for: $PLATFORM"
    case "$PLATFORM" in
        "linux/amd64")
            echo "  docker run ${IMAGE_NAME}                           # AMD64 image"
            ;;
        "linux/arm64")
            echo "  docker run ${IMAGE_NAME}                           # ARM64 image"
            ;;
        *)
            echo "  docker run $IMAGE_NAME"
            ;;
    esac
fi

if [ "$PUSH" = false ]; then
    echo
    if [ -n "${MULTI_PLATFORM_BUILD:-}" ]; then
        print_info "Images available locally as:"
        echo "  ${IMAGE_NAME}:amd64"
        echo "  ${IMAGE_NAME}:arm64"
    else
        print_info "Image available locally as: $IMAGE_NAME"
    fi
    echo "  Use 'docker images' to see all built images"
fi
