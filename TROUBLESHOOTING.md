# Troubleshooting Guide - Docker Development Environment

This guide helps you diagnose and fix common issues with the Docker development environment.

## 🔧 Quick Diagnostics

### Run All Validation Scripts
```bash
# Validate DevContainer configuration
./validate-devcontainer.sh

# Test complete environment
./test-environment.sh

# Check specific components
./test-conda-setup.sh
./test-usb-access.sh
```

## 🐳 Container Issues

### Container Won't Start

#### Symptom: `docker-compose up -d` fails
```bash
# Check Docker daemon status
sudo systemctl status docker
sudo systemctl start docker

# Check Docker Compose syntax
docker-compose config

# View detailed error logs
docker-compose up --no-detach

# Clean start
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

#### Symptom: Container exits immediately
```bash
# Check container logs
docker-compose logs dev-box

# Check supervisor logs
docker logs dev_box

# Common causes:
# 1. Supervisor configuration error
# 2. SSH key generation failure
# 3. Permission issues
```

### Build Issues

#### Symptom: Build fails during Python/Node.js installation
```bash
# Alpine package repository issues
docker build --no-cache --build-arg TARGETARCH=amd64 .

# Network connectivity issues during build
docker build --network=host .

# Clear build cache
docker builder prune -a
```

#### Symptom: Docker group permission errors
```bash
# Fix Docker GID in .env file
echo "HOST_DOCKER_GID=$(getent group docker | cut -d: -f3)" > .env

# Rebuild with correct GID
docker-compose build --build-arg HOST_DOCKER_GID=$(getent group docker | cut -d: -f3)
```

## 🔐 SSH Connection Issues

### SSH Connection Refused

#### Check SSH Service Status
```bash
# Inside container
docker exec dev_box supervisorctl status sshd

# Restart SSH service
docker exec dev_box supervisorctl restart sshd

# Check SSH configuration
docker exec dev_box cat /etc/ssh/sshd_config
```

#### SSH Port Issues
```bash
# Check if port 2222 is available
netstat -tulpn | grep 2222

# Use different port in docker-compose.yaml
ports:
  - "2223:22"  # Change to available port
```

### SSH Authentication Failed

#### Password Authentication
```bash
# Default credentials
# Username: developer
# Password: developer

# Reset password if needed
docker exec dev_box passwd developer
```

#### SSH Key Authentication
```bash
# Generate and install SSH keys
./manage-ssh-keys.sh

# Manual key setup
ssh-keygen -t ed25519 -f ~/.ssh/devbox_key
ssh-copy-id -i ~/.ssh/devbox_key.pub -p 2222 developer@localhost

# Connect with key
ssh -i ~/.ssh/devbox_key -p 2222 developer@localhost
```

## 🐍 Python Environment Issues

### Python Environment Not Found

#### Check Virtual Environment
```bash
# Verify environment exists
docker exec dev_box ls -la /opt/miniconda/envs/

# Check Python installation
docker exec dev_box which python3

# Test environment activation
docker exec dev_box su - developer -c "source /opt/miniconda/envs/dev_env/bin/activate && python --version"
```

#### Reinstall Python Environment
```bash
# Inside container as developer user
docker exec -it dev_box su - developer

# Create new environment
python3 -m venv /opt/miniconda/envs/dev_env
source /opt/miniconda/envs/dev_env/bin/activate
pip install --upgrade pip
```

### Package Installation Issues
```bash
# Permission issues
sudo chown -R developer:developer /opt/miniconda/

# Network issues
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org package_name

# Alpine package dependencies
sudo apk add --no-cache python3-dev gcc musl-dev
```

## 🌐 Node.js Issues

### Node.js Command Not Found

#### Check Node.js Installation
```bash
# Verify Node.js
docker exec dev_box which node
docker exec dev_box node --version

# Check npm
docker exec dev_box which npm
docker exec dev_box npm --version
```

#### Reinstall Node.js
```bash
# Inside container
docker exec -it dev_box apk add --no-cache nodejs npm

# Or rebuild container
docker-compose build --no-cache
```

### npm Permission Issues
```bash
# Fix npm permissions
docker exec dev_box chown -R developer:developer /home/developer/.npm

# Global package installation
docker exec dev_box su - developer -c "npm config set prefix ~/.local"
```

## 🐳 Docker-in-Docker Issues

### Docker Socket Permission Denied

#### Check Docker Socket Mount
```bash
# Verify socket mount
docker exec dev_box ls -la /var/run/docker.sock

# Check permissions
ls -la /var/run/docker.sock
```

#### Fix Group Permissions
```bash
# Get host Docker GID
getent group docker | cut -d: -f3

# Update .env file
echo "HOST_DOCKER_GID=$(getent group docker | cut -d: -f3)" > .env

# Rebuild container
docker-compose down
docker-compose build
docker-compose up -d
```

### Docker Commands Fail Inside Container
```bash
# Check Docker client installation
docker exec dev_box docker version

# Verify user group membership
docker exec dev_box groups developer

# Test Docker access
docker exec dev_box su - developer -c "docker ps"
```

## 🔌 USB Access Issues

### USB Devices Not Visible

#### Check Device Mounting
```bash
# Inside container
docker exec dev_box lsusb
docker exec dev_box ls -la /dev/tty*

# Host USB devices
lsusb
ls -la /dev/tty*
```

#### Fix USB Permissions
```bash
# Check user groups
docker exec dev_box groups developer

# Should include: dialout, plugdev, tty

# Fix if missing
docker exec dev_box adduser developer dialout
docker exec dev_box adduser developer plugdev
```

#### USB Device Access in Docker Compose
```yaml
# For full access (current setup)
privileged: true
volumes:
  - /dev:/dev

# For specific devices
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
  - /dev/ttyACM0:/dev/ttyACM0
```

## 🎨 VS Code Integration Issues

### DevContainer Won't Open

#### Check VS Code Extensions
1. Install "Dev Containers" extension
2. Install "Remote Development" extension pack

#### DevContainer Configuration Issues
```bash
# Validate configuration
./validate-devcontainer.sh

# Check JSON syntax
python3 -m json.tool .devcontainer/devcontainer.json
```

#### Container Build Issues in VS Code
```bash
# Build manually first
docker-compose build --no-cache

# Clear VS Code cache
# Command Palette → "Dev Containers: Rebuild Container"
```

### Remote-SSH Connection Issues

#### SSH Configuration
```bash
# VS Code SSH config (~/.ssh/config)
Host devbox
    HostName localhost
    Port 2222
    User developer
    IdentityFile ~/.ssh/devbox_key
```

#### SSH Agent Issues
```bash
# Start SSH agent
eval $(ssh-agent -s)
ssh-add ~/.ssh/devbox_key

# Test connection
ssh devbox
```

## 📊 Performance Issues

### Container Running Slowly

#### Check Resource Usage
```bash
# Container stats
docker stats dev_box

# Host resources
htop
df -h
```

#### Optimize Docker Compose
```yaml
services:
  dev-box:
    # Add resource limits
    mem_limit: 4g
    cpus: '2.0'
    
    # Optimize volume mounts
    volumes:
      - ./src:/workspace/src:cached
```

### High Memory Usage
```bash
# Check what's using memory
docker exec dev_box ps aux --sort=-%mem | head

# Supervisor processes
docker exec dev_box supervisorctl status

# Clean up if needed
docker exec dev_box apt-get clean
docker system prune -f
```

## 🔍 Debugging Steps

### Complete Environment Reset
```bash
# Stop everything
docker-compose down -v

# Remove images
docker rmi $(docker images -q "*dev*")

# Clean system
docker system prune -a

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d
```

### Debugging Container Startup
```bash
# Run container interactively
docker run -it --rm alpine:3.20 /bin/bash

# Check specific build stages
docker build --target <stage-name> .

# Debug supervisor
docker exec dev_box supervisorctl tail -f sshd
```

### Log Analysis
```bash
# Container logs
docker-compose logs --tail=100 dev-box

# Supervisor logs
docker exec dev_box ls -la /opt/supervisor/
docker exec dev_box cat /opt/supervisor/supervisord.log

# SSH logs
docker exec dev_box tail -f /var/log/auth.log
```

## 🆘 Getting Help

### Information to Collect
When reporting issues, include:

```bash
# System information
uname -a
docker --version
docker-compose --version

# Container status
docker-compose ps
docker-compose logs --tail=50

# Environment
cat .env
./validate-devcontainer.sh
```

### Common Commands for Support
```bash
# Full environment test
./test-environment.sh > test-results.txt 2>&1

# Configuration validation
./validate-devcontainer.sh > validation-results.txt 2>&1

# Container inspection
docker inspect dev_box > container-info.txt
```

## 📝 Prevention Tips

### Regular Maintenance
```bash
# Weekly cleanup
docker system prune -f

# Update base images
docker pull alpine:3.20

# Rebuild periodically
docker-compose build --pull
```

### Backup Important Data
```bash
# Export container volumes
docker run --rm -v dev-box_config:/source alpine tar czf - -C /source . > config-backup.tar.gz

# Backup SSH keys
cp -r ~/.ssh/devbox* ~/backups/
```

This troubleshooting guide covers the most common issues. For complex problems, consider rebuilding the container from scratch or checking the container logs for specific error messages.

## ✅ Double Virtual Environment Prompt (RESOLVED)

#### Symptom: `((dev_env) ) ((dev_env) )` instead of `(dev_env)`
```bash
# Example of the issue:
((dev_env) ) ((dev_env) ) developer@hostname:/workspace$
```

#### Cause
Multiple virtual environment activations from:
1. SSH environment variables (`VIRTUAL_ENV` in `.ssh/environment`)
2. Bash profile activation (`.bashrc` sourcing activate script)

#### ✅ Solution (IMPLEMENTED)
The Dockerfile has been updated to:
- ✅ Remove `VIRTUAL_ENV` from SSH environment
- ✅ Add conditional activation in `.bashrc` to prevent double activation
- ✅ Keep PATH properly configured for both SSH and interactive sessions

**Status**: This issue has been **FIXED** in the current version.

#### Manual Fix (if needed)
```bash
# Inside container, edit .bashrc
docker exec dev_box su - developer -c "
cat > ~/.bashrc << 'EOF'
# Activate dev_env Python environment by default (only if not already activated)
if [[ -z \"\$VIRTUAL_ENV\" ]]; then
    source /opt/miniconda/envs/dev_env/bin/activate
fi

# Helpful aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
EOF
"

# Edit SSH environment file
docker exec dev_box su - developer -c "
echo 'PATH=/opt/miniconda/bin:/opt/miniconda/envs/dev_env/bin:/home/developer/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' > ~/.ssh/environment
chmod 600 ~/.ssh/environment
"

# Restart container
docker-compose restart
```

#### Verification
```bash
# Test prompt fix
./test-prompt-fix.sh

# Manual verification via SSH
ssh -p 2222 developer@localhost
# Should show: (dev_env) developer@hostname:/workspace$
```
