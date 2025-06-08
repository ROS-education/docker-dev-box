# ARM64 Quick Start Guide

## 🚀 **Get Started with ARM64 Support**

This guide helps you quickly set up the Docker dev-box container with full ARM64 support.

### ⚡ **Quick Commands**

```bash
# Clone the repository
git clone <your-repo-url>
cd docker-dev-box

# Build for your current platform (auto-detected)
docker compose build

# Or build specifically for ARM64 (Apple Silicon, ARM servers)
./build-multiarch.sh --platform arm64

# Start the container
docker compose up -d

# Access VS Code in browser
open http://localhost:8443  # Password: (none, just press Enter)

# Or SSH access
ssh ubuntu@localhost        # Password: ubuntu
```

### 🍎 **Apple Silicon Mac Users**

```bash
# Optimal setup for M1/M2/M3 Macs
./build-multiarch.sh --platform arm64
docker compose up -d

# Access your development environment
open http://localhost:8443
```

### 🏗️ **Build Options by Platform**

| Platform | Command | Use Case |
|----------|---------|----------|
| **Current Platform** | `docker compose build` | Auto-detect and build |
| **ARM64 Only** | `./build-multiarch.sh --platform arm64` | Apple Silicon, ARM servers |
| **AMD64 Only** | `./build-multiarch.sh --platform amd64` | Intel/AMD processors |
| **Both Platforms** | `./build-multiarch.sh --platform all` | Multi-arch deployment |

### 🧪 **Test Your Setup**

```bash
# Test ARM64 compatibility
./test-arm64-support.sh

# Test system capabilities  
./demo-system-control.sh

# Validate complete setup
./validate-complete-setup.sh
```

### 🔧 **Architecture-Specific Features**

#### **ARM64 (Apple Silicon) Benefits:**
- ✅ Native performance (no emulation)
- ✅ Better power efficiency
- ✅ Full compatibility with M1/M2/M3 Macs
- ✅ Optimized Conda packages
- ✅ Native Docker performance

#### **Cross-Platform Support:**
- ✅ Build once, run anywhere
- ✅ Emulation support for testing
- ✅ CI/CD friendly
- ✅ Registry push for multi-arch images

### 🚨 **Troubleshooting**

#### **Issue: Wrong Architecture Built**
```bash
# Check what was built
docker image inspect docker-dev-box-dev-box:latest | grep Architecture

# Force rebuild for specific platform
docker build --no-cache --platform linux/arm64 .
```

#### **Issue: Performance Problems**
```bash
# Check if running emulated
docker info | grep Architecture
uname -m

# If architectures don't match, you're running emulated
# Solution: Build for native platform
```

#### **Issue: Missing Buildx**
```bash
# Install Docker Buildx (if not included)
docker buildx install

# Or use single-platform builds
docker build --platform linux/arm64 .
```

### 📊 **Performance Comparison**

| Platform | Native Performance | Emulated Performance | Recommendation |
|----------|-------------------|----------------------|----------------|
| **Apple Silicon** | ARM64: Excellent | AMD64: Good | Use ARM64 |
| **Intel/AMD** | AMD64: Excellent | ARM64: Poor | Use AMD64 |
| **ARM Servers** | ARM64: Excellent | AMD64: Fair | Use ARM64 |

### 🎯 **Common Use Cases**

#### **Development on Apple Silicon Mac:**
```bash
./build-multiarch.sh --platform arm64
docker compose up -d
```

#### **Multi-Platform CI/CD:**
```bash
./build-multiarch.sh --platform all --push --registry your-registry.com
```

#### **Testing Cross-Platform:**
```bash
# Build both, test both
./build-multiarch.sh --platform all
docker run --platform linux/arm64 docker-dev-box-dev-box:latest
docker run --platform linux/amd64 docker-dev-box-dev-box:latest
```

### 📚 **Next Steps**

1. **Read Full Documentation:**
   - [ARM64-SUPPORT.md](./ARM64-SUPPORT.md) - Complete ARM64 guide
   - [README.md](./README.md) - Main documentation
   - [HOST-NETWORK-SETUP.md](./HOST-NETWORK-SETUP.md) - Network configuration

2. **Explore Advanced Features:**
   - Host networking capabilities
   - System control access
   - USB device support
   - Remote development setup

3. **Customize Your Environment:**
   - Add your SSH keys
   - Install additional packages
   - Configure VS Code extensions
   - Set up your development workflow

---

**🎉 You're now ready to develop with full ARM64 support!**

For questions or issues, check the troubleshooting sections in the main documentation.
