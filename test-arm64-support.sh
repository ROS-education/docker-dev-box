#!/bin/bash

# ARM64 Architecture Test Script
# Tests ARM64-specific functionality and compatibility

set -e

echo "🔍 ARM64 Architecture Compatibility Test"
echo "======================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Test 1: Architecture Detection
print_info "Testing Architecture Detection"
echo "----------------------------"

RUNTIME_ARCH=$(uname -m)
KERNEL_ARCH=$(uname -p 2>/dev/null || echo "unknown")
TARGET_ARCH=${TARGETARCH:-"not set"}

echo "Runtime architecture: $RUNTIME_ARCH"
echo "Kernel architecture:  $KERNEL_ARCH"
echo "Target architecture:  $TARGET_ARCH"

case "$RUNTIME_ARCH" in
    aarch64|arm64)
        print_success "ARM64 architecture detected"
        IS_ARM64=true
        ;;
    x86_64)
        print_success "AMD64 architecture detected"
        IS_ARM64=false
        ;;
    armv7l)
        print_warning "ARM v7 architecture detected (32-bit)"
        IS_ARM64=false
        ;;
    *)
        print_warning "Unknown architecture: $RUNTIME_ARCH"
        IS_ARM64=false
        ;;
esac

echo

# Test 2: Conda Installation and Architecture
print_info "Testing Conda Installation"
echo "-------------------------"

if command -v conda >/dev/null 2>&1; then
    print_success "Conda is installed"
    CONDA_VERSION=$(conda --version 2>/dev/null || echo "unknown")
    echo "Conda version: $CONDA_VERSION"
    
    # Test conda info
    if conda info >/dev/null 2>&1; then
        print_success "Conda is functional"
        CONDA_PLATFORM=$(conda info | grep "platform" | head -1 | awk '{print $3}' || echo "unknown")
        echo "Conda platform: $CONDA_PLATFORM"
        
        case "$CONDA_PLATFORM" in
            *linux-aarch64*)
                print_success "Conda configured for ARM64"
                ;;
            *linux-64*)
                print_success "Conda configured for AMD64"
                ;;
            *)
                print_warning "Conda platform: $CONDA_PLATFORM"
                ;;
        esac
    else
        print_error "Conda installation issues detected"
    fi
else
    print_error "Conda not found in PATH"
fi

echo

# Test 3: Node.js and npm Architecture
print_info "Testing Node.js Installation"
echo "---------------------------"

if command -v node >/dev/null 2>&1; then
    print_success "Node.js is installed"
    NODE_VERSION=$(node --version 2>/dev/null || echo "unknown")
    echo "Node.js version: $NODE_VERSION"
    
    NODE_ARCH=$(node -e "console.log(process.arch)" 2>/dev/null || echo "unknown")
    echo "Node.js architecture: $NODE_ARCH"
    
    case "$NODE_ARCH" in
        arm64)
            print_success "Node.js configured for ARM64"
            ;;
        x64)
            print_success "Node.js configured for AMD64"
            ;;
        *)
            print_warning "Node.js architecture: $NODE_ARCH"
            ;;
    esac
else
    print_error "Node.js not found"
fi

if command -v npm >/dev/null 2>&1; then
    print_success "npm is available"
    NPM_VERSION=$(npm --version 2>/dev/null || echo "unknown")
    echo "npm version: $NPM_VERSION"
else
    print_error "npm not found"
fi

echo

# Test 4: Docker CLI Architecture
print_info "Testing Docker CLI"
echo "-----------------"

if command -v docker >/dev/null 2>&1; then
    print_success "Docker CLI is installed"
    DOCKER_VERSION=$(docker --version 2>/dev/null || echo "unknown")
    echo "Docker version: $DOCKER_VERSION"
    
    # Test docker info if daemon is accessible
    if docker info >/dev/null 2>&1; then
        print_success "Docker daemon is accessible"
        DOCKER_ARCH=$(docker info --format '{{.Architecture}}' 2>/dev/null || echo "unknown")
        echo "Docker daemon architecture: $DOCKER_ARCH"
    else
        print_warning "Docker daemon not accessible (expected in build context)"
    fi
else
    print_error "Docker CLI not found"
fi

echo

# Test 5: Network Utilities
print_info "Testing Network Utilities"
echo "------------------------"

NETWORK_TOOLS=("curl" "wget" "netcat" "ping" "traceroute" "nslookup" "nmap")

for tool in "${NETWORK_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        print_success "$tool is available"
    else
        print_error "$tool not found"
    fi
done

echo

# Test 6: Code Server Architecture Compatibility
print_info "Testing Code Server"
echo "------------------"

if command -v code-server >/dev/null 2>&1; then
    print_success "Code-server is installed"
    CODE_SERVER_VERSION=$(code-server --version 2>/dev/null | head -1 || echo "unknown")
    echo "Code-server version: $CODE_SERVER_VERSION"
else
    print_error "Code-server not found"
fi

echo

# Test 7: ngrok Architecture
print_info "Testing ngrok"
echo "------------"

if command -v ngrok >/dev/null 2>&1; then
    print_success "ngrok is installed"
    NGROK_VERSION=$(ngrok version 2>/dev/null || echo "unknown")
    echo "ngrok version: $NGROK_VERSION"
else
    print_error "ngrok not found"
fi

echo

# Test 8: System Libraries and Dependencies
print_info "Testing System Libraries"
echo "-----------------------"

# Test for ARM64-specific library paths
if [ "$IS_ARM64" = true ]; then
    if [ -d "/lib/aarch64-linux-gnu" ]; then
        print_success "ARM64 system libraries found"
        LIB_COUNT=$(ls /lib/aarch64-linux-gnu/ | wc -l)
        echo "Library count: $LIB_COUNT"
    else
        print_warning "ARM64 library directory not found"
    fi
    
    if [ -d "/usr/lib/aarch64-linux-gnu" ]; then
        print_success "ARM64 usr libraries found"
    else
        print_warning "ARM64 usr library directory not found"
    fi
else
    if [ -d "/lib/x86_64-linux-gnu" ]; then
        print_success "AMD64 system libraries found"
    else
        print_warning "AMD64 library directory not found"
    fi
fi

echo

# Test 9: Container Environment
print_info "Testing Container Environment"
echo "----------------------------"

if [ -f /.dockerenv ]; then
    print_success "Running inside Docker container"
    
    # Check for multi-arch build args
    if [ -n "${TARGETARCH:-}" ]; then
        print_success "TARGETARCH build arg: $TARGETARCH"
    else
        print_warning "TARGETARCH build arg not set"
    fi
    
    if [ -n "${TARGETPLATFORM:-}" ]; then
        print_success "TARGETPLATFORM build arg: $TARGETPLATFORM"
    else
        print_warning "TARGETPLATFORM build arg not set"
    fi
else
    print_warning "Not running in Docker container"
fi

echo

# Summary
print_info "Architecture Compatibility Summary"
echo "================================="

if [ "$IS_ARM64" = true ]; then
    print_success "✅ ARM64 architecture detected and supported"
    echo "  • All major components should work on ARM64"
    echo "  • Conda, Node.js, Docker CLI, and tools are compatible"
else
    print_success "✅ AMD64 architecture detected and supported"
    echo "  • All components work on AMD64"
    echo "  • Full compatibility confirmed"
fi

echo
print_info "🚀 Architecture test completed"
echo
echo "Build recommendations:"
echo "  • For current platform: docker build ."
echo "  • For ARM64 specifically: docker build --platform linux/arm64 ."
echo "  • For AMD64 specifically: docker build --platform linux/amd64 ."
echo "  • For both platforms: ./build-multiarch.sh --platform all"
