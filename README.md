# Docker Development Environment (DEV-BOX)

A comprehensive Alpine Linux-based Docker development environment with Python, Node.js, development tools, VS Code integration, SSH access, and Docker-in-Docker capabilities. Optimized for lightweight performance and security.

## ✨ Features

### 🏔️ **Alpine Linux Foundation**
*   **Lightweight Base:** Built on Alpine Linux 3.20 for minimal footprint and enhanced security
*   **musl libc:** Native Alpine packages for better compatibility and performance
*   **Package Security:** Regular security updates from Alpine's hardened package repository

### 🐍 **Python Development Environment**
*   **Native Python:** Alpine-native Python 3.x with virtual environment support
*   **Virtual Environment:** Pre-configured development environment at `/opt/miniconda/envs/dev_env`
*   **Package Management:** pip with all essential development packages
*   **Auto-activation:** Python environment automatically activated in all user sessions

### 🌐 **Node.js Development Stack**
*   **Node.js 20+:** Latest LTS version from Alpine packages
*   **npm 10+:** Modern package manager with global tool support
*   **Firebase CLI:** Pre-installed for Firebase development
*   **Development Tools:** Full npm ecosystem access

### 🛠️ **Development Tools Suite**
*   **Build Tools:** cmake, make, gcc, clang, gdb
*   **Version Control:** git with full functionality
*   **Cloud Tools:** Google Cloud CLI, Firebase CLI
*   **System Tools:** curl, wget, rsync, openssh
*   **USB Support:** Full USB device access with proper permissions

### 🐳 **Docker-in-Docker Integration**
*   **Host Docker Access:** Shares host Docker daemon via socket mounting
*   **Container Management:** Full docker and docker-compose functionality
*   **Security:** Proper group permissions for safe Docker access
*   **Multi-platform:** Supports both AMD64 and ARM64 architectures

### 🔐 **Multiple Access Methods**
*   **VS Code DevContainer:** Native VS Code integration with automatic setup
*   **Remote-SSH:** VS Code Remote-SSH support with configured SSH server
*   **Direct Access:** Direct container shell access for command-line work
*   **Secure SSH:** Password and key-based authentication support

### 🔌 **USB Device Support**
*   **Full USB Access:** Complete USB device access in privileged mode
*   **Device Groups:** User added to dialout, plugdev, and tty groups
*   **udev Rules:** Proper device permissions for development hardware
*   **Serial Devices:** Support for Arduino, microcontrollers, and serial interfaces

### 👤 **User Management**
*   **Developer User:** Non-root user (UID 1000) with sudo access
*   **Secure Permissions:** Proper file ownership and group memberships
*   **SSH Configuration:** Pre-configured SSH server with key support
*   **Environment Setup:** Customized bash environment with aliases and completion

## 🚀 Quick Start

### Prerequisites
*   Docker Engine 20.10+ or Docker Desktop
*   Docker Compose 2.0+
*   VS Code with Remote Development extensions (optional)

### 1. **Initial Setup**
```bash
# Navigate to project directory
cd /home/developer/DEV/docker-dev-box

# Configure Docker group permissions
echo "HOST_DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 988)" > .env

# Build and start the container
docker-compose up -d

# Wait for services to initialize (30-60 seconds)
docker-compose logs -f
```

### 2. **Verify Installation** 
```bash
# Run comprehensive test suite
./test-environment.sh

# Validate DevContainer configuration
./validate-devcontainer.sh
```

### 3. **Connect to Environment**

#### Option A: VS Code DevContainer (Recommended)
1. Open VS Code in the project directory
2. Install "Dev Containers" extension
3. Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
4. VS Code builds and connects automatically

#### Option B: VS Code Remote-SSH
```bash
# Set up SSH keys
./manage-ssh-keys.sh

# Connect via Remote-SSH
# Host: localhost, Port: 2222, User: developer
```

#### Option C: Direct Shell Access
```bash
# Interactive shell as developer user
docker exec -it dev_box su - developer

# Or quick command execution
docker exec dev_box su - developer -c "python --version"
```

## 📋 Environment Specifications

### System Architecture
*   **Base Image:** Alpine Linux 3.20
*   **Container Size:** ~2.6GB (optimized)
*   **User:** developer (UID 1000, GID 1000)
*   **Shell:** bash with completion and history
*   **Process Manager:** supervisor for service management

### Python Stack
*   **Python Version:** 3.x (Alpine native)
*   **Virtual Environment:** `/opt/miniconda/envs/dev_env`
*   **Package Manager:** pip (latest)
*   **Pre-installed Packages:** Development essentials

### Node.js Stack
*   **Node.js Version:** 20+ LTS
*   **Package Manager:** npm 10+
*   **Global Tools:** Firebase CLI
*   **Environment:** Full npm ecosystem support

### Development Tools
```bash
# Build & Compilation
cmake, make, gcc, clang, gdb

# Version Control
git

# Cloud Development
gcloud CLI, Firebase CLI

# Network & Transfer
curl, wget, rsync, openssh

# USB & Hardware
usbutils, libusb-dev, eudev-dev
```

### Container Ports
*   **2222:** SSH Server (Remote-SSH access)
*   **3000:** Development server (React/Node.js)
*   **8080:** Alternative development port
*   **9000:** Additional service port

### Volume Mounts
*   **Codespaces:** Main workspace directory (`/workspace`)
*   **config:** User configuration (`/home/developer/.config`)
*   **conda:** Python environment data (`/home/developer/.conda`)
*   **Docker Socket:** Docker-in-Docker access (`/var/run/docker.sock`)
*   **USB Devices:** Hardware access (`/dev` in privileged mode)
## 💻 Development Workflows

### Python Development
```bash
# Activate environment (auto-activated in new shells)
source /opt/miniconda/envs/dev_env/bin/activate

# Install packages
pip install numpy pandas matplotlib jupyter

# Run Python scripts
python app.py

# Jupyter notebook server
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser
```

### Node.js Development
```bash
# Package management
npm install express react

# Global tools
npm install -g create-react-app typescript nodemon

# Development server
npm start

# Firebase development
firebase login
firebase init
firebase serve
```

### Docker-in-Docker Usage
```bash
# Container management
docker run hello-world
docker build -t my-app .
docker-compose up -d

# Access host Docker
docker ps  # Shows host containers
docker images  # Shows host images
```

### USB Device Development
```bash
# List USB devices
lsusb

# Access serial devices
ls -la /dev/tty*

# Arduino/microcontroller development
# Devices auto-accessible via dialout group
```

## 🔧 Configuration & Customization

### Environment Variables (.env)
```bash
# Docker group ID (required for Docker-in-Docker)
HOST_DOCKER_GID=988

# Optional: Custom timezone
TZ=Asia/Bangkok

# Optional: Custom architecture
TARGETARCH=amd64
```

### Custom Package Installation
```bash
# System packages (as root)
docker exec dev_box apk add --no-cache package-name

# Python packages (as developer)
docker exec dev_box su - developer -c "pip install package-name"

# Node.js packages (as developer)
docker exec dev_box su - developer -c "npm install -g package-name"
```

### SSH Key Setup
```bash
# Generate and configure SSH keys
./manage-ssh-keys.sh

# Manual SSH key setup
ssh-keygen -t ed25519 -f ~/.ssh/devbox_key
ssh-copy-id -i ~/.ssh/devbox_key.pub -p 2222 developer@localhost
```

### VS Code Extensions
Add extensions to `.devcontainer/devcontainer.json`:
```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-vscode.vscode-docker",
        "your-extension-id"
      ]
    }
  }
}
```

## 🧪 Testing & Validation

### Run Test Suites
```bash
# Complete environment validation
./test-environment.sh

# DevContainer configuration check
./validate-devcontainer.sh

# Specific component tests
./test-conda-setup.sh
./test-usb-access.sh
```

### Manual Testing
```bash
# Container status
docker-compose ps
docker stats dev_box

# Service health
docker exec dev_box supervisorctl status

# Environment verification
docker exec dev_box su - developer -c "python --version && node --version"
```

## 📚 Documentation

### Comprehensive Guides
- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Complete setup and usage instructions
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **[ACCESS-METHODS.md](ACCESS-METHODS.md)** - All connection methods explained

### Migration & Conversion
- **[ALPINE-CONVERSION.md](ALPINE-CONVERSION.md)** - Ubuntu to Alpine migration notes
- **[REMOTE-SETUP.md](REMOTE-SETUP.md)** - Remote development setup

### Specialized Topics
- **[SSH-SETUP.md](SSH-SETUP.md)** - SSH configuration details
- **[REMOTE-WORKFLOW.md](REMOTE-WORKFLOW.md)** - Remote development workflows

## 🔍 Architecture Overview

### Container Architecture
```
┌─────────────────────────────────────────┐
│ Alpine Linux 3.20 Container            │
├─────────────────────────────────────────┤
│ Supervisor (Process Manager)            │
│ ├── SSH Server (Port 22)               │
│ └── (code-server disabled)             │
├─────────────────────────────────────────┤
│ Development Environment                 │
│ ├── Python 3.x + Virtual Environment   │
│ ├── Node.js 20+ + npm                  │
│ ├── Development Tools (git, cmake, etc)│
│ └── Cloud Tools (gcloud, firebase)     │
├─────────────────────────────────────────┤
│ User: developer (UID 1000)             │
│ ├── Groups: docker, dialout, plugdev   │
│ ├── Home: /home/developer              │
│ └── Workspace: /workspace              │
├─────────────────────────────────────────┤
│ Volume Mounts                           │
│ ├── /workspace (Codespaces volume)     │
│ ├── /home/developer/.config            │
│ ├── /var/run/docker.sock (Docker)      │
│ └── /dev (USB devices, privileged)     │
└─────────────────────────────────────────┘
```

### Network Ports
- **2222**: SSH Server (Remote-SSH, direct SSH)
- **3000**: Development server (React, Node.js)
- **8080**: Alternative development port
- **9000**: Additional service port

## 🛡️ Security Considerations

### Container Security
- **Non-root User**: Development work runs as `developer` user
- **Privilege Separation**: Only necessary services run as root
- **Alpine Hardening**: Built on security-focused Alpine Linux
- **Regular Updates**: Based on maintained Alpine base image

### Docker-in-Docker Security
- **Socket Mounting**: Shares host Docker daemon (be cautious with images)
- **Group Permissions**: Proper GID matching for secure access
- **No Privileged Docker**: Container itself doesn't run Docker daemon

### SSH Security
- **Key Authentication**: SSH key support for secure access
- **Password Policy**: Default password should be changed for production
- **Port Mapping**: SSH on non-standard port (2222)

## 🚀 Performance Optimization

### Resource Management
```yaml
# docker-compose.yaml optimizations
services:
  dev-box:
    mem_limit: 4g      # Adjust based on available RAM
    cpus: '2.0'        # Limit CPU usage
    shm_size: 512m     # Shared memory for large builds
```

### Volume Performance
```yaml
# For better I/O on specific directories
volumes:
  - ./src:/workspace/src:cached
  - ./build:/workspace/build:delegated
```

### Alpine Optimizations
- **Package Cache**: `apk add --no-cache` prevents cache buildup
- **Multi-stage Build**: Minimizes final image size
- **Static Linking**: Alpine's musl libc provides smaller binaries

## 🤝 Contributing

### Development Guidelines
1. **Test Changes**: Always run `./test-environment.sh` after modifications
2. **Documentation**: Update relevant documentation files
3. **Compatibility**: Ensure Alpine Linux compatibility
4. **Security**: Follow security best practices

### Adding New Features
1. **Package Installation**: Add to Dockerfile with `apk add --no-cache`
2. **Service Management**: Add supervisor configuration if needed
3. **Testing**: Create corresponding test scripts
4. **Documentation**: Update guides and README

## 📄 License

This project is provided as-is for educational and development purposes. Feel free to modify and distribute according to your needs.

## 🆘 Support

For issues and questions:
1. **Check Documentation**: Review the comprehensive guides
2. **Run Diagnostics**: Use `./test-environment.sh` and `./validate-devcontainer.sh`
3. **Check Logs**: `docker-compose logs` for container issues
4. **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Built with Alpine Linux for efficiency, security, and performance.**

