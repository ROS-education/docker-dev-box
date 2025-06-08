# Linux Capabilities Configuration for Docker Dev-Box

This document explains how to configure Linux capabilities instead of using `privileged: true` for better security while maintaining necessary functionality.

## Current vs Capability-Based Configuration

### Current Configuration (Full Privileged)
```yaml
services:
  dev-box:
    privileged: true  # Grants ALL capabilities - security risk
```

### Capability-Based Configuration (Recommended)
```yaml
services:
  dev-box:
    # Remove privileged: true
    cap_add:
      - SYS_ADMIN      # Required for mount operations, some USB devices
      - SYS_PTRACE     # Required for debugging (gdb, strace)
      - NET_ADMIN      # Required for network configuration
      - NET_RAW        # Required for raw sockets, ping, packet capture
      - DAC_OVERRIDE   # Required for file permission overrides
      - SETUID         # Required for sudo operations
      - SETGID         # Required for group changes
      - SYS_CHROOT     # Required for chroot operations
      - MKNOD          # Required for device node creation
    cap_drop:
      - ALL            # Drop all capabilities first, then add only needed ones
```

## Linux Capabilities Explained

### Essential Capabilities for Dev Environment

1. **SYS_ADMIN** - Administrative operations
   - Mount/unmount filesystems
   - USB device management
   - System configuration changes

2. **SYS_PTRACE** - Process tracing
   - Debugging with gdb
   - Profiling applications
   - Process monitoring tools

3. **NET_ADMIN** - Network administration
   - Configure network interfaces
   - Manage routing tables
   - Firewall operations

4. **NET_RAW** - Raw network access
   - Raw sockets for ping
   - Packet capture with tcpdump
   - Network troubleshooting

5. **DAC_OVERRIDE** - File access override
   - Access files regardless of permissions
   - Required for some development operations

6. **SETUID/SETGID** - User/group switching
   - sudo operations
   - User impersonation for testing

### Optional Capabilities

7. **SYS_CHROOT** - Chroot environments
   - Build systems that use chroot
   - Container runtime operations

8. **MKNOD** - Device node creation
   - Creating device files
   - USB device hotplug support

9. **SYS_TIME** - Time management
   - Set system time (if needed)
   - Time-sensitive applications

10. **SYS_MODULE** - Kernel module management
    - Load/unload kernel modules
    - Hardware driver management

## Configuration Options

### Option 1: Minimal Capabilities (Most Secure)
```yaml
services:
  dev-box:
    cap_add:
      - SYS_PTRACE     # For debugging
      - NET_RAW        # For ping, network tools
      - DAC_OVERRIDE   # For file access
      - SETUID         # For sudo
      - SETGID         # For group changes
```

### Option 2: Development-Focused (Balanced)
```yaml
services:
  dev-box:
    cap_add:
      - SYS_ADMIN      # For USB and mount operations
      - SYS_PTRACE     # For debugging
      - NET_ADMIN      # For network configuration
      - NET_RAW        # For network tools
      - DAC_OVERRIDE   # For file access
      - SETUID         # For sudo
      - SETGID         # For group changes
      - MKNOD          # For device creation
```

### Option 3: Near-Privileged (Maximum Compatibility)
```yaml
services:
  dev-box:
    cap_add:
      - SYS_ADMIN
      - SYS_PTRACE
      - NET_ADMIN
      - NET_RAW
      - DAC_OVERRIDE
      - SETUID
      - SETGID
      - SYS_CHROOT
      - MKNOD
      - SYS_TIME
      - SYS_MODULE
```

## USB Device Access with Capabilities

For USB device access without full privileged mode:

```yaml
services:
  dev-box:
    cap_add:
      - SYS_ADMIN      # Required for USB device management
      - MKNOD          # Required for device node creation
    devices:
      - /dev/bus/usb:/dev/bus/usb  # USB device access
    volumes:
      - /dev:/dev:ro   # Read-only device access
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

## Security Comparison

| Configuration | Security Level | USB Access | Network Tools | Debugging | Docker Access |
|---------------|----------------|------------|---------------|-----------|---------------|
| `privileged: true` | ⚠️ Low | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| Minimal caps | 🔒 High | ❌ Limited | ⚠️ Basic | ✅ Yes | ✅ Yes |
| Development caps | 🔐 Medium | ✅ Good | ✅ Good | ✅ Full | ✅ Full |
| Near-privileged | ⚠️ Medium-Low | ✅ Full | ✅ Full | ✅ Full | ✅ Full |

## Implementation

1. **Create capability-based compose file:**
```bash
cp docker-compose.yaml docker-compose-caps.yaml
```

2. **Edit the new file** with your chosen capability configuration

3. **Test the configuration:**
```bash
docker compose -f docker-compose-caps.yaml up -d --build
```

4. **Validate functionality:**
```bash
docker exec -it dev_box /workspace/test-host-network.sh
docker exec -it dev_box /workspace/test-usb-access.sh
```

## Troubleshooting

### Common Issues and Solutions

1. **USB devices not accessible**
   - Add `SYS_ADMIN` capability
   - Ensure proper device mounts

2. **Network tools not working**
   - Add `NET_RAW` and `NET_ADMIN` capabilities

3. **Debugging fails**
   - Add `SYS_PTRACE` capability

4. **Permission denied errors**
   - Add `DAC_OVERRIDE` capability
   - Check file/directory ownership

5. **sudo not working**
   - Add `SETUID` and `SETGID` capabilities

### Testing Capabilities
```bash
# Test current capabilities
docker exec -it dev_box capsh --print

# Test specific functionality
docker exec -it dev_box ping google.com        # Requires NET_RAW
docker exec -it dev_box sudo whoami            # Requires SETUID
docker exec -it dev_box gdb --version          # Requires SYS_PTRACE
docker exec -it dev_box lsusb                  # Requires SYS_ADMIN (for USB)
```

## Recommendation

For development environments, use **Option 2 (Development-Focused)** as it provides:
- ✅ Good security posture
- ✅ Full development functionality  
- ✅ USB device access
- ✅ Network tools and debugging
- ⚠️ Only necessary capabilities

This approach reduces the attack surface significantly compared to `privileged: true` while maintaining all essential development functionality.
