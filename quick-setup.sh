#!/bin/bash

# Quick setup script for docker-dev-box
# This script helps users get started quickly with minimal configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🚀 Docker Dev-Box Quick Setup${NC}"
    echo "================================"
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

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "Docker and Docker Compose are installed"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) DOCKER_ARCH="amd64" ;;
    aarch64|arm64) DOCKER_ARCH="arm64" ;;
    *) print_warning "Unsupported architecture: $ARCH. Defaulting to amd64"; DOCKER_ARCH="amd64" ;;
esac

print_info "Detected architecture: $ARCH (Docker: $DOCKER_ARCH)"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_info "Creating .env file..."
    DOCKER_GID=$(getent group docker 2>/dev/null | cut -d: -f3 || echo 988)
    cat > .env << EOF
# Docker Dev-Box Environment Configuration
HOST_DOCKER_GID=$DOCKER_GID
TZ=UTC
ARCH=$DOCKER_ARCH
COMPOSE_BAKE=true
EOF
    print_success "Created .env file with HOST_DOCKER_GID=$DOCKER_GID"
else
    print_info ".env file already exists"
fi

# Ask user what they want to do
echo
echo -e "${YELLOW}What would you like to do?${NC}"
echo "1. Build and start the development environment"
echo "2. Pull pre-built image and start"
echo "3. Build for specific architecture"
echo "4. Exit"
echo

read -p "Choose an option (1-4): " choice

case $choice in
    1)
        print_info "Building and starting the development environment..."
        docker compose up -d --build
        ;;
    2)
        print_info "Updating docker-compose.yaml to use pre-built image..."
        sed -i 's/^    image: .*/    image: wn1980\/dev-box:'$DOCKER_ARCH'/' docker-compose.yaml
        print_info "Starting the development environment..."
        docker compose up -d
        ;;
    3)
        echo "Available architectures:"
        echo "1. AMD64 (Intel/AMD)"
        echo "2. ARM64 (Apple Silicon, ARM servers)"
        echo "3. Both (multi-arch)"
        read -p "Choose architecture (1-3): " arch_choice
        
        case $arch_choice in
            1) ./scripts/build-multiarch.sh --platform amd64 ;;
            2) ./scripts/build-multiarch.sh --platform arm64 ;;
            3) ./scripts/build-multiarch.sh --platform all ;;
            *) print_error "Invalid choice"; exit 1 ;;
        esac
        ;;
    4)
        print_info "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# Check if container started successfully
sleep 5
if docker compose ps | grep -q "Up"; then
    print_success "Development environment is running!"
    echo
    echo -e "${GREEN}🎉 Setup complete!${NC}"
    echo
    echo -e "${BLUE}Access your development environment:${NC}"
    echo -e "  SSH: ${GREEN}ssh -p 2222 ubuntu@localhost${NC}"
    echo -e "  Password: ${GREEN}ubuntu${NC}"
    echo
    echo -e "${BLUE}Useful commands:${NC}"
    echo -e "  View logs: ${GREEN}docker compose logs -f${NC}"
    echo -e "  Stop: ${GREEN}docker compose down${NC}"
    echo -e "  Shell access: ${GREEN}docker exec -it dev_box bash${NC}"
    echo
    echo -e "${YELLOW}Security reminder: Change the default password in production!${NC}"
else
    print_error "Failed to start the development environment"
    echo "Check logs with: docker compose logs"
    exit 1
fi
