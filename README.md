# dev-box

A Dockerized development environment based on Ubuntu Noble, providing a complete SSH-accessible development environment managed by Supervisor. It comes pre-configured with Miniconda, essential C++/Python development tools, and is ready for remote development via SSH.



## ✨ Features

*   **Multi-Architecture Support:** Native support for both **AMD64** (x86_64) and **ARM64** (aarch64) architectures, including Apple Silicon Macs (M1/M2/M3)
*   **SSH-Based Development:** Access a full development environment via SSH with VS Code Remote Development.
*   **Ubuntu Noble Base:** Built on the latest Ubuntu LTS release (at the time of writing).
*   **Miniconda:** Includes Miniconda for robust Python package and environment management.
*   **Pre-configured Conda Environment (`dev_env`):**
    *   Python 3.12
    *   Node.js 22
    *   CMake
    *   C++ Compiler (g++)
    *   Make
    *   GDB (GNU Debugger)
*   **System Tools:**
    *   `git` for version control.
    *   `clangd` for C/C++ language intelligence (installed via apt).
*   **Process Management:** Uses `supervisor` to manage SSH and other services reliably.
*   **Non-root User:** Runs development tasks as a standard user (`ubuntu`, UID/GID 1000) with passwordless `sudo` access.
*   **Persistent Storage:** Uses Docker volumes to persist user configuration and project files between container runs.
*   **SSH Access:** Secure SSH server running on port 2222 with both password and key-based authentication.

## ⚙️ Prerequisites

*   Docker Engine or Docker Desktop installed.
*   Git (optional, for cloning this repository).
*   Docker Compose (or the `docker compose` plugin).

## 🌐 Network Configuration

This container is configured to use **host networking** by default, providing direct access to the host's network stack. This means:

- **SSH Server**: Available directly on host port 2222
- **No port mapping needed**: Services bind to host ports directly
- **Better performance**: No network translation overhead

⚠️ **Important**: The container SSH runs on port 2222 to avoid conflicts with host SSH. See [docs/HOST-NETWORK-SETUP.md](./docs/HOST-NETWORK-SETUP.md) for detailed configuration options and troubleshooting.

## ▶️ Usage (Running with Docker Compose)

This project includes a `docker-compose.yaml` file for easier management of the container and its volumes.

1.  **Prerequisites:**
    *   Ensure you have `docker` and `docker-compose` (or the `docker compose` plugin) installed.
    *   Make sure the `Dockerfile`, the `app` directory, and the `docker-compose.yaml` file are in the same directory.

2.  **Build and Start the Container:**
    Open your terminal in the directory containing the `docker-compose.yaml` file and run:

    ```bash
    docker-compose up -d --build
    ```

    *   `docker-compose up`: Creates and starts the container(s) defined in the file.
    *   `-d`: Runs the container(s) in detached mode (in the background).
    *   `--build`: Forces Docker Compose to build the image using the `Dockerfile` before starting the service. You can omit `--build` on subsequent runs if the `Dockerfile` hasn't changed.

3.  **Access the development environment:**
    *   **SSH Access:** The container provides SSH access on port 2222:
      - `ssh -p 2222 ubuntu@localhost` (local)
      - `ssh -p 2222 ubuntu@<host-ip>` (remote)
      - Default password: `ubuntu` (⚠️ **Change this in production!**)

4.  **Working with Project Files:**
    The `docker-compose.yaml` file uses named volumes:
    *   `config`: Persists user settings and configurations from `/home/ubuntu/.config`.
    *   `conda`: Persists Conda environments and packages from `/home/ubuntu/.conda`.
    *   `Codespaces`: General workspace volume for projects.

    **Important:** This `docker-compose.yaml` uses *named volumes* managed by Docker. This means your project files are stored within Docker's internal storage area, not directly in a folder you specify on your host *by default*.

    *   **Option 1 (Recommended for new projects):** SSH into the container and use the terminal to clone repositories or create new projects directly within the `/workspace` directory. The data will be saved in the mounted volumes.
    *   **Option 2 (Using existing host projects - Modify Compose):** If you prefer to work directly with projects stored in a specific folder on your host machine (like `/path/on/your/host/to/projects`), modify the `volumes` section within the `dev-box` service in your `docker-compose.yaml` like this:

        ```yaml
        services:
          dev-box:
            # ... other settings ...
            volumes:
              - config:/home/ubuntu/.config
              - conda:/home/ubuntu/.conda
              - Codespaces:/workspace
              - /path/on/your/host/to/projects:/home/ubuntu/projects  # Add this bind mount
            # ... other settings ...
        ```
        **Remember to replace `/path/on/your/host/to/projects` with the actual path on your computer.** Then run `docker-compose up -d` again.

5.  **Using the Environment:**
    *   Once connected via SSH, you are in a full Ubuntu development environment running inside the container.
    *   Open a terminal session. You will be logged in as the `ubuntu` user, and the `dev_env` Conda environment will be activated automatically.
    *   You can use `git`, `python`, `g++`, `cmake`, `make`, `gdb`, `node`, etc., directly in the terminal.
    *   For a full IDE experience, use VS Code with the Remote-SSH extension to connect to the container.

6.  **Stopping the Container:**
    To stop the container(s) defined in the compose file:
    ```bash
    docker-compose down
    ```
    *(This stops and removes the container, but preserves the named volumes by default.)*

7.  **Stopping and Removing Volumes:**
    If you want to stop the container AND remove the named volumes (`config`, `projects`):
    ```bash
    docker-compose down -v
    ```

8.  **Restarting the Container:**
    If the container is stopped, you can restart it with:
    ```bash
    docker-compose up -d
    ```

9.  **Viewing Logs:**
    To view the logs from the running container:
    ```bash
    docker-compose logs -f dev-box
    ```
    (Press `Ctrl+C` to stop following logs).

## 🚀 Quick Start

For the fastest setup experience, use the quick setup script:

```bash
git clone <repository-url>
cd docker-dev-box
./quick-setup.sh
```

The quick setup script will:
- Check prerequisites (Docker, Docker Compose)
- Auto-detect your system architecture
- Create environment configuration
- Give you options to build or use pre-built images
- Start the development environment

For manual setup, continue reading below.

## 🏗️ **Building & Architecture Support**

This container supports both **AMD64** (Intel/AMD) and **ARM64** (Apple Silicon, ARM servers) architectures:

### Quick Build Options

```bash
# Build for current platform (auto-detect)
docker compose build

# Build for specific architecture
./build-multiarch.sh --platform arm64    # ARM64 only (Apple Silicon, ARM servers)
./build-multiarch.sh --platform amd64    # AMD64 only (Intel/AMD)
./build-multiarch.sh --platform all      # Both architectures

# Multi-architecture with push to registry
./build-multiarch.sh --platform all --push --registry your-registry.com
```

### Apple Silicon Mac Users
```bash
# Optimal for M1/M2/M3 Macs - builds native ARM64
./build-multiarch.sh --platform arm64
docker compose up -d
```

📖 **For detailed ARM64 support information, see [docs/ARM64-SUPPORT.md](./docs/ARM64-SUPPORT.md)**
📖 **For ARM64 quick start, see [docs/ARM64-QUICKSTART.md](./docs/ARM64-QUICKSTART.md)**

## 🔧 Configuration

*   **Supervisor:** Process management is handled by Supervisor. Configuration files are located in the `app/` directory within this repository and copied to `/app` inside the container.
    *   `app/supervisord.conf`: Main supervisor configuration.
    *   `app/conf.d/sshd.conf`: Configuration for running the SSH server process.
*   **SSH Server:** SSH configuration is handled via standard `/etc/ssh/sshd_config` with enhancements for remote development.
*   **Conda:** The `dev_env` environment is activated by default for the `ubuntu` user's bash sessions via `.bashrc`. You can manage packages using `conda install`, `conda remove`, etc., within SSH terminals.

*Note: AI code generation tools assisted in the development of this project.*

## 🌐 Remote PC Usage

This development environment can be deployed and accessed on a remote PC/server, allowing you to develop from anywhere using SSH connections.

### Quick Setup on Remote PC

1. **Transfer files to remote PC:**
   ```bash
   # Automated transfer with setup options
   ./transfer-to-remote.sh
   
   # OR manual transfer
   git clone <repository-url>
   cd docker-dev-box
   ```

2. **Run the automated setup (if not done during transfer):**
   ```bash
   ./setup-remote-pc.sh
   ```

3. **Access your environment:**
   - **VS Code Remote-SSH:** Configure connection to `remote-pc-ip:22`
   - **Direct SSH:** `ssh ubuntu@remote-pc-ip`

### Features for Remote Development

- **SSH Server:** Built-in SSH server for VS Code Remote-SSH connections
- **Conda Environment:** Automatically activated for all sessions
- **Port Forwarding:** Easy access to development servers
- **Persistent Storage:** Your work persists across container restarts

### Security & Production

For production deployments:
- Change default passwords
- Set up SSH key authentication
- Configure firewall rules
- Use reverse proxy with SSL
- Set up SSH key authentication
- Configure firewall rules
- Use reverse proxy with SSL

📖 **For detailed remote setup instructions, see [docs/REMOTE-SETUP.md](./docs/REMOTE-SETUP.md)**

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

# Development Environment

## Modes of Operation

### 1. Devcontainer Mode (VS Code)
- Open the project in VS Code.
- Install the "Remote - Containers" extension.
- Click on the green "Remote" icon in the bottom-left corner and select "Reopen in Container."

### 2. Normal Mode (Docker Compose)
- Ensure the `.env` file is configured correctly.
- Run the following command to start the container:
  ```bash
  docker-compose --profile normal up -d
  ```

---

### **6. Optional: Add a Validation Script**
Create a script to validate the [.env](http://_vscodecontentref_/10) file and ensure required variables are set before running in either mode.

#### Example Validation Script (`validate-env.sh`):
```bash
#!/bin/bash
if [ -z "$HOST_DOCKER_GID" ]; then
  echo "Error: HOST_DOCKER_GID is not set in .env file."
  exit 1
fi
if [ -z "$ARCH" ]; then
  echo "Error: ARCH is not set in .env file."
  exit 1
fi
echo "Environment variables are valid."
```

## 📁 Project Structure

This project is organized into the following directories:

### 🏠 Root Directory
* **`Dockerfile`** - Main Docker image definition
* **`docker-compose.yaml`** - Main compose configuration  
* **`quick-setup.sh`** - One-command setup script for new users
* **`setup-remote-pc.sh`** - Script for remote PC setup
* **`detect-and-map-devices.sh`** - Auto-detects storage devices and generates device mappings
* **`fix-docker-dns.sh`** - Fixes DNS issues in Docker containers
* **`setup-docker-in-docker.sh`** - Sets up Docker socket permissions for Docker-in-Docker
* **`.env.example`** - Environment configuration template

### 📚 Documentation (`/docs/`)
Comprehensive documentation organized by topic:

**Getting Started:**
- **QUICK-START.md** - Quick start guide for using the development environment
- **ACCESS-METHODS.md** - Different ways to access the development environment

**Architecture Support:**
- **ARM64-SUPPORT.md** - Detailed information about ARM64 architecture support
- **ARM64-QUICKSTART.md** - Quick start guide for ARM64 users
- **ARM64-IMPLEMENTATION-SUMMARY.md** - Implementation details for ARM64 support

**Configuration Guides:**
- **HOST-NETWORK-SETUP.md** - Guide for configuring host networking
- **CAPABILITIES-SETUP.md** - Using Linux capabilities instead of privileged mode
- **SSH-SETUP.md** - SSH configuration details
- **REMOTE-SETUP.md** - Setting up for remote development
- **TROUBLESHOOTING.md** - Common issues and solutions

**Comparison and Analysis:**
- **PRIVILEGED-vs-CAPABILITIES.md** - Comparison between privileged mode and capabilities
- **REMOTE-SSH-VS-DEVCONTAINER-COMPARISON.md** - Comparison between Remote SSH and DevContainer approaches
- **REMOTE-WORKFLOW.md** - Workflows for remote development
- **HOST-SYSTEM-CONTROL.md** - Information about host system control capabilities
- **SYSTEM-CONTROL-TEST-RESULTS.md** - Test results for system control features

### 🔧 Utility Scripts (`/scripts/`)
Build, deployment, and management utilities:

**Build Scripts:**
- **build-multiarch.sh** - Builds multi-architecture Docker images (AMD64 and ARM64)
- **build-arm64-complete.sh** - Complete ARM64-specific build script with enhanced compatibility
- **tag-multiarch-images.sh** - Tags built images with appropriate architecture tags
- **push-multiarch-images.sh** - Pushes multi-architecture images to registries

**Remote Management:**
- **manage-ssh-keys.sh** - Manages SSH keys for secure remote access
- **transfer-to-remote.sh** - Transfers project files to remote systems

**Usage Example:**
```bash
# Build for all architectures
./scripts/build-multiarch.sh --platform all

# Transfer project to remote system
./scripts/transfer-to-remote.sh
```

### ⚙️ Application Configuration (`/app/`)
Supervisor process management configuration:

- **supervisord.conf** - Main supervisor configuration file
- **conf.d/sshd.conf** - SSH daemon service configuration (port 2222)

**Service Configuration:**
The SSH daemon is configured to:
- Listen on port 2222 (avoiding host SSH conflicts)
- Accept both password and key-based authentication
- Allow the default user (`ubuntu`) with password `ubuntu` (for development use only)

**Security Note for Production:**
- Change the default password
- Configure SSH key-based authentication
- Consider disabling password authentication

### 🧪 Test & Validation (`/tests/`)
Scripts for testing and validating the environment:

**Test Scripts:**
- **test-capabilities.sh** - Tests Linux capabilities configuration
- **test-conda-setup.sh** - Validates Conda environment setup and dependencies
- **test-host-network.sh** - Tests host networking configuration and access
- **test-system-control.sh** - Tests system control capabilities
- **test-usb-access.sh** - Tests USB device access from the container
- **demo-system-control.sh** - Demonstrates system control capabilities safely
- **test-device-access.sh** - Tests device access functionality
- **test-device-mount-vs-mapping.sh** - Compares volume mount vs device mapping approaches

**Validation Scripts:**
- **validate-arm64-setup.sh** - Validates ARM64-specific configurations
- **validate-complete-setup.sh** - Validates the complete setup including SSH, networking, etc.

**Usage Example:**
```bash
# From host system
./tests/test-host-network.sh

# From within container
docker exec -it dev_box /workspace/tests/test-host-network.sh
```

