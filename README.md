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
*   **SSH Access:** Secure SSH server running on port 22 with both password and key-based authentication.

## ⚙️ Prerequisites

*   Docker Engine or Docker Desktop installed.
*   Git (optional, for cloning this repository).
*   Docker Compose (or the `docker compose` plugin).

## 🌐 Network Configuration

This container is configured to use **host networking** by default, providing direct access to the host's network stack. This means:

- **SSH Server**: Available directly on host port 22
- **No port mapping needed**: Services bind to host ports directly
- **Better performance**: No network translation overhead

⚠️ **Important**: If your host already runs SSH on port 22, you may need to configure port conflicts. See [HOST-NETWORK-SETUP.md](./HOST-NETWORK-SETUP.md) for detailed configuration options and troubleshooting.

## ▶️ Usage (Running with Docker Compose)

This project includes a `docker-compose.yaml` file for easier management of the container and its volumes.

1.  **Prerequisites:**
    *   Ensure you have `docker` and `docker-compose` (or the `docker compose` plugin) installed.
    *   Make sure the `Dockerfile`, the `supervisor` directory, and the `docker-compose.yaml` file are in the same directory.

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

📖 **For detailed ARM64 support information, see [ARM64-SUPPORT.md](./ARM64-SUPPORT.md)**
📖 **For ARM64 quick start, see [ARM64-QUICKSTART.md](./ARM64-QUICKSTART.md)**

## 🔧 Configuration

*   **Supervisor:** Process management is handled by Supervisor. Configuration files are located in the `supervisor/` directory within this repository and copied to `/opt/supervisor` inside the container.
    *   `supervisor/supervisord.conf`: Main supervisor configuration.
    *   `supervisor/conf.d/sshd.conf`: Configuration for running the SSH server process.
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

📖 **For detailed remote setup instructions, see [REMOTE-SETUP.md](REMOTE-SETUP.md)**

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

