#!/bin/bash

# Docker DNS Fix Script
# Resolves DNS issues during Docker builds by configuring DNS settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}🔧 Docker DNS Configuration Fix${NC}"
    echo "===================================="
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

# Check if running as root for Docker daemon configuration
if [[ $EUID -eq 0 ]]; then
    DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"
    
    print_info "Configuring Docker daemon DNS settings..."
    
    # Create Docker directory if it doesn't exist
    mkdir -p /etc/docker
    
    # Create or update daemon.json with DNS configuration
    if [ -f "$DOCKER_DAEMON_CONFIG" ]; then
        print_info "Backing up existing daemon.json..."
        cp "$DOCKER_DAEMON_CONFIG" "$DOCKER_DAEMON_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Create daemon.json with DNS configuration
    cat > "$DOCKER_DAEMON_CONFIG" << 'EOF'
{
    "dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF
    
    print_success "Docker daemon configuration updated"
    print_warning "Docker daemon restart required for changes to take effect"
    print_info "Run: sudo systemctl restart docker"
    
else
    print_warning "Not running as root - will provide manual configuration steps"
fi

print_info "Alternative DNS resolution methods:"
echo "1. Use --network host flag during build"
echo "2. Add specific host entries with --add-host"
echo "3. Configure system DNS settings"
echo "4. Use public DNS servers (8.8.8.8, 1.1.1.1)"
echo

# Test DNS resolution
print_info "Testing DNS resolution..."

for host in "archive.ubuntu.com" "security.ubuntu.com" "download.docker.com"; do
    if nslookup "$host" >/dev/null 2>&1; then
        print_success "DNS resolution for $host: OK"
    else
        print_error "DNS resolution for $host: FAILED"
        
        # Try to resolve and provide IP
        if command -v dig >/dev/null 2>&1; then
            IP=$(dig +short "$host" 2>/dev/null | head -n1)
            if [ -n "$IP" ]; then
                print_info "  Resolved IP: $IP"
                echo "  Use: --add-host $host:$IP"
            fi
        fi
    fi
done

echo
print_info "Quick build command with DNS fix:"
echo "docker build --network host --dns 8.8.8.8 --dns 8.8.4.4 -t dev-box ."
echo
print_info "Or use the enhanced build script which now includes DNS fixes:"
echo "./build-multiarch.sh --platform $(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"

echo
print_success "DNS configuration check completed!"
