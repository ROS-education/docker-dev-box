# ARM64 Support Documentation

## 🎯 Overview

The Docker dev-box container now has **comprehensive ARM64 (aarch64) support** alongside existing AMD64 (x86_64) support. This enables the container to run natively on:

- **Apple Silicon Macs** (M1, M2, M3 chips)
- **ARM64 Linux servers** (AWS Graviton, Oracle Cloud Ampere, etc.)
- **Raspberry Pi 4/5** (64-bit mode)
- **ARM64 development boards**
- **ARM64 cloud instances**

## ✅ **ARM64 Compatibility Matrix**

| Component | AMD64 Support | ARM64 Support | Notes |
|-----------|---------------|---------------|-------|
| **Base OS** | ✅ Ubuntu Noble | ✅ Ubuntu Noble | Multi-arch base image |
| **Miniconda** | ✅ x86_64 installer | ✅ aarch64 installer | Auto-detection |
| **Python 3.12** | ✅ Conda-forge | ✅ Conda-forge | Native ARM64 builds |
| **Node.js 22** | ✅ Conda-forge | ✅ Conda-forge | Native ARM64 builds |
| **Docker CLI** | ✅ Official repos | ✅ Official repos | Multi-arch support |
| **VS Code Remote-SSH** | ✅ Native support | ✅ Native support | Cross-platform |
| **ngrok** | ✅ AMD64 binary | ✅ ARM64 binary | Architecture-specific |
| **Network Tools** | ✅ All tools | ✅ All tools | Native packages |
| **Development Tools** | ✅ GCC, Make, CMake | ✅ GCC, Make, CMake | Native toolchain |

## 🏗️ **Building for ARM64**

### Method 1: Single Architecture Build

```bash
# Build for ARM64 specifically
docker build --platform linux/arm64 -t docker-dev-box-arm64 .

# Build for AMD64 specifically  
docker build --platform linux/amd64 -t docker-dev-box-amd64 .

# Build for current platform (auto-detect)
docker build -t docker-dev-box .
```

### Method 2: Multi-Architecture Build (Recommended)

```bash
# Use the enhanced build script
./build-multiarch.sh --platform all          # Build both AMD64 and ARM64
./build-multiarch.sh --platform arm64        # Build ARM64 only
./build-multiarch.sh --platform amd64        # Build AMD64 only
./build-multiarch.sh --platform all --push   # Build and push both
```

### Method 3: Docker Compose Multi-Arch

```bash
# Use the multi-arch compose file
docker compose -f docker-compose-multiarch.yaml build
```

## 🚀 **Running on ARM64**

### Local ARM64 System

```bash
# On native ARM64 system (Apple Silicon, ARM64 Linux)
docker compose up -d

# Or specify platform explicitly
docker run --platform linux/arm64 --privileged --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker-dev-box-dev-box:latest
```

### Cross-Platform Development

```bash
# Run ARM64 container on AMD64 system (emulation)
docker run --platform linux/arm64 --privileged --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker-dev-box-dev-box:latest

# Run AMD64 container on ARM64 system (emulation)  
docker run --platform linux/amd64 --privileged --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker-dev-box-dev-box:latest
```

## 🔧 **Architecture Detection & Auto-Configuration**

The Dockerfile includes intelligent architecture detection:

### Build-Time Detection
```dockerfile
# Automatic build arguments from Docker BuildKit
ARG TARGETARCH      # 'amd64' or 'arm64'
ARG TARGETPLATFORM  # 'linux/amd64' or 'linux/arm64'
```

### Runtime Detection
```bash
# Fallback runtime detection
RUNTIME_ARCH=$(uname -m)
case $RUNTIME_ARCH in
    x86_64)  ARCH_SUFFIX="x86_64" ;;
    aarch64) ARCH_SUFFIX="aarch64" ;;
    arm64)   ARCH_SUFFIX="aarch64" ;;
esac
```

### Component-Specific Configuration

**Miniconda Installation:**
- AMD64: Downloads `Miniconda3-latest-Linux-x86_64.sh`
- ARM64: Downloads `Miniconda3-latest-Linux-aarch64.sh`

**ngrok Installation:**
- AMD64: Downloads `ngrok-v3-stable-linux-amd64.zip`
- ARM64: Downloads `ngrok-v3-stable-linux-arm64.zip`

**Docker Repository:**
- Automatically uses correct architecture via `dpkg --print-architecture`

## 🧪 **Testing ARM64 Support**

### Automated Testing

```bash
# Run comprehensive ARM64 compatibility test
./test-arm64-support.sh
```

### Manual Verification

```bash
# Inside the container
uname -m                    # Should show 'aarch64' on ARM64
conda info | grep platform # Should show 'linux-aarch64'
node -e "console.log(process.arch)"  # Should show 'arm64'
docker info --format '{{.Architecture}}'  # Host architecture
```

## 📊 **Performance Considerations**

### Native ARM64 Performance
- **Apple Silicon**: Excellent performance, faster than emulated x86
- **ARM64 Servers**: Native performance, ideal for cloud workloads
- **Raspberry Pi**: Good for development, limited by memory/CPU

### Emulation Performance
- **AMD64 on ARM64**: Slower but functional via emulation
- **ARM64 on AMD64**: Significantly slower, not recommended for production

### Optimization Tips
- Always use native architecture when possible
- For Apple Silicon Macs, prefer ARM64 builds
- For cloud deployments, match container to instance architecture

## 🌟 **Apple Silicon Mac Support**

### Optimal Configuration

```bash
# Build native ARM64 image for Apple Silicon
./build-multiarch.sh --platform arm64

# Run with optimized settings
docker compose up -d
```

### VS Code Integration

```bash
# Access via SSH
ssh ubuntu@localhost  # Password: ubuntu

# Or via VS Code Remote-SSH
# Use Remote-SSH extension to connect to ubuntu@localhost
```

### Docker Desktop Settings
- Enable "Use Rosetta for x86/amd64 emulation on Apple Silicon" for cross-platform compatibility
- Allocate sufficient resources (8GB+ RAM recommended)

## 🐛 **Troubleshooting ARM64 Issues**

### Common Issues

**1. Wrong Architecture Downloaded**
```bash
# Check what was actually downloaded
file /opt/miniconda/bin/conda
# Should show: ELF 64-bit LSB executable, aarch64
```

**2. Conda Packages Not Available**
```bash
# Check available packages
conda search -c conda-forge python
# Some packages may have limited ARM64 availability
```

**3. Performance Issues**
```bash
# Check if running emulated
docker info | grep Architecture
uname -m
# Mismatched values indicate emulation
```

### Solutions

**Force Rebuild with Correct Platform:**
```bash
docker build --no-cache --platform linux/arm64 .
```

**Use Alternative Packages:**
```bash
# If conda package unavailable, try pip
pip install package-name
```

**Check Build Logs:**
```bash
# Enable detailed logging
docker build --progress=plain --platform linux/arm64 .
```

## 📈 **Migration Guide**

### From AMD64-Only to Multi-Arch

1. **Update Build Process:**
   ```bash
   # Old
   docker build -t myimage .
   
   # New
   ./build-multiarch.sh --platform all
   ```

2. **Update CI/CD:**
   ```yaml
   # GitHub Actions example
   - name: Set up Docker Buildx
     uses: docker/setup-buildx-action@v2
   
   - name: Build multi-arch
     run: |
       docker buildx build \
         --platform linux/amd64,linux/arm64 \
         --push -t myregistry/myimage:latest .
   ```

3. **Update Documentation:**
   - Add platform specifications to run commands
   - Document ARM64-specific considerations

## 🚀 **Best Practices**

### Development
- **Use native architecture** for daily development
- **Test both architectures** before deployment
- **Document architecture requirements** in project README

### Deployment
- **Match container architecture to host**
- **Use multi-arch images** for flexibility
- **Monitor performance metrics** across architectures

### CI/CD
- **Build both architectures** in CI pipelines
- **Test on both platforms** if possible
- **Use matrix builds** for comprehensive testing

## 📝 **Examples**

### Complete Multi-Arch Workflow

```bash
# 1. Build for both architectures
./build-multiarch.sh --platform all --tag v1.0

# 2. Test ARM64 functionality
./test-arm64-support.sh

# 3. Deploy based on target platform
# For ARM64 servers:
docker run --platform linux/arm64 myimage:v1.0

# For AMD64 servers:
docker run --platform linux/amd64 myimage:v1.0
```

### Development on Apple Silicon

```bash
# Optimal setup for Apple Silicon Macs
git clone <your-repo>
cd docker-dev-box

# Build native ARM64 image
./build-multiarch.sh --platform arm64

# Start development environment
docker compose up -d

# Access via SSH
ssh ubuntu@localhost
```

## 🔗 **Related Documentation**

- [Docker Multi-Platform Builds](https://docs.docker.com/build/building/multi-platform/)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/)
- [Conda Multi-Platform Support](https://docs.conda.io/projects/conda/en/latest/user-guide/configuration/platforms.html)

---

**✅ ARM64 support is now fully integrated and tested!** 

The container works seamlessly on both AMD64 and ARM64 architectures with automatic detection and configuration.
