#!/bin/bash

# Script to copy the dev-box project to a remote computer
# Author: GitHub Copilot
# Date: June 10, 2025

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Transfer the docker-dev-box project to a remote computer via SSH/SCP"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "The script will interactively prompt for:"
    echo "  - Remote hostname or IP address"
    echo "  - Remote username (default: ubuntu)"
    echo "  - SSH port (default: 22)"
    echo "  - Source directory (default: project root)"
    echo "  - Destination directory (default: ~/dev-box)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Interactive mode"
    echo "  $0 --help                    # Show this help"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -*)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac

# ANSI color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display script banner
echo -e "${BLUE}==============================================${NC}"
echo -e "${GREEN}Dev Box - Remote Transfer Script${NC}"
echo -e "${BLUE}==============================================${NC}"
echo

# Default values
DEFAULT_SOURCE_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")  # Project root directory
DEFAULT_SSH_PORT=22

# Ask for remote hostname/IP
read -p "Enter remote hostname or IP (e.g., rk3399.local): " REMOTE_HOST
if [ -z "$REMOTE_HOST" ]; then
    echo -e "${RED}Error: Remote hostname cannot be empty${NC}"
    exit 1
fi

# Ask for remote user
read -p "Enter remote username (default: ubuntu): " REMOTE_USER
REMOTE_USER=${REMOTE_USER:-ubuntu}

# Ask for SSH port
read -p "Enter SSH port (default: $DEFAULT_SSH_PORT): " SSH_PORT
SSH_PORT=${SSH_PORT:-$DEFAULT_SSH_PORT}

# Ask for source directory 
read -p "Enter source directory (default: $DEFAULT_SOURCE_DIR): " SOURCE_DIR
SOURCE_DIR=${SOURCE_DIR:-$DEFAULT_SOURCE_DIR}

# Ask for destination directory
read -p "Enter destination directory on remote (default: ~/dev-box): " DEST_DIR
DEST_DIR=${DEST_DIR:-"~/dev-box"}

# Confirm before proceeding
echo
echo -e "${YELLOW}Ready to copy files with the following settings:${NC}"
echo -e "  Source directory: ${GREEN}$SOURCE_DIR${NC}"
echo -e "  Remote host: ${GREEN}$REMOTE_USER@$REMOTE_HOST:$SSH_PORT${NC}"
echo -e "  Destination directory: ${GREEN}$DEST_DIR${NC}"
echo
read -p "Do you want to continue? (y/n): " CONFIRM

if [[ $CONFIRM != [yY]* ]]; then
    echo -e "${YELLOW}Operation canceled.${NC}"
    exit 0
fi

# Validate source directory exists and contains expected files
echo -e "\n${BLUE}Validating source directory...${NC}"
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory '$SOURCE_DIR' does not exist.${NC}"
    exit 1
fi

if [ ! -f "$SOURCE_DIR/Dockerfile" ] || [ ! -f "$SOURCE_DIR/docker-compose.yaml" ]; then
    echo -e "${RED}Error: Source directory doesn't appear to contain the dev-box project.${NC}"
    echo -e "${RED}Expected files 'Dockerfile' and 'docker-compose.yaml' not found.${NC}"
    exit 1
fi

# Test SSH connectivity
echo -e "${BLUE}Testing SSH connectivity...${NC}"
if ! ssh -p "$SSH_PORT" -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH connection successful'" 2>/dev/null; then
    echo -e "${YELLOW}Warning: Could not establish SSH connection. Please ensure:${NC}"
    echo -e "  - Remote host is accessible"
    echo -e "  - SSH service is running on port $SSH_PORT"
    echo -e "  - SSH keys are set up or password authentication is enabled"
    read -p "Do you want to continue anyway? (y/n): " CONTINUE_ANYWAY
    if [[ $CONTINUE_ANYWAY != [yY]* ]]; then
        echo -e "${YELLOW}Operation canceled.${NC}"
        exit 0
    fi
fi

# Create the destination directory first
echo -e "\n${BLUE}Creating destination directory...${NC}"
ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $DEST_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error creating destination directory. Aborting.${NC}"
    exit 1
fi

# Copy the files
echo -e "\n${BLUE}Copying project files to remote host...${NC}"
rsync -avz --progress --exclude='.git' --exclude='.vscode' --exclude='*.log' --exclude='node_modules' \
    -e "ssh -p $SSH_PORT" "$SOURCE_DIR/" "$REMOTE_USER@$REMOTE_HOST:$DEST_DIR/"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}rsync failed, trying with scp...${NC}"
    scp -P "$SSH_PORT" -r "$SOURCE_DIR/"* "$REMOTE_USER@$REMOTE_HOST:$DEST_DIR/"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error copying files. Aborting.${NC}"
        exit 1
    fi
fi

# Set execute permissions for scripts
echo -e "\n${BLUE}Setting execute permissions on scripts...${NC}"
ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "cd $DEST_DIR && find . -name '*.sh' -type f -exec chmod +x {} \;"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Warning: Could not set execute permissions.${NC}"
fi

# Ask which environment to set up
echo
echo -e "${YELLOW}Which development environment would you like to set up?${NC}"
echo "1. Full Dev-Box (SSH + Conda with C++/Python)"
echo "2. Transfer only (no setup)"
read -p "Choose option (1/2): " ENV_CHOICE

case $ENV_CHOICE in
    1)
        echo -e "\n${BLUE}Setting up Full Dev-Box environment...${NC}"
        ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "cd $DEST_DIR && ./setup-remote-pc.sh"
        ;;
    2)
        echo -e "\n${GREEN}Files transferred successfully. No automatic setup performed.${NC}"
        ;;
    *)
        echo -e "\n${YELLOW}Invalid choice. Skipping automatic setup.${NC}"
        ;;
esac

# Confirm completion
echo
echo -e "${GREEN}✅ Transfer complete!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "  • Files copied from: $SOURCE_DIR"
echo -e "  • Remote destination: $REMOTE_USER@$REMOTE_HOST:$DEST_DIR"
echo -e "  • SSH port: $SSH_PORT"

if [ "$ENV_CHOICE" != "1" ]; then
    echo -e "\n${YELLOW}📝 Next steps - To set up the environment on the remote host:${NC}"
    echo -e "${BLUE}For Full Dev-Box:${NC}"
    echo -e "  ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST"
    echo -e "  cd $DEST_DIR"
    echo -e "  ./setup-remote-pc.sh"
    echo
    echo -e "${BLUE}For manual Docker setup:${NC}"
    echo -e "  ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST"
    echo -e "  cd $DEST_DIR"
    echo -e "  docker compose up -d --build"
fi
echo

# Optional: offer to connect to the remote machine
read -p "Do you want to connect to the remote machine now? (y/n): " CONNECT

if [[ $CONNECT == [yY]* ]]; then
    echo -e "\n${BLUE}Connecting to $REMOTE_USER@$REMOTE_HOST...${NC}"
    ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST"
fi
