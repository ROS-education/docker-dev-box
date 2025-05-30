# VS Code SSH Container with Hardware Access

This folder contains a lightweight container setup for remote VS Code development over SSH, designed specifically for Raspberry Pi and other ARM-based devices. The container includes full hardware access, with special support for USB devices and drives, as well as a pre-configured Conda environment for C++, CMake, and Python development. Your workspace is stored in a persistent Docker volume named 'Codespaces'.

## Files

- `Dockerfile`: Defines a minimal Debian-based container with SSH server and development tools
- `docker-compose.vscode-ssh.yaml`: Docker Compose configuration for the VS Code SSH container
- `vscode-ssh-setup.sh`: Helper script to build, start, and manage the container
- `99-usb-permissions.rules`: udev rules for USB device access

## Features

- Full access to host devices via privileged mode
- USB drive auto-mounting capabilities 
- Helper script for mounting USB devices
- udev rules for proper device permissions
- Persistent workspace using external Docker volume 'Codespaces'
- **Conda Environment (dev_env):**
  - Python 3.11
  - C/C++ Compiler (GCC/G++)
  - CMake and Make
  - GDB for debugging
  - NumPy, Pandas, and Matplotlib
  - Jupyter Notebook

## Accessing USB Devices

Once connected to the container via SSH, you can:

```bash
# List USB devices
lsusb

# List block devices (including USB drives)
lsblk

# Mount a USB drive (replace sdb1 with your device)
sudo mount-usb.sh /dev/sdb1
```

USB drives will be mounted at `/media/` and accessible to the dev user.

## Using Conda Environment

The container comes with a pre-configured conda environment called `dev_env`:

```bash
# The environment is activated automatically when you log in
# Check if conda is working
conda info

# Check which packages are installed
conda list

# Install additional packages
sudo conda install -n dev_env <package-name>

# Create a C++ project
mkdir -p ~/projects/cpp-test
cd ~/projects/cpp-test
cat > CMakeLists.txt << EOF
cmake_minimum_required(VERSION 3.10)
project(TestProject)
add_executable(test_app main.cpp)
EOF

cat > main.cpp << EOF
#include <iostream>
int main() {
    std::cout << "Hello from the VS Code SSH container!" << std::endl;
    return 0;
}
EOF

# Build with CMake
mkdir build && cd build
cmake ..
make
./test_app
```

## How It Works

This setup creates a dedicated container with an SSH server that VS Code can connect to remotely. This is more lightweight than code-server and provides a native VS Code experience.

## Usage

### From the parent directory:

```bash
./run-vscode-ssh.sh
```

### Or directly from this directory:

```bash
./vscode-ssh-setup.sh
```

Then follow the on-screen instructions to:
1. Build and start the container
2. Connect from VS Code using the Remote-SSH extension
3. Change the default password

## Connection Information

- **Host**: Your Raspberry Pi's IP address
- **Port**: 2222
- **Username**: dev
- **Default Password**: password (change this immediately!)

## Customizing

To add more development tools, edit the `Dockerfile` and rebuild using option 1 in the setup script.

## Security Note

Always change the default password immediately after starting the container for the first time.
