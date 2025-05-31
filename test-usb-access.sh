#!/bin/bash
# Test USB device access within the container

echo "=== USB Device Access Test ==="
echo

echo "1. Testing lsusb command:"
if command -v lsusb >/dev/null 2>&1; then
    lsusb
    echo "✓ lsusb command available"
else
    echo "✗ lsusb command not found"
fi
echo

echo "2. Testing USB device files access:"
if [ -d "/dev/bus/usb" ]; then
    echo "✓ /dev/bus/usb directory exists"
    echo "USB bus directories:"
    ls -la /dev/bus/usb/
else
    echo "✗ /dev/bus/usb directory not found"
fi
echo

echo "3. Testing serial device access:"
if ls /dev/ttyUSB* >/dev/null 2>&1; then
    echo "✓ USB serial devices found:"
    ls -la /dev/ttyUSB*
else
    echo "ℹ No USB serial devices (/dev/ttyUSB*) found"
fi

if ls /dev/ttyACM* >/dev/null 2>&1; then
    echo "✓ ACM devices found:"
    ls -la /dev/ttyACM*
else
    echo "ℹ No ACM devices (/dev/ttyACM*) found"
fi
echo

echo "4. Testing user group memberships:"
echo "Current user: $(whoami)"
echo "Groups: $(groups)"
echo

echo "5. Testing device permissions:"
echo "Checking permissions for common device paths:"
[ -e "/dev/bus" ] && echo "/dev/bus: $(ls -ld /dev/bus)"
[ -e "/dev/tty" ] && echo "/dev/tty: $(ls -ld /dev/tty)"
echo

echo "6. Testing udev rules:"
if [ -f "/etc/udev/rules.d/99-usb-permissions.rules" ]; then
    echo "✓ USB udev rules file exists:"
    cat /etc/udev/rules.d/99-usb-permissions.rules
else
    echo "✗ USB udev rules file not found"
fi
echo

echo "=== End of USB Access Test ==="
