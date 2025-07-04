#!/bin/bash

echo "🖥️  System Control Test - Container to Host"
echo "==========================================="
echo

echo "📋 Container Configuration:"
echo "Privileged: $([ -f /.dockerenv ] && echo 'Yes' || echo 'No')"
echo "PID namespace: $([ -d /proc/1 ] && echo 'Can see PID 1' || echo 'Cannot see PID 1')"
echo "Network: $(ip route show | grep default | head -1)"
echo

echo "🔍 Critical System Control Tests:"
echo

# Test 1: SysRq access
echo "1. Magic SysRq Test:"
if [ -w /proc/sysrq-trigger ]; then
    echo "   ✅ SysRq trigger is WRITABLE"
    echo "   Current SysRq mask: $(cat /proc/sys/kernel/sysrq 2>/dev/null || echo 'Cannot read')"
    echo "   🚨 This means we CAN forcibly reboot the host!"
    echo "   Commands that would reboot host:"
    echo "      echo b > /proc/sysrq-trigger  # Immediate reboot"
    echo "      echo o > /proc/sysrq-trigger  # Immediate shutdown"
else
    echo "   ❌ SysRq trigger not writable"
fi

echo

# Test 2: Systemd access  
echo "2. Systemd Communication:"
if command -v systemctl >/dev/null 2>&1; then
    echo "   ✅ systemctl command available"
    if systemctl --version >/dev/null 2>&1; then
        echo "   ✅ Can communicate with systemd"
        echo "   🚨 This means we can use: systemctl reboot"
        echo "   🚨 This means we can use: systemctl poweroff"
    else
        echo "   ⚠️  systemctl present but cannot communicate"
    fi
else
    echo "   ❌ systemctl not available"
fi

echo

# Test 3: Traditional commands
echo "3. Traditional Power Commands:"
for cmd in shutdown reboot halt poweroff; do
    if command -v $cmd >/dev/null 2>&1; then
        echo "   ✅ $cmd command available"
    else
        echo "   ❌ $cmd not found"
    fi
done

echo

echo "📊 SECURITY ASSESSMENT:"
echo "======================"

can_reboot=false

if [ -w /proc/sysrq-trigger ]; then
    echo "🔴 CRITICAL: Container CAN forcibly reboot host via SysRq"
    can_reboot=true
fi

if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
    echo "🔴 CRITICAL: Container CAN reboot host via systemctl"  
    can_reboot=true
fi

if $can_reboot; then
    echo
    echo "⚠️  DANGER: This container has FULL control over host power state!"
    echo "   It can reboot or shutdown the host system at any time."
    echo "   This is due to:"
    echo "   - privileged: true"
    echo "   - pid: host" 
    echo "   - Access to /proc filesystem"
    echo "   - Access to systemd socket"
else
    echo "🟢 SAFE: Container cannot control host power state"
fi

echo
echo "Test completed. Container has $([ $can_reboot = true ] && echo 'FULL' || echo 'NO') host control."
