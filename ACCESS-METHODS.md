# Access Methods Summary

This document provides a quick reference for all the ways you can access and use this Docker development environment.

## 🏠 Local Usage

### Method 1: Web Browser (Code-Server)
```bash
# Start the container
docker-compose up -d

# Access in browser
https://localhost:8443
```
- **Pros:** Works from any device with a browser, no software installation needed
- **Cons:** Some VS Code features may be limited compared to desktop VS Code

### Method 2: VS Code Remote-Containers
```bash
# Open in VS Code with Remote-Containers extension
code .
# Then: Ctrl+Shift+P → "Remote-Containers: Reopen in Container"
```
- **Pros:** Full VS Code experience with all features
- **Cons:** Requires VS Code and Remote-Containers extension

### Method 3: Direct SSH to Container
```bash
# Start container and SSH into it
docker-compose up -d
ssh -p 2222 ubuntu@localhost
```
- **Pros:** Direct command-line access, good for terminal-heavy work
- **Cons:** No GUI, requires SSH client

## 🌐 Remote PC Usage

### Method 1: Web Browser Access
```bash
# On remote PC
./setup-remote-pc.sh

# From any device
https://remote-pc-ip:8443
```
- **Pros:** Access from anywhere, any device, no software needed
- **Cons:** Requires HTTPS certificate handling, some features limited

### Method 2: VS Code Remote-SSH
```bash
# Add to ~/.ssh/config on local machine
Host remote-dev
    HostName remote-pc-ip
    Port 2222
    User ubuntu

# Connect via VS Code Remote-SSH extension
```
- **Pros:** Full VS Code experience, best performance, all features available
- **Cons:** Requires VS Code and Remote-SSH extension on local machine

### Method 3: SSH with Port Forwarding
```bash
# Create SSH tunnel for code-server
ssh -L 8443:localhost:8443 -L 2222:localhost:2222 user@remote-pc-ip

# Then access via localhost:8443 or localhost:2222
```
- **Pros:** Secure tunneled connection, can use local browser/VS Code
- **Cons:** Requires maintaining SSH connection

### Method 4: Direct SSH to Remote Container
```bash
ssh -p 2222 ubuntu@remote-pc-ip
```
- **Pros:** Direct access, good for command-line work
- **Cons:** No GUI, requires proper firewall configuration

## 📱 Lightweight Alternative (Resource-Constrained Devices)

### VS Code SSH Container (Raspberry Pi, etc.)
```bash
./run-vscode-ssh.sh
```
- **Access:** VS Code Remote-SSH only (no web interface)
- **Pros:** Minimal resource usage, full hardware access including USB
- **Cons:** Requires VS Code with Remote-SSH extension

## 🔐 Authentication Methods

| Access Method | Default Auth | Recommended for Production |
|---------------|--------------|----------------------------|
| Code-Server Web | None (`--auth none`) | Password or OAuth |
| SSH to Container | Password: `ubuntu` | SSH keys |
| VS Code Remote-SSH | SSH password/keys | SSH keys only |

## 🚀 Quick Start Commands

### Local Development
```bash
# Full setup
docker-compose up -d --build
open https://localhost:8443

# OR with VS Code
code .  # Then reopen in container
```

### Remote PC Setup
```bash
# Automated transfer and setup
./transfer-to-remote.sh

# Manual setup
cp sample.env .env
echo "HOST_DOCKER_GID=$(getent group docker | cut -d: -f3)" >> .env
docker-compose up -d --build
```

### SSH Key Setup (Any method)
```bash
# Automated
./setup-remote-ssh.sh setup-keys

# Manual
ssh-copy-id -p 2222 ubuntu@target-host
```

## 🔧 Environment Features

All access methods provide:
- **Conda Environment:** `dev_env` with Python 3.12, Node.js 22
- **Development Tools:** CMake, GCC, GDB, Git
- **Cloud Tools:** Firebase CLI, Google Cloud SDK, ngrok
- **Docker Access:** Host Docker daemon via socket mount
- **AI Assistant:** Google Gemini integration in VS Code
- **Persistent Storage:** Projects, configs, and conda environments

## 📊 Performance Comparison

| Method | Resource Usage | Features | Best For |
|--------|----------------|----------|----------|
| Code-Server Web | High | 90% VS Code | Remote access, any device |
| Remote-Containers | Medium | 100% VS Code | Local development |
| Remote-SSH | Low | 100% VS Code | Remote development |
| SSH Direct | Very Low | CLI only | Server management |
| VS Code SSH Container | Minimal | 100% VS Code | Resource-constrained devices |

## 🛠️ Troubleshooting Quick Reference

### Container Won't Start
```bash
docker-compose logs dev-box
docker system prune -f
docker-compose build --no-cache
```

### Can't Connect Remotely
```bash
# Check firewall
sudo ufw status
sudo ufw allow 8443/tcp
sudo ufw allow 2222/tcp

# Check if ports are listening
sudo netstat -tlnp | grep -E "(8443|2222)"
```

### Conda Environment Issues
```bash
# SSH into container and check
docker exec -it dev_box bash
conda env list
which python
echo $CONDA_DEFAULT_ENV
```

### VS Code Remote-SSH Issues
```bash
# Test SSH connection
ssh -p 2222 ubuntu@target-host 'echo "Connected successfully"'

# Check SSH service in container
docker exec dev_box supervisorctl status sshd
```

Choose the access method that best fits your needs:
- **Local development:** Remote-Containers or Code-Server web
- **Remote development:** VS Code Remote-SSH
- **Server management:** Direct SSH
- **Resource-constrained:** VS Code SSH container
- **Any device access:** Code-Server web interface
