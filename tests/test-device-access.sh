#!/bin/bash

# Test device access from within the container

echo "🧪 Testing device access from container..."
echo "=========================================="

echo "📋 Available block devices:"
lsblk

echo ""
echo "💾 Disk information:"
df -h

echo ""
echo "🔍 /dev/sda* devices:"
ls -la /dev/sda* 2>/dev/null || echo "No /dev/sda* devices found"

echo ""
echo "🔍 NVMe devices:"
ls -la /dev/nvme* 2>/dev/null || echo "No NVMe devices found"

echo ""
echo "🔍 Loop devices:"
ls -la /dev/loop* 2>/dev/null || echo "No loop devices found"

echo ""
echo "📊 Partition information:"
cat /proc/partitions

echo ""
echo "🏗️ Device mapper:"
ls -la /dev/mapper/ 2>/dev/null || echo "No device mapper found"

echo ""
echo "🔧 Testing direct device access (read-only):"
for device in /dev/sda /dev/nvme0n1; do
    if [[ -b "$device" ]]; then
        echo "Testing $device..."
        # Try to read first sector (safe, read-only test)
        if dd if="$device" of=/dev/null bs=512 count=1 2>/dev/null; then
            echo "✅ Successfully accessed $device"
        else
            echo "❌ Failed to access $device"
        fi
    fi
done

echo ""
echo "🐳 Docker-in-Docker test:"
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker is available"
    docker --version
    echo "🏃 Testing Docker containers:"
    docker ps 2>/dev/null || echo "Docker daemon might not be running"
else
    echo "❌ Docker not found in container"
fi

echo ""
echo "✅ Device access test completed!"
