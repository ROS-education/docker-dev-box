# Remote PC Setup Guide

This guide explains how to run and access your Docker development environment on a remote PC.

## Prerequisites

### On Remote PC
- Docker and Docker Compose installed
- SSH server running (for remote access)
- Firewall configured to allow necessary ports

### On Your Local Machine
- SSH client
- VS Code with Remote-SSH extension (optional)
- Web browser for code-server access

## Setup Steps

### 1. Transfer Files to Remote PC

**Option A: Using Automated Transfer Script (Recommended)**
```bash
# From your local machine
./transfer-to-remote.sh
```
This interactive script will:
- Guide you through the transfer process
- Set proper permissions
- Offer to automatically set up the environment
- Support both full dev-box and lightweight VS Code SSH setups

**Option B: Using Git**
```bash
# On remote PC
git clone <your-repository-url>
cd docker-dev-box
```

**Option C: Using SCP**
```bash
# From your local machine
scp -r /path/to/docker-dev-box user@remote-pc:/path/to/destination/
```

**Option D: Using rsync**
```bash
# From your local machine
rsync -avz --progress /path/to/docker-dev-box/ user@remote-pc:/path/to/destination/docker-dev-box/
```

### 2. Configure Environment on Remote PC

```bash
# SSH into remote PC
ssh user@remote-pc-ip

# Navigate to project directory
cd /path/to/docker-dev-box

# Create environment file
cp sample.env .env

# Set Docker group GID (important for Docker socket access)
echo "HOST_DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 988)" >> .env

# Make scripts executable
chmod +x *.sh
```

### 3. Configure Remote PC Firewall

```bash
# Allow code-server port (8443)
sudo ufw allow 8443/tcp

# Allow SSH container port (2222) 
sudo ufw allow 2222/tcp

# Optional: Allow SSH access to remote PC itself
sudo ufw allow ssh

# Enable firewall if not already enabled
sudo ufw --force enable
```

### 4. Start the Development Environment

```bash
# Build and start containers
docker-compose up --build -d

# Check status
docker-compose ps

# View logs if needed
docker-compose logs -f
```

## Access Methods

### Method 1: Code-Server (Web IDE)

Access the web-based VS Code from any browser:

```
https://remote-pc-ip:8443
```

**First-time setup:**
1. Accept the self-signed certificate warning
2. Enter password if prompted (check logs: `docker-compose logs dev-box | grep password`)

### Method 2: VS Code Remote-SSH

**Step 1: Set up SSH tunnel from local machine**
```bash
# Create SSH tunnel for code-server (optional)
ssh -L 8443:localhost:8443 -L 2222:localhost:2222 user@remote-pc-ip

# Keep this terminal open
```

**Step 2: Configure VS Code Remote-SSH**

Add to your local `~/.ssh/config`:

```
# Direct connection to container SSH
Host remote-dev-container
    HostName remote-pc-ip
    Port 2222
    User ubuntu
    ForwardAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 10

# Via SSH tunnel (alternative)
Host remote-dev-tunnel
    HostName localhost
    Port 2222
    User ubuntu
    ForwardAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 10
```

**Step 3: Connect with VS Code**
1. Open VS Code
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Type "Remote-SSH: Connect to Host"
4. Select `remote-dev-container` or `remote-dev-tunnel`
5. Enter password: `ubuntu` (default)

### Method 3: Direct SSH Access

```bash
# Direct SSH to container
ssh -p 2222 ubuntu@remote-pc-ip

# Or via tunnel
ssh -p 2222 ubuntu@localhost  # (after setting up tunnel)
```

## SSH Key Setup (Recommended)

Set up SSH keys for passwordless access:

```bash
# On remote PC, run the setup script
./setup-remote-ssh.sh setup-keys

# Or manually copy your public key
cat ~/.ssh/id_rsa.pub | docker exec -i dev_box tee -a /home/ubuntu/.ssh/authorized_keys
docker exec dev_box chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
docker exec dev_box chmod 600 /home/ubuntu/.ssh/authorized_keys
```

## Port Configuration

| Service | Container Port | Host Port | External Access |
|---------|----------------|-----------|-----------------|
| Code-Server (HTTPS) | 8443 | 8443 | https://remote-pc-ip:8443 |
| SSH to Container | 22 | 2222 | ssh -p 2222 ubuntu@remote-pc-ip |
| SSH to Remote PC | 22 | 22 | ssh user@remote-pc-ip |

## Security Considerations

### For Production Use:

1. **Change default passwords:**
   ```bash
   docker exec dev_box passwd ubuntu
   ```

2. **Use SSH keys only:**
   ```bash
   # Disable password authentication
   docker exec dev_box sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   docker exec dev_box supervisorctl restart sshd
   ```

3. **Configure firewall rules:**
   ```bash
   # Restrict access to specific IPs
   sudo ufw delete allow 8443/tcp
   sudo ufw delete allow 2222/tcp
   sudo ufw allow from your-local-ip to any port 8443
   sudo ufw allow from your-local-ip to any port 2222
   ```

4. **Use reverse proxy with SSL:**
   ```bash
   # Example with nginx
   sudo apt install nginx certbot python3-certbot-nginx
   # Configure nginx to proxy to localhost:8443
   # Setup Let's Encrypt SSL
   ```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker-compose logs dev-box

# Check Docker daemon
sudo systemctl status docker

# Rebuild if needed
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Can't Access from Outside
```bash
# Check if ports are listening
sudo netstat -tlnp | grep -E "(8443|2222)"

# Check firewall
sudo ufw status

# Check Docker port mapping
docker port dev_box
```

### SSH Connection Issues
```bash
# Test SSH connectivity
telnet remote-pc-ip 2222

# Check SSH service in container
docker exec dev_box supervisorctl status sshd

# Restart SSH service
docker exec dev_box supervisorctl restart sshd
```

### Code-Server Issues
```bash
# Check code-server service
docker exec dev_box supervisorctl status code-server

# View code-server logs
docker exec dev_box supervisorctl tail -f code-server

# Restart code-server
docker exec dev_box supervisorctl restart code-server
```

## Advanced Configuration

### Custom Domain Setup

1. **DNS Configuration:**
   - Point your domain to remote PC IP
   - Configure A record: `dev.yourdomain.com` → `remote-pc-ip`

2. **Reverse Proxy with SSL:**
   ```nginx
   # /etc/nginx/sites-available/dev-server
   server {
       listen 80;
       server_name dev.yourdomain.com;
       return 301 https://$server_name$request_uri;
   }

   server {
       listen 443 ssl;
       server_name dev.yourdomain.com;
       
       ssl_certificate /path/to/certificate.pem;
       ssl_certificate_key /path/to/private.key;
       
       location / {
           proxy_pass https://localhost:8443;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
           
           # WebSocket support
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
       }
   }
   ```

### Resource Monitoring

```bash
# Monitor container resources
docker stats dev_box

# Check system resources
htop
df -h
free -h
```

## Backup and Recovery

### Backup Data
```bash
# Backup volumes
docker run --rm -v docker-dev-box_config:/source -v /backup:/backup alpine tar czf /backup/config-backup.tar.gz -C /source .
docker run --rm -v docker-dev-box_conda:/source -v /backup:/backup alpine tar czf /backup/conda-backup.tar.gz -C /source .

# Backup workspace
tar czf workspace-backup.tar.gz /path/to/workspace
```

### Restore Data
```bash
# Restore volumes
docker run --rm -v docker-dev-box_config:/target -v /backup:/backup alpine tar xzf /backup/config-backup.tar.gz -C /target
docker run --rm -v docker-dev-box_conda:/target -v /backup:/backup alpine tar xzf /backup/conda-backup.tar.gz -C /target
```

## Performance Optimization

### For Remote Access:
1. **Use compression in SSH:**
   ```bash
   # Add to ~/.ssh/config
   Compression yes
   ```

2. **Optimize VS Code settings:**
   ```json
   {
       "remote.SSH.connectTimeout": 30,
       "remote.SSH.enableDynamicForwarding": false,
       "files.watcherExclude": {
           "**/node_modules/**": true
       }
   }
   ```

3. **Limit resource usage:**
   ```yaml
   # In docker-compose.yaml
   services:
     dev-box:
       mem_limit: 4g
       cpus: '2.0'
   ```

This setup provides a complete remote development environment accessible via web browser, VS Code Remote-SSH, or direct SSH access.
