#!/bin/bash

# Script to push multi-architecture dev-box images and create manifest
# This script handles pushing and creating multi-arch manifests for wn1980/dev-box

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Multi-Arch Image Push & Manifest${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if user is logged in to Docker Hub
check_docker_login() {
    if ! docker info | grep -q "Username:"; then
        print_warning "You may not be logged in to Docker Hub"
        print_info "Run 'docker login' to authenticate before pushing"
        echo
    fi
}

# Function to push image
push_image() {
    local image_tag="$1"
    
    print_info "Pushing $image_tag..."
    
    if docker push "$image_tag"; then
        print_success "Successfully pushed: $image_tag"
        return 0
    else
        print_error "Failed to push: $image_tag"
        return 1
    fi
}

# Function to create and push manifest
create_manifest() {
    local manifest_tag="$1"
    local amd64_tag="$2"
    local arm64_tag="$3"
    
    print_info "Creating multi-arch manifest: $manifest_tag"
    
    # Remove existing manifest if it exists
    docker manifest rm "$manifest_tag" 2>/dev/null || true
    
    if docker manifest create "$manifest_tag" "$amd64_tag" "$arm64_tag"; then
        print_success "Created manifest: $manifest_tag"
        
        print_info "Annotating manifest for architectures..."
        docker manifest annotate "$manifest_tag" "$amd64_tag" --arch amd64
        docker manifest annotate "$manifest_tag" "$arm64_tag" --arch arm64
        
        print_info "Pushing manifest: $manifest_tag"
        if docker manifest push "$manifest_tag"; then
            print_success "Successfully pushed manifest: $manifest_tag"
            return 0
        else
            print_error "Failed to push manifest: $manifest_tag"
            return 1
        fi
    else
        print_error "Failed to create manifest: $manifest_tag"
        return 1
    fi
}

# Main execution
main() {
    print_header
    
    # Define image tags
    local AMD64_TAG="wn1980/dev-box:amd64"
    local ARM64_TAG="wn1980/dev-box:arm64"
    local LATEST_TAG="wn1980/dev-box:latest"
    
    print_info "Current wn1980/dev-box images:"
    docker images | grep "wn1980/dev-box" || print_warning "No wn1980/dev-box images found"
    echo
    
    # Check Docker login
    check_docker_login
    
    local success_count=0
    local total_operations=0
    
    # Push individual architecture images
    print_info "Pushing architecture-specific images..."
    echo
    
    ((total_operations++))
    if push_image "$AMD64_TAG"; then
        ((success_count++))
    fi
    echo
    
    ((total_operations++))
    if push_image "$ARM64_TAG"; then
        ((success_count++))
    fi
    echo
    
    # Create and push multi-arch manifest
    print_info "Creating multi-architecture manifest..."
    echo
    
    ((total_operations++))
    if create_manifest "$LATEST_TAG" "$AMD64_TAG" "$ARM64_TAG"; then
        ((success_count++))
    fi
    echo
    
    # Summary
    print_header
    print_info "Push Summary:"
    echo "  Total operations: $total_operations"
    echo "  Successful: $success_count"
    echo "  Failed: $((total_operations - success_count))"
    echo
    
    if [ $success_count -eq $total_operations ]; then
        print_success "All operations completed successfully!"
        echo
        print_info "Your multi-arch image is now available:"
        echo "  docker pull wn1980/dev-box:latest    # Multi-arch (auto-selects)"
        echo "  docker pull wn1980/dev-box:amd64     # AMD64 specific"
        echo "  docker pull wn1980/dev-box:arm64     # ARM64 specific"
        echo
        print_info "Test the multi-arch functionality:"
        echo "  docker run --platform linux/amd64 wn1980/dev-box:latest uname -m"
        echo "  docker run --platform linux/arm64 wn1980/dev-box:latest uname -m"
        
    else
        print_error "Some operations failed. Please check the errors above."
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Pushes multi-architecture dev-box images and creates manifest"
            echo
            echo "Prerequisites:"
            echo "  - Docker login: docker login"
            echo "  - Tagged images: wn1980/dev-box:amd64, wn1980/dev-box:arm64"
            echo
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo "  --dry-run      Show what would be pushed without actually pushing"
            echo
            echo "Images to push:"
            echo "  wn1980/dev-box:amd64"
            echo "  wn1980/dev-box:arm64"
            echo "  wn1980/dev-box:latest (multi-arch manifest)"
            exit 0
            ;;
        --dry-run)
            print_info "DRY RUN MODE - No actual pushing will be performed"
            echo
            print_info "Would push the following:"
            echo "  wn1980/dev-box:amd64"
            echo "  wn1980/dev-box:arm64"
            echo "  wn1980/dev-box:latest (multi-arch manifest)"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main
