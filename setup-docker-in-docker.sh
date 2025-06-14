#!/bin/bash

# Fix Docker socket permissions for Docker-in-Docker access
# This script ensures the container can access the Docker socket properly

set -e

echo "🔧 Setting up Docker-in-Docker permissions..."

# Get the host Docker group GID
HOST_DOCKER_GID=$(getent group docker | cut -d: -f3 2>/dev/null || echo "999")

echo "📋 Host Docker group GID: $HOST_DOCKER_GID"

# Update environment file
if [[ -f ".env" ]]; then
    # Update existing .env file
    if grep -q "HOST_DOCKER_GID" .env; then
        sed -i "s/HOST_DOCKER_GID=.*/HOST_DOCKER_GID=$HOST_DOCKER_GID/" .env
        echo "✅ Updated HOST_DOCKER_GID in .env file"
    else
        echo "HOST_DOCKER_GID=$HOST_DOCKER_GID" >> .env
        echo "✅ Added HOST_DOCKER_GID to .env file"
    fi
else
    # Create new .env file
    cat > .env << EOF
# Auto-generated Docker environment
HOST_DOCKER_GID=$HOST_DOCKER_GID
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
TZ=$(timedatectl show -p Timezone --value 2>/dev/null || echo "UTC")
EOF
    echo "✅ Created .env file with HOST_DOCKER_GID=$HOST_DOCKER_GID"
fi

# Check Docker socket permissions
echo ""
echo "🔍 Docker socket information:"
ls -la /var/run/docker.sock

echo ""
echo "🐳 Current Docker info:"
docker info --format "{{.ServerVersion}}" 2>/dev/null || echo "Docker daemon not accessible"

echo ""
echo "✅ Docker-in-Docker setup completed!"
echo "💡 You can now run Docker Compose with full device access:"
echo "   docker-compose -f docker-compose-auto-devices.yaml up -d"
echo "   docker-compose -f docker-compose-full-device-access.yaml up -d"
