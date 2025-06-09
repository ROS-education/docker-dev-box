# Host System Control from Docker Container

## Overview

With `privileged: true` and proper capabilities, your Docker container can control the host system, including reboot and shutdown operations.

## Methods to Reboot/Shutdown Host

### Method 1: Direct systemctl (Recommended)
```bash
# Shutdown host immediately
sudo systemctl poweroff

# Reboot host immediately  
sudo systemctl reboot

# Shutdown with delay
sudo shutdown -h +5 "System will shutdown in 5 minutes"

# Reboot with delay
sudo shutdown -r +10 "System will reboot in 10 minutes"

# Cancel scheduled shutdown
sudo shutdown -c
```

### Method 2: Traditional shutdown command
```bash
# Shutdown now
sudo shutdown -h now

# Reboot now
sudo shutdown -r now

# Shutdown in 30 minutes
sudo shutdown -h +30

# Reboot at specific time
sudo shutdown -r 23:30
```

### Method 3: Direct system calls (Advanced)
```bash
# Force immediate reboot (emergency only)
echo 1 | sudo tee /proc/sys/kernel/sysrq
echo b | sudo tee /proc/sysrq-trigger

# Force immediate shutdown (emergency only)
echo 1 | sudo tee /proc/sys/kernel/sysrq
echo o | sudo tee /proc/sysrq-trigger
```

### Method 4: Using reboot/halt commands
```bash
# Reboot
sudo reboot

# Shutdown
sudo halt
sudo poweroff
```

## Required Configuration

### 1. Privileged Mode (✅ You have this)
```yaml
services:
  dev-box:
    privileged: true  # Grants CAP_SYS_ADMIN and others
```

### 2. Host PID Namespace (Optional but recommended)
```yaml
services:
  dev-box:
    privileged: true
    pid: host  # Share host PID namespace
```

### 3. Host IPC Namespace (Optional)
```yaml
services:
  dev-box:
    privileged: true
    ipc: host  # Share host IPC namespace
```

## Testing Host Control Capabilities

Here's a test script to verify what system control you have:
