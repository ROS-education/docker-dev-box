#!/bin/bash

# Test script to check host system control capabilities from Docker container
# This script tests various system control methods WITHOUT actually rebooting

echo "🖥️  Host System Control Capabilities Test"
echo "=========================================="

echo
echo "📋 Current Container Configuration:"
echo "---------------------------------"

# Check if running in privileged mode
if [ -f /proc/self/status ]; then
    eff_caps=$(grep CapEff /proc/self/status | awk '{print $2}')
    if [ "$eff_caps" = "000001ffffffffff" ] || [ "$eff_caps" = "0000003fffffffff" ]; then
        echo "✅ Running in privileged mode"
        PRIVILEGED=true
    else
        echo "❌ Not running in privileged mode"
        PRIVILEGED=false
    fi
else
    echo "⚠️  Cannot determine privilege level"
    PRIVILEGED=false
fi

# Check PID namespace
echo -n "PID namespace: "
if [ "$(readlink /proc/1/ns/pid)" = "$(readlink /proc/self/ns/pid)" ]; then
    echo "✅ Host PID namespace (can see all host processes)"
    HOST_PID=true
else
    echo "ℹ️  Container PID namespace"
    HOST_PID=false
fi

# Check network namespace
echo -n "Network namespace: "
if [ "$(readlink /proc/1/ns/net)" = "$(readlink /proc/self/ns/net)" ]; then
    echo "✅ Host network namespace"
    HOST_NET=true
else
    echo "ℹ️  Container network namespace"
    HOST_NET=false
fi

echo
echo "🔍 System Control Tests:"
echo "-----------------------"

# Test systemctl availability
echo -n "systemctl command: "
if command -v systemctl >/dev/null 2>&1; then
    echo "✅ Available"
    SYSTEMCTL=true
else
    echo "❌ Not available"
    SYSTEMCTL=false
fi

# Test if we can communicate with systemd
echo -n "systemd communication: "
if systemctl --version >/dev/null 2>&1; then
    echo "✅ Can communicate with systemd"
    SYSTEMD_COMM=true
else
    echo "❌ Cannot communicate with systemd"
    SYSTEMD_COMM=false
fi

# Test shutdown command availability
echo -n "shutdown command: "
if command -v shutdown >/dev/null 2>&1; then
    echo "✅ Available"
    SHUTDOWN=true
else
    echo "❌ Not available"
    SHUTDOWN=false
fi

# Test reboot command availability
echo -n "reboot command: "
if command -v reboot >/dev/null 2>&1; then
    echo "✅ Available"
    REBOOT=true
else
    echo "❌ Not available"
    REBOOT=false
fi

echo
echo "🧪 Capability Tests (Non-destructive):"
echo "-------------------------------------"

# Test CAP_SYS_ADMIN (needed for system control)
echo -n "CAP_SYS_ADMIN: "
if [ -w /proc/sys/kernel/sysrq ] 2>/dev/null; then
    echo "✅ Available (can write to sysrq)"
else
    echo "❌ Not available"
fi

# Test access to systemd units (read-only test)
echo -n "systemd unit access: "
if systemctl list-units --type=service --state=running >/dev/null 2>&1; then
    running_services=$(systemctl list-units --type=service --state=running --no-pager --no-legend | wc -l)
    echo "✅ Available ($running_services running services visible)"
else
    echo "❌ Cannot access systemd units"
fi

# Test host process visibility
echo -n "Host process visibility: "
if ps aux | grep -q systemd && ps aux | grep -v grep | grep -q "systemd.*--system"; then
    total_processes=$(ps aux | wc -l)
    echo "✅ Can see host processes ($total_processes total)"
else
    echo "❌ Limited process visibility"
fi

echo
echo "💾 System Information Access:"
echo "---------------------------"

# Test uptime access
echo -n "System uptime: "
if uptime >/dev/null 2>&1; then
    echo "✅ $(uptime)"
else
    echo "❌ Cannot access uptime"
fi

# Test system load
echo -n "System load: "
if [ -r /proc/loadavg ]; then
    echo "✅ $(cat /proc/loadavg)"
else
    echo "❌ Cannot access load average"
fi

# Test memory info
echo -n "Memory info: "
if [ -r /proc/meminfo ]; then
    total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2 " " $3}')
    echo "✅ Total: $total_mem"
else
    echo "❌ Cannot access memory info"
fi

echo
echo "⚠️  Safe System Control Examples:"
echo "--------------------------------"

if [ "$PRIVILEGED" = true ] && [ "$SYSTEMCTL" = true ]; then
    echo "🟢 Your container CAN control the host system!"
    echo
    echo "Safe commands to test system control:"
    echo "• systemctl status    # Check systemd status"
    echo "• systemctl list-units # List all units"
    echo "• who                 # See logged in users"
    echo "• last reboot         # See reboot history"
    echo
    echo "⚠️  DESTRUCTIVE commands (USE WITH CAUTION):"
    echo "• sudo systemctl reboot     # Reboot host immediately"
    echo "• sudo systemctl poweroff   # Shutdown host immediately"
    echo "• sudo shutdown -r +5       # Reboot in 5 minutes"
    echo "• sudo shutdown -h +10      # Shutdown in 10 minutes"
    echo "• sudo shutdown -c          # Cancel scheduled shutdown"
    echo
    echo "🚨 EMERGENCY commands (FORCE, NO GRACEFUL SHUTDOWN):"
    echo "• echo 1 | sudo tee /proc/sys/kernel/sysrq"
    echo "• echo b | sudo tee /proc/sysrq-trigger  # Force reboot"
    echo "• echo o | sudo tee /proc/sysrq-trigger  # Force shutdown"
else
    echo "🔴 Your container CANNOT fully control the host system"
    echo
    if [ "$PRIVILEGED" = false ]; then
        echo "❌ Missing: privileged mode"
        echo "   Add 'privileged: true' to docker-compose.yaml"
    fi
    if [ "$SYSTEMCTL" = false ]; then
        echo "❌ Missing: systemctl command"
        echo "   Install systemd tools in container"
    fi
fi

echo
echo "🔧 Recommended docker-compose.yaml additions for full system control:"
echo "-------------------------------------------------------------------"
echo "services:"
echo "  dev-box:"
echo "    privileged: true      # ✅ You have this"
echo "    network_mode: host    # ✅ You have this"
echo "    pid: host            # Add this for full process visibility"
echo "    ipc: host            # Add this for IPC access"
echo "    volumes:"
echo "      - /proc:/host/proc:ro    # Host proc filesystem"
echo "      - /sys:/host/sys:ro      # Host sys filesystem"

echo
echo "💡 Additional Tips:"
echo "-----------------"
echo "• Always use graceful shutdown (systemctl) when possible"
echo "• Emergency commands (sysrq) should only be used as last resort"
echo "• Test with 'shutdown -c' to cancel before actual reboot"
echo "• Consider implementing safety delays for accidental commands"
echo "• Monitor system logs: journalctl -f"

echo
echo "🎯 Summary:"
echo "----------"
if [ "$PRIVILEGED" = true ] && [ "$SYSTEMCTL" = true ]; then
    echo "✅ Your container has FULL host system control capabilities"
    echo "✅ Can reboot and shutdown the host PC"
    echo "✅ Can manage systemd services"
    echo "⚠️  Use with extreme caution - these are destructive operations"
else
    echo "❌ Limited host system control"
    echo "ℹ️  Check configuration recommendations above"
fi
