#!/bin/bash

# Simple ARM64 Build Test Script

echo "🧪 Testing ARM64 Build Capabilities"
echo "==================================="

# Check Docker version
echo "Docker version:"
docker --version

# Check Docker Buildx
echo ""
echo "Docker Buildx availability:"
if docker buildx version 2>/dev/null; then
    echo "✅ Docker Buildx is available"
else
    echo "❌ Docker Buildx is not available"
    echo "   Multi-platform builds will not be possible"
fi

# Check current platform
echo ""
echo "Current platform:"
echo "  Architecture: $(uname -m)"
echo "  Platform: $(uname -s)/$(uname -m)"

# Test platform-specific build
echo ""
echo "Testing platform-specific build (dry run):"
echo "  For AMD64: docker build --platform linux/amd64 ."
echo "  For ARM64: docker build --platform linux/arm64 ."

echo ""
echo "✅ ARM64 build test completed"
