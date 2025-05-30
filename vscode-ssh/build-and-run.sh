#!/bin/bash
# Script to build, run and connect to the VS Code SSH development container

# Function to check if Docker volume exists and create if needed
check_volume() {
    if ! docker volume ls | grep -q "Codespaces"; then
        echo "Creating Docker volume 'Codespaces'..."
        docker volume create Codespaces
    else
        echo "Docker volume 'Codespaces' already exists."
    fi
}

# Function to build and restart the container
build_and_run() {
    echo "Building and starting the VS Code SSH container..."
    docker-compose -f docker-compose.vscode-ssh.yaml down
    docker-compose -f docker-compose.vscode-ssh.yaml build
    docker-compose -f docker-compose.vscode-ssh.yaml up -d
    
    echo "Container is now running. SSH connection is available at localhost:${SSH_PORT:-2222}"
    echo "Username: dev"
    echo "Password: password"
}

# Main execution
check_volume
build_and_run

# Display how to connect with VS Code
echo "-----------------------------------------------------"
echo "To connect with VS Code Remote SSH:"
echo "1. Install the Remote - SSH extension in VS Code"
echo "2. Add an SSH configuration with the following details:"
echo "   Host: localhost"
echo "   Port: ${SSH_PORT:-2222}"
echo "   Username: dev"
echo "   Password: password"
echo "-----------------------------------------------------"
