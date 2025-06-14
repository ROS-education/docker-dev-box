#!/bin/bash

# Test to demonstrate the difference between /dev volume mount vs explicit device mappings

echo "🧪 Testing Device Access: Volume Mount vs Device Mappings"
echo "=========================================================="

# Test 1: Check if devices exist in /dev
echo "📋 1. Checking device visibility in /dev:"
echo "   /dev/nvme0n1 exists: $(test -e /dev/nvme0n1 && echo "✅ YES" || echo "❌ NO")"
echo "   /dev/nvme0n1p1 exists: $(test -e /dev/nvme0n1p1 && echo "✅ YES" || echo "❌ NO")"

# Test 2: Check device permissions
echo ""
echo "🔒 2. Device permissions:"
ls -la /dev/nvme0n1* 2>/dev/null || echo "   No NVMe devices found in /dev"

# Test 3: Try to read device information
echo ""
echo "📖 3. Testing device read access:"
if [[ -b /dev/nvme0n1 ]]; then
    echo "   /dev/nvme0n1 is a block device: ✅"
    if timeout 2 dd if=/dev/nvme0n1 of=/dev/null bs=512 count=1 2>/dev/null; then
        echo "   Can read from /dev/nvme0n1: ✅"
    else
        echo "   Cannot read from /dev/nvme0n1: ❌ (Permission denied or device not accessible)"
    fi
else
    echo "   /dev/nvme0n1 is not recognized as block device: ❌"
fi

# Test 4: Check device major/minor numbers
echo ""
echo "🔢 4. Device major/minor numbers:"
if [[ -b /dev/nvme0n1 ]]; then
    stat -c "   /dev/nvme0n1: %t:%T (major:minor)" /dev/nvme0n1 2>/dev/null || echo "   Cannot stat /dev/nvme0n1"
else
    echo "   /dev/nvme0n1 not accessible for stat"
fi

# Test 5: Check cgroup device permissions
echo ""
echo "🔐 5. Container cgroup device permissions:"
if [[ -f /sys/fs/cgroup/devices/devices.allow ]]; then
    echo "   Device cgroup rules:"
    cat /sys/fs/cgroup/devices/devices.allow 2>/dev/null | head -10 || echo "   Cannot read cgroup device rules"
elif [[ -f /sys/fs/cgroup/devices.allow ]]; then
    echo "   Device cgroup rules (cgroups v2):"
    cat /sys/fs/cgroup/devices.allow 2>/dev/null | head -10 || echo "   Cannot read cgroup device rules"
else
    echo "   No device cgroup information found"
fi

# Test 6: Try low-level device operations
echo ""
echo "⚙️ 6. Low-level device operations test:"
if command -v blkid >/dev/null 2>&1; then
    echo "   blkid output:"
    blkid /dev/nvme0n1* 2>/dev/null | head -5 || echo "   blkid failed - device not accessible"
else
    echo "   blkid not available"
fi

# Test 7: Check if Docker can access devices
echo ""
echo "🐳 7. Docker device access test:"
if command -v docker >/dev/null 2>&1; then
    echo "   Testing Docker container device access..."
    # Try to run a simple container that lists block devices
    docker run --rm alpine:latest lsblk 2>/dev/null | head -5 || echo "   Docker device access test failed"
else
    echo "   Docker not available for testing"
fi

echo ""
echo "📝 Summary:"
echo "   - Volume mount (/dev:/dev) provides file system access"
echo "   - Device mappings (devices:) provide proper device node access"
echo "   - Both are needed for full device functionality in containers"
echo ""
echo "🔍 For Docker-in-Docker, explicit device mappings ensure:"
echo "   1. Proper device permissions"
echo "   2. Correct cgroup device access control"  
echo "   3. Device node major/minor number preservation"
echo "   4. Container security model compliance"
