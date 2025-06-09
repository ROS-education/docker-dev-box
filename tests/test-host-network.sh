#!/bin/bash

# Test script to verify host networking configuration
# Run this script inside the container to test network functionality

echo "🌐 Testing Host Network Configuration"
echo "===================================="

echo
echo "📍 Container Network Interfaces:"
echo "--------------------------------"
ip addr show | grep -E "^\d+:|inet "

echo
echo "📍 Container Routing Table:"
echo "--------------------------"
ip route show

echo
echo "📍 DNS Resolution Test:"
echo "----------------------"
echo "Testing DNS resolution..."
if nslookup google.com > /dev/null 2>&1; then
    echo "✅ DNS resolution working"
else
    echo "❌ DNS resolution failed"
fi

echo
echo "📍 External Connectivity Test:"
echo "-----------------------------"
echo "Testing external connectivity..."
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ External connectivity working"
else
    echo "❌ External connectivity failed"
fi

echo
echo "📍 Host Port Binding Test:"
echo "-------------------------"
echo "Checking if SSH port is bound..."

# Check SSH port
if netstat -tuln | grep -q ":2222 "; then
    echo "✅ SSH server bound to port 2222"
else
    echo "❌ SSH server not bound to port 2222"
fi

echo
echo "📍 Host Network Namespace Test:"
echo "------------------------------"
echo "Comparing container and host network namespaces..."

# Check if we can see host processes (indication of shared network namespace)
if [ "$(readlink /proc/1/ns/net)" = "$(readlink /proc/self/ns/net)" ]; then
    echo "✅ Using host network namespace"
else
    echo "ℹ️  Using container network namespace (bridge mode)"
fi

echo
echo "📍 Network Tools Available:"
echo "--------------------------"
tools=("ping" "curl" "wget" "nmap" "netcat" "tcpdump" "dig" "traceroute")
for tool in "${tools[@]}"; do
    if command -v "$tool" > /dev/null 2>&1; then
        echo "✅ $tool"
    else
        echo "❌ $tool"
    fi
done

echo
echo "📍 Docker Socket Access:"
echo "-----------------------"
if [ -S /var/run/docker.sock ]; then
    echo "✅ Docker socket mounted"
    if docker ps > /dev/null 2>&1; then
        echo "✅ Docker commands working"
    else
        echo "❌ Docker commands failed (check permissions)"
    fi
else
    echo "❌ Docker socket not mounted"
fi

echo
echo "📍 USB Device Access:"
echo "--------------------"
if command -v lsusb > /dev/null 2>&1; then
    echo "✅ USB utilities available"
    usb_count=$(lsusb | wc -l)
    echo "ℹ️  Found $usb_count USB devices"
else
    echo "❌ USB utilities not available"
fi

echo
echo "📍 Summary:"
echo "----------"
echo "Host networking test completed."
echo "Check the results above for any issues."
echo ""
echo "💡 Tips:"
echo "- If SSH port 22 conflicts with host SSH, see HOST-NETWORK-SETUP.md"
echo "- For security, change default passwords before production use"
echo "- Use 'docker-compose logs dev-box' to check container logs"
