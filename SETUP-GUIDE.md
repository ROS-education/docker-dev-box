# Docker Development Environment - Complete Setup Guide

This repository provides a comprehensive Docker-based development environment with Python (via Alpine packages), Node.js, development tools, VS Code integration, SSH access, and Docker-in-Docker capabilities.

## 🚀 Quick Start

### Prerequisites
- Docker Engine 20.10+ 
- Docker Compose 2.0+
- VS Code with Remote Development extensions (optional)

### 1. Initial Setup

```bash
# Clone or navigate to the project directory
cd /home/developer/DEV/docker-dev-box

# Set the Docker group ID for proper permissions
echo "HOST_DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 988)" > .env

# Build and start the container
docker-compose up -d

# Wait for services to start (about 30 seconds)
docker-compose logs -f
```

### 2. Verify Installation

```bash
# Run the comprehensive test suite
./test-environment.sh
```

## 🛠️ Development Environment Features

### Core Components
- **Base OS**: Alpine Linux 3.20 (lightweight and secure)
- **Python**: Alpine native Python 3.x with virtual environment
- **Node.js**: Alpine native Node.js 20+ with npm
- **Development Tools**: git, cmake, gdb, curl, wget, and more
- **Cloud Tools**: Google Cloud CLI, Firebase CLI
- **Container Access**: Docker-in-Docker via socket mounting
- **USB Support**: Full USB device access with proper group memberships

### Python Environment
- Virtual environment at `/opt/miniconda/envs/dev_env`
- Automatically activated in user sessions
- Pip package manager included
- Development packages pre-installed

### Node.js Environment
- Node.js 20+ from Alpine packages
- npm 10+ package manager
- Firebase CLI globally installed
- Full npm ecosystem access

## 🔌 Connection Methods

### Method 1: VS Code DevContainer (Recommended)
1. Open VS Code in the project directory
2. Install "Dev Containers" extension
3. Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
4. VS Code will build and connect automatically

### Method 2: VS Code Remote-SSH
1. Set up SSH keys: `./manage-ssh-keys.sh`
2. Connect to `ssh://developer@localhost:2222`
3. Password: `developer` (if not using keys)

### Method 3: Direct Container Access
```bash
# Interactive shell
docker exec -it dev_box bash

# As developer user
docker exec -it dev_box su - developer
```

## 🔧 Configuration

### Environment Variables (.env)
```bash
# Docker group ID (auto-detected)
HOST_DOCKER_GID=988

# Optional: Custom timezone
TZ=Asia/Bangkok
```

### Volume Mounts
- `Codespaces:/workspace` - Main workspace directory
- `config:/home/developer/.config` - User configuration
- `conda:/home/developer/.conda` - Python environment data
- `/var/run/docker.sock` - Docker-in-Docker access
- `/dev:/dev` - USB device access (when using --privileged)

### Port Mappings
- `2222` → SSH Server
- `3000` → Development server (Node.js/React)
- `8080` → Alternative development server
- `9000` → Additional service port

## 🐍 Python Development

### Environment Activation
```bash
# Automatically activated in new sessions
source /opt/miniconda/envs/dev_env/bin/activate

# Install packages
pip install numpy pandas matplotlib jupyter

# Run Python scripts
python your_script.py
```

### Jupyter Notebook
```bash
# Install Jupyter
pip install jupyter

# Start Jupyter server
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
```

## 🌐 Node.js Development

### Package Management
```bash
# Install dependencies
npm install

# Global packages
npm install -g create-react-app typescript

# Run development server
npm start
```

### Firebase Development
```bash
# Firebase CLI is pre-installed
firebase login
firebase init
firebase serve
```

## 🐳 Docker-in-Docker Usage

### Container Management
```bash
# Docker commands work inside the container
docker run hello-world
docker build -t my-app .
docker-compose up -d

# Access host Docker daemon
docker ps  # Shows host containers
```

### Security Note
The container shares the host's Docker daemon. Be cautious when:
- Running privileged containers
- Mounting host directories
- Pulling untrusted images

## 🔌 USB Device Access

### Full Access Mode (Privileged)
```bash
# Run with full USB access
docker-compose up -d
# Container runs with --privileged and /dev mount
```

### Specific Device Access
```bash
# For specific devices, modify docker-compose.yaml
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
  - /dev/ttyACM0:/dev/ttyACM0
```

### Testing USB Access
```bash
# List USB devices
lsusb

# Check permissions
ls -la /dev/tty*
groups  # Should include dialout, plugdev
```

## 🔐 SSH Key Management

### Generate SSH Keys
```bash
# Use the provided script
./manage-ssh-keys.sh

# Or manually
ssh-keygen -t ed25519 -f ~/.ssh/devbox_key
```

### Connect via SSH
```bash
# With key
ssh -i ~/.ssh/devbox_key -p 2222 developer@localhost

# With password
ssh -p 2222 developer@localhost
# Password: developer
```

## 🧪 Testing and Validation

### Run Test Suite
```bash
# Comprehensive environment testing
./test-environment.sh

# Specific tests
./test-conda-setup.sh
./test-usb-access.sh
```

### Manual Verification
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs

# Container resources
docker stats dev_box

# Python environment
docker exec dev_box su - developer -c "python --version"

# Node.js environment  
docker exec dev_box su - developer -c "node --version"
```

## 🐛 Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check Docker daemon
systemctl status docker

# Check compose file
docker-compose config

# View detailed logs
docker-compose logs --tail=50
```

#### SSH Connection Failed
```bash
# Check SSH service
docker exec dev_box supervisorctl status sshd

# Test SSH from container
docker exec dev_box ssh -p 22 developer@localhost

# Reset SSH keys
./manage-ssh-keys.sh --reset
```

#### Docker-in-Docker Issues
```bash
# Check Docker socket permissions
ls -la /var/run/docker.sock

# Verify group membership  
docker exec dev_box groups developer

# Check Docker group GID
getent group docker | cut -d: -f3
```

#### Python Environment Issues
```bash
# Verify virtual environment
docker exec dev_box ls -la /opt/miniconda/envs/

# Check activation
docker exec dev_box su - developer -c "which python"

# Reinstall if needed
docker-compose down
docker-compose build --no-cache
```

### Performance Optimization

#### Resource Limits
```yaml
# In docker-compose.yaml
services:
  dev-box:
    mem_limit: 4g
    cpus: '2.0'
```

#### Volume Performance
```bash
# Use bind mounts for better performance on specific directories
volumes:
  - ./src:/workspace/src:cached
```

## 📚 Additional Resources

### Documentation Files
- `ACCESS-METHODS.md` - Detailed connection methods
- `ALPINE-CONVERSION.md` - Alpine Linux migration notes
- `SSH-SETUP.md` - SSH configuration guide
- `REMOTE-SETUP.md` - Remote development setup

### Utility Scripts
- `manage-ssh-keys.sh` - SSH key management
- `setup-remote-pc.sh` - Remote PC configuration
- `transfer-to-remote.sh` - File transfer utilities

## 🤝 Contributing

### Development Workflow
1. Make changes to Dockerfile or configs
2. Test with `docker-compose build --no-cache`
3. Validate with `./test-environment.sh`
4. Document changes in appropriate files

### Adding New Tools
1. Update Dockerfile with package installation
2. Test compatibility with Alpine Linux
3. Update test scripts and documentation
4. Consider security implications

## 📄 License

This project is provided as-is for educational and development purposes.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review container logs: `docker-compose logs`
3. Run the test suite: `./test-environment.sh`
4. Verify your Docker/Docker Compose versions
