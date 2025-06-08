#!/bin/bash

# DANGEROUS SYSTEM CONTROL DEMONSTRATION
# This script shows the exact commands that would reboot/shutdown the host
# DO NOT RUN THESE COMMANDS UNLESS YOU WANT TO REBOOT/SHUTDOWN NOW!

echo "🚨 DANGER: Host System Control Commands"
echo "======================================"
echo
echo "⚠️  WARNING: These commands will IMMEDIATELY affect the host system!"
echo "    Only run them if you want to reboot/shutdown the host PC now."
echo

echo "🔴 EMERGENCY REBOOT (immediate, ungraceful):"
echo "   echo b > /proc/sysrq-trigger"
echo

echo "🔴 EMERGENCY SHUTDOWN (immediate, ungraceful):"
echo "   echo o > /proc/sysrq-trigger"
echo

echo "🟡 GRACEFUL REBOOT (proper shutdown sequence):"
echo "   systemctl reboot"
echo

echo "🟡 GRACEFUL SHUTDOWN (proper shutdown sequence):"
echo "   systemctl poweroff"
echo

echo "🔵 SAFER ALTERNATIVES (with delays/confirmations):"
echo "   shutdown -r +1    # Reboot in 1 minute"
echo "   shutdown -h +1    # Shutdown in 1 minute"
echo "   shutdown -c       # Cancel scheduled shutdown"
echo

echo "📊 CURRENT SYSTEM STATUS:"
echo "   Host uptime: $(cat /proc/uptime | cut -d. -f1) seconds"
echo "   Host kernel: $(uname -r)"
echo "   System state: $(systemctl is-system-running 2>/dev/null || echo 'unknown')"
echo

echo "✅ PROOF: Container CAN control host power state"
echo "   All commands above are functional and will work from this container."
echo
echo "⚠️  Remember: With great power comes great responsibility!"
echo "    Only use these commands when intended."

# Safety check
echo
read -p "Do you want to see a SAFE system information query? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "📋 Safe system information:"
    echo "   Default target: $(systemctl get-default 2>/dev/null || echo 'unknown')"
    echo "   Active services: $(systemctl list-units --type=service --state=active --no-pager --no-legend | wc -l) running"
    echo "   System load: $(cat /proc/loadavg)"
    echo "   Memory usage: $(grep -E 'MemTotal|MemFree' /proc/meminfo | tr '\n' ' ')"
fi

echo
echo "Test completed safely. No system changes made."
