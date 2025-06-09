# SSH Remote Development Setup

This Docker container includes SSH server support for VS Code Remote-SSH development.

## Quic### Reset SSH Keys
```bash
./setup-remote-ssh.sh reset-keys
```

### Conda Environment Issues

If conda environment is not activated properly in VS Code Remote-SSH:

```bash
# Check if conda is in PATH
which conda

# Manually source conda setup
source /opt/miniconda/etc/profile.d/conda.sh

# Activate dev_env manually
conda activate dev_env

# Check environment variables
env | grep CONDA

# Verify SSH environment file
cat ~/.ssh/environment
```

**Fix SSH environment loading:**
```bash
# If environment is not loading, check SSH config
docker exec dev_box grep -i PermitUserEnvironment /etc/ssh/sshd_config

# Should return: PermitUserEnvironment yes
```

### Container Access
```bash
# Access container directly
docker exec -it dev_box bash

# Check running services
docker exec dev_box supervisorctl status
```*Start the container:**
   ```bash
   docker-compose up -d
   ```

2. **Set up SSH keys:**
   ```bash
   ./setup-remote-pc.sh ssh
   ```

3. **Test the connection:**
   ```bash
   ssh -p 2222 ubuntu@localhost 'echo "SSH connection successful!"'
   ```

4. **Get VS Code configuration:**
   ```bash
   # Manual configuration for VS Code Remote-SSH
   # Add to ~/.ssh/config:
   Host docker-dev-box
       HostName localhost
       Port 2222
       User ubuntu
       ForwardAgent yes
   ```

## Connection Details

- **Host:** localhost
- **Port:** 2222
- **User:** ubuntu
- **Password:** ubuntu (default - change in production!)

## VS Code Remote-SSH Setup

1. Install the "Remote - SSH" extension in VS Code
2. Add this configuration to `~/.ssh/config`:

```
Host docker-dev-box
    HostName localhost
    Port 2222
    User ubuntu
    ForwardAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 10
```

3. In VS Code:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Type "Remote-SSH: Connect to Host"
   - Select "docker-dev-box"

## Available Tools in SSH Session

- **Conda Environment:** `dev_env` (auto-activated for all sessions)
- **Languages:** Python 3.12, Node.js 22
- **Build Tools:** CMake, GCC, GDB
- **Cloud Tools:** Firebase CLI, Google Cloud SDK, ngrok
- **Docker:** Access to host Docker daemon

### Conda Environment Details

The `dev_env` conda environment is automatically activated for both interactive and non-interactive SSH sessions, including VS Code Remote-SSH connections. The environment includes:

- Python 3.12 with development tools
- Node.js 22 with npm
- Build essentials (cmake, gcc, gdb)

If the environment doesn't activate automatically, you can manually activate it:
```bash
conda activate dev_env
```

### Environment Verification

Check your current environment:
```bash
# Check active conda environment
echo $CONDA_DEFAULT_ENV

# Check Python version
python --version

# Check Node.js version
node --version

# List all conda environments
conda env list
```

## Commands

### SSH Connection
```bash
ssh -p 2222 ubuntu@localhost
```

### File Transfer (SCP)
```bash
# Upload file
scp -P 2222 local-file.txt ubuntu@localhost:/workspace/

# Download file
scp -P 2222 ubuntu@localhost:/workspace/remote-file.txt ./
```

### File Transfer (SFTP)
```bash
sftp -P 2222 ubuntu@localhost
```

## Troubleshooting

### SSH Connection Issues
```bash
# Check SSH service status
docker exec dev_box supervisorctl status sshd

# Check SSH logs
docker exec dev_box journalctl -u ssh

# Restart SSH service
docker exec dev_box supervisorctl restart sshd
```

### Reset SSH Keys
```bash
./setup-remote-ssh.sh reset-keys
```

### Container Access
```bash
# Access container directly
docker exec -it dev_box bash

# Check running services
docker exec dev_box supervisorctl status
```

## Security Notes

⚠️ **Important for Production:**

1. **Change default password:**
   ```bash
   docker exec dev_box passwd ubuntu
   ```

2. **Disable password authentication** (use keys only):
   ```bash
   docker exec dev_box sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   docker exec dev_box supervisorctl restart sshd
   ```

3. **Use non-standard ports** in production environments

4. **Consider firewall rules** to restrict SSH access

## Workspace Structure

- **`/workspace`** - Main development directory (mounted volume)
- **`/home/ubuntu`** - User home directory
- **`/home/ubuntu/.config`** - VS Code and app configurations (mounted volume)
- **`/home/ubuntu/.conda`** - Conda environments (mounted volume)

## Environment Variables

The following environment variables are available in SSH sessions:

- `PATH` includes conda and local bins
- `CONDA_EXE` points to conda executable
- Default conda environment `dev_env` is activated

## Port Mapping

# Port 22 used for SSH access
- **2222** → SSH Server
- **22** → SSH Server (inside container)
