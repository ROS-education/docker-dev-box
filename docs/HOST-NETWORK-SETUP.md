# Host Network Configuration

This guide explains how to configure the dev-box container to use host networking for maximum integration with the host system.

## Overview

Host networking (`network_mode: host`) allows the container to use the host's network stack directly, providing:

- **Direct access to host network interfaces**
- **No port mapping needed** - services bind to host ports directly
- **Better network performance** - no NAT overhead
- **Access to host network configuration and routes**
- **Can bind to specific host network interfaces**
- **Access to localhost services running on host**

## Current Configuration

The `docker-compose.yaml` file is already configured with `network_mode: host`. This means:

- **SSH Server**: Available on port 2222
- **All network services**: Use host networking directly

## Security Considerations

⚠️ **Important Security Notes:**

1. **SSH Port Conflict**: The container SSH server will try to bind to port 22. If your host already runs SSH on port 22, you'll need to change one of them.

2. **Direct Host Access**: Services in the container can access localhost services on the host.

3. **Network Visibility**: The container's network services are directly accessible from the network the host is connected to.

## Configuration Options

### Option 1: Use Host Networking (Current Default)

```yaml
services:
  dev-box:
    network_mode: host
    # No port mapping needed
```

**Access:**
- SSH: `ssh ubuntu@<host-ip>` (port 22)

### Option 2: Bridge Networking with Port Mapping

If you prefer isolated networking, modify `docker-compose.yaml`:

```yaml
services:
  dev-box:
    # Remove or comment out: network_mode: host
    ports:
      - "2222:22"    # SSH Server (mapped to avoid conflict)
```

**Access:**
- SSH: `ssh ubuntu@<host-ip> -p 2222`

### Option 3: Custom SSH Port with Host Networking

To avoid SSH port conflicts, modify the Dockerfile to use a different SSH port:

1. Edit the Dockerfile SSH configuration:
```dockerfile
echo 'Port 2222' >> /etc/ssh/sshd_config && \
```

2. Rebuild the image:
```bash
docker-compose up -d --build
```

**Access:**
- SSH: `ssh ubuntu@<host-ip> -p 2222`

## Network Utilities Included

The container includes comprehensive network utilities for host network integration:

- `netcat-openbsd` - Network connections and port scanning
- `iproute2` - Advanced IP routing utilities (ip command)
- `iptables` - Firewall configuration tools
- `iputils-ping` - Ping and network connectivity testing
- `traceroute` - Network path tracing
- `dnsutils` - DNS lookup tools (dig, nslookup)
- `tcpdump` - Network packet capture and analysis
- `nmap` - Network discovery and security auditing

## Usage Examples

### Test Network Connectivity
```bash
# Inside the container
ping google.com
traceroute google.com
dig google.com
```

### Check Host Network Interfaces
```bash
# Inside the container
ip addr show
ip route show
```

### Scan Network Ports
```bash
# Inside the container
nmap localhost
netstat -tulpn
```

### Access Host Services
```bash
# Access services running on host localhost
curl http://localhost:8080  # If host runs service on 8080
```

## Troubleshooting

### SSH Port Conflict
If you get "Address already in use" for SSH:

1. **Check what's using port 22:**
   ```bash
   sudo netstat -tulpn | grep :22
   ```

2. **Option A**: Stop host SSH temporarily
   ```bash
   sudo systemctl stop ssh
   ```

3. **Option B**: Change container SSH port (see Option 3 above)

4. **Option C**: Use bridge networking (see Option 2 above)

### Network Performance Issues
Host networking should provide better performance, but if you experience issues:

1. **Check for port conflicts**: `netstat -tulpn`
2. **Monitor network usage**: `iftop` or `nethogs`
3. **Check container logs**: `docker-compose logs dev-box`

## Benefits of Host Networking

1. **Direct Hardware Access**: Combined with privileged mode and device mounts, provides nearly complete host system access.

2. **Network Services**: Can run network services that are directly accessible without port mapping complexity.

3. **Development Integration**: Perfect for network application development where you need direct access to host network stack.

4. **Performance**: Eliminates Docker's network translation overhead.

5. **Simplicity**: No need to manage port mappings for multiple services.

## Complete Host Integration Command

For maximum host integration (networking + devices + Docker):

```bash
docker run -d \
  --name dev-box \
  --privileged \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /dev:/dev \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v $(pwd)/workspace:/workspace \
  wn1980/dev-box:arm64
```

This provides:
- ✅ Host networking
- ✅ USB/hardware access  
- ✅ Docker daemon access
- ✅ Privileged system access
- ✅ Complete development environment

**⚠️ Security Warning**: This configuration provides extensive access to host resources and should only be used in trusted environments.
