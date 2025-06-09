#!/bin/bash

# Script to tag multi-architecture dev-box images to wn1980/dev-box repository
# This script tags:
# - dev-box:latest-linux-amd64 -> wn1980/dev-box:amd64
# - dev-box:latest-linux-arm64 -> wn1980/dev-box:arm64

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Multi-Arch Image Tagging Script${NC}"
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

# Function to check if image exists
check_image_exists() {
    local image_name="$1"
    if docker image inspect "$image_name" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to tag image
tag_image() {
    local source_tag="$1"
    local target_tag="$2"
    
    print_info "Tagging $source_tag -> $target_tag"
    
    if check_image_exists "$source_tag"; then
        if docker tag "$source_tag" "$target_tag"; then
            print_success "Successfully tagged: $target_tag"
            return 0
        else
            print_error "Failed to tag: $source_tag -> $target_tag"
            return 1
        fi
    else
        print_error "Source image not found: $source_tag"
        return 1
    fi
}

# Main execution
main() {
    print_header
    
    # Define source and target image mappings
    local -a SOURCE_TAGS=("dev-box:latest-linux-amd64" "dev-box:latest-linux-arm64")
    local -a TARGET_TAGS=("wn1980/dev-box:amd64" "wn1980/dev-box:arm64")
    
    print_info "Current dev-box images:"
    docker images | grep dev-box | head -10
    echo
    
    print_info "Starting image tagging process..."
    echo
    
    local success_count=0
    local total_count=${#SOURCE_TAGS[@]}
    
    # Process each mapping
    for i in "${!SOURCE_TAGS[@]}"; do
        local source_tag="${SOURCE_TAGS[$i]}"
        local target_tag="${TARGET_TAGS[$i]}"
        
        if tag_image "$source_tag" "$target_tag"; then
            ((success_count++))
        fi
        echo
    done
    
    # Summary
    print_header
    print_info "Tagging Summary:"
    echo "  Total images to tag: $total_count"
    echo "  Successfully tagged: $success_count"
    echo "  Failed: $((total_count - success_count))"
    echo
    
    if [ $success_count -eq $total_count ]; then
        print_success "All images tagged successfully!"
        
        print_info "New wn1980/dev-box images:"
        docker images | grep "wn1980/dev-box" || print_warning "No wn1980/dev-box images found"
        echo
        
        print_info "To push these images to Docker Hub, run:"
        echo "  docker push wn1980/dev-box:amd64"
        echo "  docker push wn1980/dev-box:arm64"
        echo
        
        print_info "To create a multi-arch manifest, run:"
        echo "  docker manifest create wn1980/dev-box:latest wn1980/dev-box:amd64 wn1980/dev-box:arm64"
        echo "  docker manifest push wn1980/dev-box:latest"
        
    else
        print_error "Some images failed to tag. Please check the errors above."
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Tags multi-architecture dev-box images to wn1980/dev-box repository"
            echo
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo "  --dry-run      Show what would be tagged without actually tagging"
            echo
            echo "Image mappings:"
            echo "  dev-box:latest-linux-amd64 -> wn1980/dev-box:amd64"
            echo "  dev-box:latest-linux-arm64 -> wn1980/dev-box:arm64"
            exit 0
            ;;
        --dry-run)
            print_info "DRY RUN MODE - No actual tagging will be performed"
            echo
            print_info "Would tag the following images:"
            echo "  dev-box:latest-linux-amd64 -> wn1980/dev-box:amd64"
            echo "  dev-box:latest-linux-arm64 -> wn1980/dev-box:arm64"
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
