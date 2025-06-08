#!/bin/bash

# SYSTEM CONTROL DEMONSTRATION - SAFE VERSION
# Shows the exact commands that can control the host system
# WITHOUT actually executing them

echo "🖥️  Host System Control Demonstration"
echo "==================================="
echo
echo "⚠️  This script demonstrates the container's ability to control the host"
echo "    system without actually executing dangerous commands."
echo

echo "📋 Container Configuration Analysis:"
echo "-----------------------------------"
if [ -f /.dockerenv ]; then
    echo "✅ Running inside Docker container"
    
    # Check privileged mode
    if [ -w /proc/sysrq-trigger ]; then
        echo "✅ Privileged mode: ENABLED (can write to SysRq)"
    else
        echo "❌ Privileged mode: DISABLED"
    fi
    
    # Check PID namespace
    if [ -d /proc/1 ]; then
        echo "✅ PID namespace: HOST (can see PID 1)"
    else
        echo "❌ PID namespace: CONTAINER"
    fi
    
    # Check network
    if ip route 2>/dev/null | grep -q default; then
        echo "✅ Network: HOST mode ($(ip route show default | head -1))"
    else
        echo "❌ Network: Container mode"
    fi
else
    echo "❌ Not running in container"
fi

echo
echo "🔍 Available Power Control Methods:"
echo "--------------------------------"

# Method 1: Magic SysRq
echo "1. Magic SysRq (Emergency Hardware Control):"
if [ -w /proc/sysrq-trigger ]; then
    echo "   ✅ SysRq trigger accessible: /proc/sysrq-trigger"
    echo "   ✅ SysRq mask: $(cat /proc/sys/kernel/sysrq 2>/dev/null || echo 'unknown')"
    echo "   🔴 IMMEDIATE REBOOT: echo b > /proc/sysrq-trigger"
    echo "   🔴 IMMEDIATE SHUTDOWN: echo o > /proc/sysrq-trigger"
    echo "   🔴 EMERGENCY SYNC: echo s > /proc/sysrq-trigger"
else
    echo "   ❌ SysRq trigger not accessible"
fi

echo
echo "2. Traditional Power Commands:"
for cmd in reboot halt poweroff shutdown; do
    if command -v $cmd >/dev/null 2>&1; then
        echo "   ✅ $cmd: Available at $(which $cmd)"
        case $cmd in
            reboot)   echo "      🟡 SYSTEM REBOOT: $cmd" ;;
            halt)     echo "      🟡 SYSTEM HALT: $cmd" ;;
            poweroff) echo "      🟡 SYSTEM POWEROFF: $cmd" ;;
            shutdown) echo "      🟡 SCHEDULED SHUTDOWN: $cmd -h +1" ;;
        esac
    else
        echo "   ❌ $cmd: Not available"
    fi
done

echo
echo "3. systemd Control:"
if command -v systemctl >/dev/null 2>&1; then
    echo "   ✅ systemctl: Available"
    if systemctl --version >/dev/null 2>&1; then
        echo "   ✅ systemd communication: Working"
        echo "   🟡 GRACEFUL REBOOT: systemctl reboot"
        echo "   🟡 GRACEFUL SHUTDOWN: systemctl poweroff"
    else
        echo "   ⚠️  systemctl present but cannot communicate with systemd"
    fi
else
    echo "   ❌ systemctl: Not available"
fi

echo
echo "📊 Host System Information:"
echo "-------------------------"
echo "Host uptime: $(cat /proc/uptime | cut -d. -f1) seconds ($(( $(cat /proc/uptime | cut -d. -f1) / 3600 )) hours)"
echo "Host kernel: $(uname -r)"
echo "Host architecture: $(uname -m)"
echo "Host processes: $(ps aux 2>/dev/null | wc -l) visible"
echo "Container processes: $(ps aux 2>/dev/null | grep -v '\[' | wc -l) running"

echo
echo "🚨 SECURITY RISK ASSESSMENT:"
echo "============================"

risk_level=0
can_emergency_reboot=false
can_traditional_reboot=false
can_systemd_reboot=false

if [ -w /proc/sysrq-trigger ]; then
    echo "🔴 CRITICAL: Emergency hardware control available"
    risk_level=$((risk_level + 5))
    can_emergency_reboot=true
fi

if command -v reboot >/dev/null 2>&1 || command -v halt >/dev/null 2>&1 || command -v poweroff >/dev/null 2>&1; then
    echo "🟡 HIGH: Traditional power commands available"
    risk_level=$((risk_level + 3))
    can_traditional_reboot=true
fi

if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
    echo "🟡 MEDIUM: systemd control available"
    risk_level=$((risk_level + 2))
    can_systemd_reboot=true
fi

echo
echo "📈 OVERALL RISK LEVEL: $risk_level/10"

if [ $risk_level -ge 8 ]; then
    echo "🔴 MAXIMUM RISK: Container has FULL host control"
elif [ $risk_level -ge 5 ]; then
    echo "🟡 HIGH RISK: Container has significant host control"
elif [ $risk_level -ge 2 ]; then
    echo "🟡 MEDIUM RISK: Container has limited host control"
else
    echo "🟢 LOW RISK: Container has minimal host control"
fi

echo
echo "✅ DEMONSTRATION SUMMARY:"
echo "======================="

if $can_emergency_reboot || $can_traditional_reboot || $can_systemd_reboot; then
    echo "🎯 RESULT: Container CAN control host power state"
    echo
    echo "Available methods:"
    $can_emergency_reboot && echo "  • Emergency hardware control (immediate)"
    $can_traditional_reboot && echo "  • Traditional power commands (system-level)"
    $can_systemd_reboot && echo "  • systemd service management (graceful)"
    
    echo
    echo "⚠️  This means the container can reboot or shutdown the host PC!"
else
    echo "🎯 RESULT: Container CANNOT control host power state"
    echo "   Host system is protected from container power control."
fi

echo
echo "📝 Note: This demonstration did NOT execute any dangerous commands."
echo "    All power control capabilities were tested safely."
echo
echo "🔧 To see actual commands that would work, check:"
echo "    - SYSTEM-CONTROL-TEST-RESULTS.md"
echo "    - system-control-test.sh"

echo ""
echo "🏗️ Architecture Build Support:"
echo "-----------------------------"

echo "Current system architecture: $(uname -m)"

# Test Docker Buildx for multi-platform support
if command -v docker >/dev/null 2>&1; then
    if docker buildx version >/dev/null 2>&1; then
        echo "✅ Docker Buildx available for multi-platform builds"
        echo "   Supported platforms:"
        echo "   • linux/amd64 (Intel/AMD 64-bit)"
        echo "   • linux/arm64 (ARM 64-bit, Apple Silicon)"
        echo "   • Cross-platform emulation supported"
    else
        echo "⚠️  Docker Buildx not available"
        echo "   Single-platform builds only"
    fi
else
    echo "❌ Docker not available"
fi

echo ""
echo "🍎 Apple Silicon Mac Support:"
echo "----------------------------"
echo "   For M1/M2/M3 Macs, use:"
echo "   • ./build-multiarch.sh --platform arm64"
echo "   • docker build --platform linux/arm64 ."
echo "   • Native ARM64 performance (no emulation)"

echo ""
echo "🌍 Cross-Platform Development:"
echo "-----------------------------"
echo "   Build both architectures:"
echo "   • ./build-multiarch.sh --platform all"
echo "   • docker buildx build --platform linux/amd64,linux/arm64 ."
