# dev-box

A Dockerized development environment based on Ubuntu Noble, providing a complete SSH-accessible development environment managed by Supervisor. It comes pre-configured with Miniconda, essential C++/Python/Node.js development tools, Docker-in-Docker support, and is ready for remote development via SSH or VS Code DevContainer.

## ✨ Features

*   **Multi-Architecture Support:** Native support for both **AMD64** (x86_64) and **ARM64** (aarch64) architectures, including Apple Silicon Macs (M1/M2/M3)
*   **SSH-Based Development:** Access a full development environment via SSH with VS Code Remote Development.
*   **VS Code DevContainer:** Native devcontainer support via `.devcontainer/devcontainer.json`.
*   **Ubuntu Noble Base:** Built on `ubuntu:noble-20250404`.
*   **Miniconda:** Includes Miniconda for robust Python package and environment management (AMD64 and ARM64).
*   **Pre-configured Conda Environment (`dev_env`):**
    *   Python 3.12
    *   Node.js 22
    *   CMake
    *   C++ Compiler (g++ via `cxx-compiler`)
    *   Make
    *   GDB (GNU Debugger)
*   **Developer Tools:**
    *   `git` — version control
    *   `clangd` — C/C++ language intelligence (via apt)
    *   `gh` — GitHub CLI
    *   `gcloud` — Google Cloud SDK (AMD64 and ARM64)
    *   `firebase-tools` — Firebase CLI (via npm in `dev_env`)
    *   `ngrok` — secure tunnel tool
    *   `rsync` — file synchronization
    *   `bash-completion` — shell completions
*   **Container / Cloud Tools:**
    *   Docker CLI (`docker`, `docker compose`, `docker buildx`)
    *   Docker socket (`/var/run/docker.sock`) mounted for Docker-in-Docker workflows
*   **Java Runtime:** `openjdk-17-jre-headless`
*   **Network Utilities:** `netcat-openbsd`, `iproute2`, `iptables`, `iputils-ping`, `traceroute`, `dnsutils`, `tcpdump`, `nmap`
*   **USB / Device Access:** `usbutils`, `libusb-1.0-0-dev`, `libudev-dev`; ubuntu user added to `dialout`, `plugdev`, and `tty` groups
*   **Process Management:** Uses `supervisor` to manage SSH and other services reliably.
*   **Non-root User:** Runs as `ubuntu` (UID/GID 1000) with passwordless `sudo` access.
*   **Persistent Storage:** Named Docker volumes for user configuration, conda environments, and the workspace.
*   **SSH Access:** Secure SSH server on port **2222** supporting both password and key-based authentication.
*   **Host Networking:** Runs in `network_mode: host` — no port mapping needed.
*   **Privileged Mode:** Runs with full privileges for device, USB, and system-level access.

## ⚙️ Prerequisites

*   Docker Engine or Docker Desktop installed.
*   Docker Compose (or the `docker compose` plugin).
*   Git (optional, for cloning this repository).

## 🌐 Network Configuration

This container is configured to use **host networking** by default, providing direct access to the host's network stack. This means:

- **SSH Server**: Available directly on host port 2222
- **No port mapping needed**: Services bind to host ports directly
- **Better performance**: No network translation overhead

⚠️ **Important**: The container SSH runs on port 2222 to avoid conflicts with host SSH. See [docs/HOST-NETWORK-SETUP.md](./docs/HOST-NETWORK-SETUP.md) for detailed configuration options and troubleshooting.

## ▶️ Usage (Running with Docker Compose)

### 1. Set up environment variables

Copy the example `.env` file and update it for your system:

```bash
cp .env.example .env
```

Edit `.env` to set the correct values:

```dotenv
# GID of the docker group on your host (for Docker socket access)
HOST_DOCKER_GID=988   # replace with: getent group docker | cut -d: -f3

# Architecture: amd64 or arm64
ARCH=amd64

# Timezone
TZ=UTC
```

> **Tip:** Run `getent group docker | cut -d: -f3` on your host to get the correct `HOST_DOCKER_GID`.

### 2. Create the external workspace volume

The `Codespaces` volume is declared as `external: true` in `docker-compose.yaml` and must be created before starting the stack:

```bash
docker volume create Codespaces
```

### 3. Start the container

The default compose configuration **pulls a pre-built image** from the `wn1980` registry:

```bash
docker compose up -d
```

#### Build locally instead (optional)

Uncomment the `build:` block and comment out the `image:` line in `docker-compose.yaml`, or use the build script:

```bash
./scripts/build-multiarch.sh --platform amd64   # or arm64 / all
docker compose up -d
```

### 4. Access the development environment

```bash
# Local
ssh -p 2222 ubuntu@localhost

# Remote
ssh -p 2222 ubuntu@<host-ip>
```

Default credentials: user `ubuntu`, password `ubuntu`. ⚠️ **Change this in production!**

### 5. Connect with VS Code

- **Remote-SSH extension:** Connect to `ubuntu@localhost:2222`
- **DevContainer:** Open the project in VS Code and choose *Reopen in Container* — the `.devcontainer/devcontainer.json` is pre-configured

### 6. Working with project files

The compose file uses named Docker volumes:

| Volume | Mount point | Purpose |
|---|---|---|
| `config` | `/home/ubuntu/.config` | User settings and tool configuration |
| `conda` | `/home/ubuntu/.conda` | Conda environments and packages |
| `Codespaces` | `/workspace` | Project files (external volume) |

To mount a host directory for existing projects, add a bind mount to `docker-compose.yaml`:

```yaml
volumes:
  - /path/on/host/to/projects:/home/ubuntu/projects
```

### 7. Stop / remove the container

```bash
# Stop and remove container (volumes are preserved)
docker compose down

# Stop and remove container AND volumes
docker compose down -v
```

### 8. View logs

```bash
docker compose logs -f dev-box
```

## 🏗️ Building & Architecture Support

This container supports both **AMD64** (Intel/AMD) and **ARM64** (Apple Silicon, ARM servers) architectures:

```bash
# Build for current platform (auto-detect)
docker compose build

# Build for specific architecture
./scripts/build-multiarch.sh --platform arm64    # ARM64 only (Apple Silicon, ARM servers)
./scripts/build-multiarch.sh --platform amd64    # AMD64 only (Intel/AMD)
./scripts/build-multiarch.sh --platform all      # Both architectures

# Build and push to registry
./scripts/build-multiarch.sh --platform all --push --registry your-registry.com
```

### Apple Silicon Mac Users

```bash
# Optimal for M1/M2/M3 Macs — builds native ARM64
./scripts/build-multiarch.sh --platform arm64
docker compose up -d
```

📖 See [docs/ARM64-SUPPORT.md](./docs/ARM64-SUPPORT.md) and [docs/ARM64-QUICKSTART.md](./docs/ARM64-QUICKSTART.md) for details.

## 🔧 Configuration

*   **Supervisor:** Process management configuration lives in the `app/` directory and is copied to `/app` inside the container.
    *   `app/supervisord.conf` — main Supervisor configuration
    *   `app/conf.d/sshd.conf` — SSH daemon service (port 2222)
*   **SSH Server:** Configured via `/etc/ssh/sshd_config` with Remote Development-friendly settings (X11 forwarding, keep-alive, environment variable pass-through for Conda).
*   **Conda:** The `dev_env` environment is activated by default for the `ubuntu` user via `.bashrc`.
*   **Docker group GID:** Set via `HOST_DOCKER_GID` in `.env` to match your host's docker group, enabling access to the mounted Docker socket.
*   **Timezone:** Controlled via the `TZ` environment variable (default `Asia/Bangkok` in compose, configure in `.env`).

## 🗄️ MongoDB Add-on

A standalone MongoDB service configuration is available in [`mongodb/docker-compose.yml`](./mongodb/docker-compose.yml). It uses an external volume `mongodb_data` and exposes MongoDB on port `27017`.

```bash
# Create the external volume first
docker volume create mongodb_data

# Start MongoDB
docker compose -f mongodb/docker-compose.yml up -d
```

## 📁 Project Structure

```
docker-dev-box/
├── Dockerfile                  # Main Docker image definition (multi-arch)
├── docker-compose.yaml         # Main compose configuration
├── .env                        # Local environment variables (gitignored)
├── .env.example                # Environment configuration template
├── .devcontainer/
│   └── devcontainer.json       # VS Code DevContainer configuration
├── app/                        # Supervisor process management
│   ├── supervisord.conf        # Main Supervisor config
│   └── conf.d/
│       └── sshd.conf           # SSH daemon config (port 2222)
├── docs/                       # Comprehensive documentation
├── mongodb/
│   └── docker-compose.yml      # MongoDB companion service
├── scripts/
│   ├── build-multiarch.sh      # Multi-architecture Docker image builder
│   └── transfer-to-remote.sh   # Transfer project files to a remote system
└── tests/                      # Test and validation scripts
```

### 📚 Documentation (`/docs/`)

| Topic | File |
|---|---|
| Quick start | [QUICK-START.md](./docs/QUICK-START.md) |
| Access methods | [ACCESS-METHODS.md](./docs/ACCESS-METHODS.md) |
| ARM64 support | [ARM64-SUPPORT.md](./docs/ARM64-SUPPORT.md) |
| ARM64 quick start | [ARM64-QUICKSTART.md](./docs/ARM64-QUICKSTART.md) |
| ARM64 implementation | [ARM64-IMPLEMENTATION-SUMMARY.md](./docs/ARM64-IMPLEMENTATION-SUMMARY.md) |
| Host networking | [HOST-NETWORK-SETUP.md](./docs/HOST-NETWORK-SETUP.md) |
| Linux capabilities | [CAPABILITIES-SETUP.md](./docs/CAPABILITIES-SETUP.md) |
| SSH setup | [SSH-SETUP.md](./docs/SSH-SETUP.md) |
| Remote setup | [REMOTE-SETUP.md](./docs/REMOTE-SETUP.md) |
| Troubleshooting | [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) |
| Privileged vs capabilities | [PRIVILEGED-vs-CAPABILITIES.md](./docs/PRIVILEGED-vs-CAPABILITIES.md) |
| Remote SSH vs DevContainer | [REMOTE-SSH-VS-DEVCONTAINER-COMPARISON.md](./docs/REMOTE-SSH-VS-DEVCONTAINER-COMPARISON.md) |
| Remote workflow | [REMOTE-WORKFLOW.md](./docs/REMOTE-WORKFLOW.md) |
| Host system control | [HOST-SYSTEM-CONTROL.md](./docs/HOST-SYSTEM-CONTROL.md) |
| System control test results | [SYSTEM-CONTROL-TEST-RESULTS.md](./docs/SYSTEM-CONTROL-TEST-RESULTS.md) |
| GitHub CLI guide | [GITHUB-CLI-GUIDE.md](./docs/GITHUB-CLI-GUIDE.md) |
| Device access explained | [DEVICE-ACCESS-EXPLAINED.md](./docs/DEVICE-ACCESS-EXPLAINED.md) |
| Tagging summary | [TAGGING-SUMMARY.md](./docs/TAGGING-SUMMARY.md) |

### 🔧 Scripts (`/scripts/`)

| Script | Description |
|---|---|
| `build-multiarch.sh` | Build Docker images for AMD64, ARM64, or both |
| `transfer-to-remote.sh` | Interactively transfer project to a remote machine via SCP |

### 🧪 Tests (`/tests/`)

| Script | Description |
|---|---|
| `test-capabilities.sh` | Tests Linux capabilities configuration |
| `test-conda-setup.sh` | Validates Conda environment setup |
| `test-host-network.sh` | Tests host networking configuration |
| `test-system-control.sh` | Tests system control capabilities |
| `test-usb-access.sh` | Tests USB device access |
| `test-device-access.sh` | Tests device access functionality |
| `test-device-mount-vs-mapping.sh` | Compares volume mount vs device mapping |
| `demo-system-control.sh` | Demonstrates system control capabilities |
| `validate-arm64-setup.sh` | Validates ARM64-specific configurations |
| `validate-complete-setup.sh` | Full end-to-end validation |

## 🌐 Remote PC Usage

1. **Transfer files to remote PC:**
   ```bash
   ./scripts/transfer-to-remote.sh
   ```

2. **Access your environment:**
   - **VS Code Remote-SSH:** Connect to `ubuntu@<remote-ip>:22`
   - **Direct SSH:** `ssh -p 2222 ubuntu@<remote-ip>`

📖 See [docs/REMOTE-SETUP.md](./docs/REMOTE-SETUP.md) for full instructions.

## 🔒 Security Notes

This environment is configured for **development use**. Before deploying in production:

- Change the default `ubuntu` password
- Set up SSH key-based authentication and disable password auth
- Configure firewall rules
- Use a reverse proxy with TLS if exposing services externally
- Avoid running with `privileged: true` if not required — see [docs/CAPABILITIES-SETUP.md](./docs/CAPABILITIES-SETUP.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

*Note: AI code generation tools assisted in the development of this project.*


