#!/bin/bash

# Test script to show current container capabilities
# Run this inside the container to see what privileges you have

echo "🔍 Container Capabilities Analysis"
echo "=================================="

echo
echo "📋 Current Process Capabilities:"
echo "-------------------------------"

# Check if we're running as privileged
if [ -f /proc/self/status ]; then
    echo "Current process capabilities:"
    grep -E "Cap(Inh|Prm|Eff|Bnd|Amb)" /proc/self/status
    echo
fi

# Decode capabilities if capsh is available
if command -v capsh >/dev/null 2>&1; then
    echo "📊 Decoded Capabilities:"
    echo "----------------------"
    echo "Effective capabilities:"
    capsh --decode=$(grep CapEff /proc/self/status | awk '{print $2}') 2>/dev/null || echo "Unable to decode"
    echo
    echo "Permitted capabilities:"
    capsh --decode=$(grep CapPrm /proc/self/status | awk '{print $2}') 2>/dev/null || echo "Unable to decode"
    echo
else
    echo "⚠️  capsh not available for capability decoding"
    echo "   Installing libcap2-bin for better analysis..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq && apt-get install -y libcap2-bin >/dev/null 2>&1
        if command -v capsh >/dev/null 2>&1; then
            echo "✅ capsh installed, re-run script for decoded output"
        fi
    fi
fi

echo
echo "🔐 Privilege Tests:"
echo "-------------------"

# Test privileged mode indicators
echo "Testing privilege indicators..."

# Check if we can access all capabilities
if [ "$(cat /proc/self/status | grep CapEff | awk '{print $2}')" = "000001ffffffffff" ] || [ "$(cat /proc/self/status | grep CapEff | awk '{print $2}')" = "0000003fffffffff" ]; then
    echo "✅ PRIVILEGED MODE DETECTED - All capabilities granted"
    PRIVILEGED=true
else
    echo "ℹ️  Limited capabilities mode"
    PRIVILEGED=false
fi

# Test specific administrative capabilities
echo
echo "🧪 Administrative Capability Tests:"
echo "----------------------------------"

# Test CAP_SYS_ADMIN (mount, many admin operations)
echo -n "CAP_SYS_ADMIN (mount/admin ops): "
if mount --bind /tmp /tmp 2>/dev/null; then
    echo "✅ Available"
    umount /tmp 2>/dev/null
else
    echo "❌ Not available"
fi

# Test CAP_NET_ADMIN (network administration)
echo -n "CAP_NET_ADMIN (network admin): "
if ip link show >/dev/null 2>&1; then
    echo "✅ Available"
else
    echo "❌ Not available"
fi

# Test CAP_SYS_PTRACE (debugging)
echo -n "CAP_SYS_PTRACE (debugging): "
if [ -r /proc/1/mem ] 2>/dev/null; then
    echo "✅ Available"
else
    echo "❌ Not available"
fi

# Test CAP_DAC_OVERRIDE (bypass file permissions)
echo -n "CAP_DAC_OVERRIDE (bypass perms): "
if [ -w /etc/passwd ] 2>/dev/null; then
    echo "✅ Available"
else
    echo "❌ Not available"
fi

# Test CAP_MKNOD (create device files)
echo -n "CAP_MKNOD (create devices): "
if mknod /tmp/test_device c 1 1 2>/dev/null; then
    echo "✅ Available"
    rm -f /tmp/test_device
else
    echo "❌ Not available"
fi

echo
echo "🌐 Network Capabilities:"
echo "-----------------------"

# Test network namespace
echo -n "Network namespace: "
if [ "$(readlink /proc/1/ns/net)" = "$(readlink /proc/self/ns/net)" ]; then
    echo "✅ Host network (network_mode: host)"
else
    echo "ℹ️  Container network"
fi

# Test raw socket creation (needs CAP_NET_RAW)
echo -n "CAP_NET_RAW (raw sockets): "
if python3 -c "import socket; socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)" 2>/dev/null; then
    echo "✅ Available"
else
    echo "❌ Not available"
fi

echo
echo "💾 Device Access:"
echo "----------------"

# Test device access
echo -n "Device access (/dev mounted): "
if [ -c /dev/null ] && [ -c /dev/zero ] && [ -d /dev ]; then
    device_count=$(ls /dev | wc -l)
    echo "✅ Available ($device_count devices)"
else
    echo "❌ Limited device access"
fi

# Test USB access
echo -n "USB device access: "
if command -v lsusb >/dev/null 2>&1; then
    usb_count=$(lsusb 2>/dev/null | wc -l)
    echo "✅ Available ($usb_count USB devices detected)"
else
    echo "❌ lsusb not available"
fi

echo
echo "🐳 Docker Integration:"
echo "--------------------"

# Test Docker socket access
echo -n "Docker socket access: "
if [ -S /var/run/docker.sock ]; then
    if docker ps >/dev/null 2>&1; then
        container_count=$(docker ps -q | wc -l)
        echo "✅ Available ($container_count running containers)"
    else
        echo "⚠️  Socket mounted but no permission"
    fi
else
    echo "❌ Docker socket not mounted"
fi

echo
echo "📊 Summary:"
echo "----------"

if [ "$PRIVILEGED" = true ]; then
    echo "🔴 PRIVILEGED MODE ACTIVE"
    echo "   • ALL Linux capabilities granted"
    echo "   • Maximum host access"
    echo "   • Equivalent to root on host for most operations"
    echo "   • Best for development environments"
    echo "   • ⚠️  High security risk in production"
else
    echo "🟡 LIMITED CAPABILITIES MODE"
    echo "   • Specific capabilities only"
    echo "   • Reduced host access"
    echo "   • Better security posture"
    echo "   • May limit some development tasks"
fi

echo
echo "🎯 Your Current Configuration:"
echo "-----------------------------"
echo "• privileged: true (in docker-compose.yaml)"
echo "• network_mode: host"
echo "• Device mounts: /dev:/dev"
echo "• Docker socket: mounted"
echo "• Result: Maximum host integration"

echo
echo "💡 Alternative Configurations:"
echo "-----------------------------"
echo "For production or security-conscious environments, consider:"
echo "• Using specific cap_add instead of privileged: true"
echo "• See CAPABILITIES-SETUP.md for alternatives"
echo "• Use docker-compose-caps.yaml for capability-based setup"
