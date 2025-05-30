#!/bin/bash

# Set script to exit on error
set -e

SCRIPT_DIR=$(dirname "$0")
ENV_FILE="$SCRIPT_DIR/.env"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"

# If .env file doesn't exist, create it from example
if [ ! -f "$ENV_FILE" ] && [ -f "$ENV_EXAMPLE" ]; then
    echo "Creating .env file from example..."
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    echo "Created. You may want to edit $ENV_FILE to customize settings."
fi

# Ensure the external Codespaces volume exists
if ! docker volume inspect Codespaces &>/dev/null; then
    echo "Creating external Docker volume 'Codespaces'..."
    docker volume create Codespaces
fi

echo "VS Code SSH Container Setup Script"
echo "--------------------------------"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Warning: docker-compose not found. Will use 'docker compose' instead."
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Get the host IP for connection instructions
HOST_IP=$(hostname -I | awk '{print $1}')
if [ -z "$HOST_IP" ]; then
    HOST_IP="your-raspberry-pi-ip"
fi

# Choose an action
echo ""
echo "Select an action:"
echo "1) Build and start the VS Code SSH container"
echo "2) Stop the VS Code SSH container"
echo "3) Restart the VS Code SSH container"
echo "4) Show connection information"
echo "5) Change the default password"
echo "q) Quit"
echo ""

read -p "Enter your choice (1-5, q): " choice

case $choice in
    1)
        echo "Building and starting VS Code SSH container..."
        $DOCKER_COMPOSE -f $(dirname "$0")/docker-compose.vscode-ssh.yaml up -d --build
        echo ""
        echo "Container started successfully!"
        echo ""
        echo "Connection Information:"
        echo "Host: ${HOST_IP}"
        echo "Port: 2222"
        echo "Username: dev"
        echo "Password: password"
        echo ""
        echo "In VS Code:"
        echo "1. Install the 'Remote - SSH' extension"
        echo "2. Press F1 and select 'Remote-SSH: Connect to Host...'"
        echo "3. Enter: dev@${HOST_IP}:2222"
        echo "4. When prompted for password, enter: password"
        echo ""
        echo "IMPORTANT: Please change the default password immediately using option 5"
        ;;
    2)
        echo "Stopping VS Code SSH container..."
        $DOCKER_COMPOSE -f $(dirname "$0")/docker-compose.vscode-ssh.yaml down
        echo "Container stopped successfully"
        ;;
    3)
        echo "Restarting VS Code SSH container..."
        $DOCKER_COMPOSE -f $(dirname "$0")/docker-compose.vscode-ssh.yaml restart
        echo "Container restarted successfully"
        ;;
    4)
        if [ "$($DOCKER_COMPOSE -f $(dirname "$0")/docker-compose.vscode-ssh.yaml ps -q vscode-ssh)" ]; then
            echo "Connection Information:"
            echo "Host: ${HOST_IP}"
            echo "Port: 2222"
            echo "Username: dev"
            echo "Password: password (unless you changed it)"
            echo ""
            echo "In VS Code:"
            echo "1. Install the 'Remote - SSH' extension"
            echo "2. Press F1 and select 'Remote-SSH: Connect to Host...'"
            echo "3. Enter: dev@${HOST_IP}:2222"
        else
            echo "Container is not running. Start it with option 1 first."
        fi
        ;;
    5)
        if [ "$($DOCKER_COMPOSE -f $(dirname "$0")/docker-compose.vscode-ssh.yaml ps -q vscode-ssh)" ]; then
            read -sp "Enter new password: " NEW_PASSWORD
            echo ""
            echo "Changing password..."
            docker exec vscode-ssh-container bash -c "echo 'dev:${NEW_PASSWORD}' | chpasswd"
            echo "Password changed successfully!"
        else
            echo "Container is not running. Start it with option 1 first."
        fi
        ;;
    q|Q)
        echo "Exiting script"
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
