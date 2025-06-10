# Troubleshooting Guide

This guide covers common issues and their solutions when using docker-dev-box.

## Container Issues

### Container Won't Start

**Symptoms:** Container exits immediately or fails to start

**Solutions:**
```bash
# Check container logs
docker compose logs dev-box

# Check if ports are already in use
netstat -tuln | grep 2222

# Rebuild container
docker compose down
docker compose up --build -d
```

### Permission Errors with Docker Socket

**Symptoms:** "Permission denied" when using docker commands inside container

**Solutions:**
```bash
# Check your host docker group GID
getent group docker | cut -d: -f3

# Update .env file with correct GID
echo "HOST_DOCKER_GID=$(getent group docker | cut -d: -f3)" >> .env

# Rebuild container
docker compose down
docker compose up --build -d
```

## SSH Connection Issues

### Cannot Connect via SSH

**Symptoms:** "Connection refused" or timeout when connecting via SSH

**Solutions:**
```bash
# Check if container is running
docker compose ps

# Check if SSH service is running inside container
docker exec dev_box supervisorctl status sshd

# Check if port 2222 is listening
netstat -tuln | grep 2222

# Restart SSH service
docker exec dev_box supervisorctl restart sshd
```

### SSH Key Authentication Not Working

**Symptoms:** SSH keys not accepted, falls back to password

**Solutions:**
```bash
# Check SSH key permissions on host
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# Copy SSH key to container
ssh-copy-id -p 2222 ubuntu@localhost

# Check SSH configuration in container
docker exec dev_box cat /etc/ssh/sshd_config | grep -E "(PubkeyAuthentication|AuthorizedKeysFile)"
```

## Architecture Issues

### Wrong Architecture Image

**Symptoms:** "exec format error" or performance issues

**Solutions:**
```bash
# Check your system architecture
uname -m

# For AMD64 systems
docker pull wn1980/dev-box:amd64

# For ARM64 systems (Apple Silicon, etc.)
docker pull wn1980/dev-box:arm64

# Update docker-compose.yaml with correct image
# Edit image line to match your architecture
```

### Build Fails on ARM64

**Symptoms:** Build fails with package not found errors

**Solutions:**
```bash
# Use the ARM64-specific build script
./scripts/build-arm64-complete.sh

# Or use multi-arch build
./scripts/build-multiarch.sh --platform arm64
```

## Network Issues

### Host Network Not Working

**Symptoms:** Cannot access host services from container

**Solutions:**
```bash
# Ensure host networking is enabled
grep "network_mode: host" docker-compose.yaml

# Check if container can reach host services
docker exec dev_box ping host.docker.internal

# Test network connectivity
docker exec dev_box curl http://localhost:80
```

### Port Conflicts

**Symptoms:** Port already in use errors

**Solutions:**
```bash
# Check what's using port 2222
sudo lsof -i :2222

# Stop conflicting services
sudo systemctl stop <service-name>

# Or use different ports in docker-compose.yaml
```

## Volume Issues

### Data Not Persisting

**Symptoms:** Files disappear after container restart

**Solutions:**
```bash
# Check volume mounts
docker inspect dev_box | grep -A 10 "Mounts"

# Verify volumes exist
docker volume ls | grep dev-box

# Recreate volumes if needed
docker compose down -v
docker compose up -d
```

### Permission Issues with Volumes

**Symptoms:** Cannot write to mounted directories

**Solutions:**
```bash
# Check volume permissions
docker exec dev_box ls -la /workspace

# Fix ownership if needed
docker exec dev_box chown -R ubuntu:ubuntu /workspace
```

## Performance Issues

### Slow File Operations

**Symptoms:** File operations are very slow

**Solutions:**
```bash
# For macOS users, use cached or delegated volumes
# Edit docker-compose.yaml volume mounts:
# - ./workspace:/workspace:cached

# For Linux users, check if SELinux is interfering
getenforce
# If enforcing, add :z to volume mounts
# - ./workspace:/workspace:z
```

### High CPU Usage

**Symptoms:** Container uses excessive CPU

**Solutions:**
```bash
# Check running processes
docker exec dev_box top

# Limit CPU usage in docker-compose.yaml
# Add under dev-box service:
# cpus: '2.0'
# mem_limit: 4g
```

## Development Environment Issues

### Conda Environment Not Working

**Symptoms:** Python packages not found or wrong Python version

**Solutions:**
```bash
# Check conda installation
docker exec dev_box conda --version

# Activate dev_env
docker exec dev_box bash -c "source /opt/miniconda/etc/profile.d/conda.sh && conda activate dev_env && python --version"

# Reinstall conda environment
docker exec dev_box bash -c "conda env remove -n dev_env && conda env create -f environment.yml"
```

### VS Code Extensions Not Working

**Symptoms:** Extensions don't work in Remote-SSH

**Solutions:**
```bash
# Check VS Code server installation
docker exec dev_box ls -la ~/.vscode-server

# Clear VS Code server cache
docker exec dev_box rm -rf ~/.vscode-server

# Reconnect with VS Code Remote-SSH
```

## Getting Help

If you're still experiencing issues:

1. Check the [GitHub Issues](https://github.com/your-repo/docker-dev-box/issues)
2. Run the validation script: `./tests/validate-complete-setup.sh`
3. Provide the output of:
   ```bash
   docker --version
   docker compose version
   uname -a
   docker compose logs dev-box
   ```

## Advanced Debugging

### Enable Debug Logging

```bash
# Enable SSH debug logging
docker exec dev_box sed -i 's/#LogLevel INFO/LogLevel DEBUG/' /etc/ssh/sshd_config
docker exec dev_box supervisorctl restart sshd

# Enable supervisor debug logging
docker exec dev_box sed -i 's/loglevel=info/loglevel=debug/' /opt/supervisor/supervisord.conf
docker compose restart
```

### Container Inspection

```bash
# Get detailed container information
docker inspect dev_box

# Check container resource usage
docker stats dev_box

# Access container filesystem
docker exec -it dev_box bash
```
