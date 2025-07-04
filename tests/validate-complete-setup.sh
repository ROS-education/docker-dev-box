#!/bin/bash

# Complete validation script for Docker dev-box with host networking
# This script validates all aspects of host integration

echo "🚀 Docker Dev-Box Complete Setup Validation"
echo "============================================"

# Check if docker-compose.yaml exists and has host networking
echo
echo "📋 Checking Configuration Files..."
echo "---------------------------------"

if [ -f "docker-compose.yaml" ]; then
    if grep -q "network_mode: host" docker-compose.yaml; then
        echo "✅ docker-compose.yaml configured with host networking"
    else
        echo "⚠️  docker-compose.yaml missing host networking configuration"
    fi
    
    if grep -q "privileged: true" docker-compose.yaml; then
        echo "✅ Privileged mode enabled for hardware access"
    else
        echo "⚠️  Privileged mode not enabled"
    fi
    
    if grep -q "/var/run/docker.sock" docker-compose.yaml; then
        echo "✅ Docker socket mounted"
    else
        echo "⚠️  Docker socket not mounted"
    fi
    
    if grep -q "/dev:/dev" docker-compose.yaml; then
        echo "✅ Device access configured"
    else
        echo "⚠️  Device access not configured"
    fi
else
    echo "❌ docker-compose.yaml not found"
fi

# Check Dockerfile for network utilities
echo
echo "📦 Checking Dockerfile Network Configuration..."
echo "----------------------------------------------"

if [ -f "Dockerfile" ]; then
    if grep -q "netcat-openbsd" Dockerfile; then
        echo "✅ Network utilities included in Dockerfile"
    else
        echo "⚠️  Network utilities missing from Dockerfile"
    fi
    
    if grep -q "ListenAddress 0.0.0.0" Dockerfile; then
        echo "✅ SSH configured for host networking"
    else
        echo "⚠️  SSH not configured for host networking"
    fi
else
    echo "❌ Dockerfile not found"
fi

# Check supervisor configuration
echo
echo "🔧 Checking Supervisor Configuration..."
echo "-------------------------------------"

if [ -f "app/conf.d/sshd.conf" ]; then
    echo "✅ SSH supervisor config found"
else
    echo "❌ SSH supervisor config missing"
fi

# Check documentation
echo
echo "📚 Checking Documentation..."
echo "---------------------------"

docs=("README.md" "docs/HOST-NETWORK-SETUP.md" "docs/REMOTE-SETUP.md" "docs/SSH-SETUP.md")
for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo "✅ $doc"
    else
        echo "❌ $doc missing"
    fi
done

# Check test scripts
echo
echo "🧪 Checking Test Scripts..."
echo "-------------------------"

scripts=("test-host-network.sh" "test-usb-access.sh" "test-conda-setup.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "✅ $script (executable)"
    elif [ -f "$script" ]; then
        echo "⚠️  $script (not executable)"
        chmod +x "$script"
        echo "   → Made executable"
    else
        echo "❌ $script missing"
    fi
done

# Check for potential port conflicts
echo
echo "🔍 Checking for Potential Port Conflicts..."
echo "------------------------------------------"

# Check if SSH is running on host
if systemctl is-active --quiet ssh; then
    echo "✅ Host SSH service (port 22) won't conflict with container SSH (port 2222)"
else
    echo "✅ No host SSH service running"
fi

# Check if SSH is listening on the correct port (2222)
if netstat -tuln 2>/dev/null | grep -q ":2222 "; then
    echo "✅ SSH service running on port 2222"
else
    echo "❌ SSH service not detected on port 2222"
fi

# Check Docker installation
echo
echo "🐳 Checking Docker Installation..."
echo "--------------------------------"

if command -v docker > /dev/null 2>&1; then
    echo "✅ Docker installed"
    if docker --version; then
        echo "ℹ️  $(docker --version)"
    fi
else
    echo "❌ Docker not installed"
fi

if docker compose version > /dev/null 2>&1; then
    echo "✅ Docker Compose plugin installed"
    if docker compose version; then
        echo "ℹ️  $(docker compose version)"
    fi
elif command -v docker-compose > /dev/null 2>&1; then
    echo "✅ Docker Compose standalone installed"
    if docker-compose --version; then
        echo "ℹ️  $(docker-compose --version)"
    fi
else
    echo "❌ Docker Compose not installed"
fi

# Test if docker daemon is accessible
if docker ps > /dev/null 2>&1; then
    echo "✅ Docker daemon accessible"
else
    echo "⚠️  Docker daemon not accessible (may need sudo or user group setup)"
fi

echo
echo "📊 Setup Validation Summary"
echo "============================"
echo
echo "🌟 Host Resource Access Capabilities:"
echo "  • Network: Host network stack (direct access)"
echo "  • Hardware: USB/device access via privileged mode" 
echo "  • Docker: Full daemon access via socket mount"
echo "  • Storage: Volume mounts for persistent data"
echo "  • System: Near-complete host system mimicking"
echo
echo "🚀 Ready to Start:"
echo "  docker compose up -d --build"
echo
echo "🌐 Access Points (after start):"
echo "  • SSH Access:  ssh ubuntu@localhost"
echo "  • Remote:      ssh ubuntu@<host-ip>"
echo
echo "🔧 Testing Commands:"
echo "  • Test network: docker exec -it dev_box /workspace/test-host-network.sh"
echo "  • Test USB:     docker exec -it dev_box /workspace/test-usb-access.sh"
echo "  • Test conda:   docker exec -it dev_box /workspace/test-conda-setup.sh"
echo
echo "📖 Documentation:"
echo "  • See docs/HOST-NETWORK-SETUP.md for network configuration details"
echo "  • See docs/REMOTE-SETUP.md for remote development setup"
echo "  • See docs/SSH-SETUP.md for SSH key configuration"
echo
echo "⚠️  Security Reminders:"
echo "  • Change default password (ubuntu:ubuntu)"
echo "  • Review firewall settings for exposed ports"
echo "  • Consider SSH key authentication"
echo "  • This setup provides extensive host access"
