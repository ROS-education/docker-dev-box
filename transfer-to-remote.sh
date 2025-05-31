#!/bin/bash

# Script to copy the dev-box project to a remote computer
# Author: GitHub Copilot
# Date: May 30, 2025

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
DEFAULT_SOURCE_DIR=$(dirname "$(readlink -f "$0")")
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

# Create the destination directory first
echo -e "\n${BLUE}Creating destination directory...${NC}"
ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $DEST_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error creating destination directory. Aborting.${NC}"
    exit 1
fi

# Copy the files
echo -e "\n${BLUE}Copying project files to remote host...${NC}"
scp -P "$SSH_PORT" -r "$SOURCE_DIR/"* "$REMOTE_USER@$REMOTE_HOST:$DEST_DIR/"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error copying files. Aborting.${NC}"
    exit 1
fi

# Set execute permissions for scripts
echo -e "\n${BLUE}Setting execute permissions on scripts...${NC}"
ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "cd $DEST_DIR && chmod +x *.sh"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Warning: Could not set execute permissions.${NC}"
fi

# Ask which environment to set up
echo
echo -e "${YELLOW}Which development environment would you like to set up?${NC}"
echo "1. Full Dev-Box (Code-Server + SSH + Conda with C++/Python)"
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
echo -e "${GREEN}Transfer complete!${NC}"

if [ "$ENV_CHOICE" = "3" ] || [ "$ENV_CHOICE" != "1" ] && [ "$ENV_CHOICE" != "2" ]; then
    echo -e "\nTo manually set up environments on the remote host:"
    echo -e "${BLUE}For Full Dev-Box:${NC}"
    echo -e "  ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST"
    echo -e "  cd $DEST_DIR"
    echo -e "  ./setup-remote-pc.sh"
    echo
    echo -e "${BLUE}For VS Code SSH:${NC}"
    echo -e "  ssh -p $SSH_PORT $REMOTE_USER@$REMOTE_HOST"
    echo -e "  cd $DEST_DIR"
    echo -e "  ./setup-remote-pc.sh"
fi
echo

# Optional: offer to connect to the remote machine
read -p "Do you want to connect to the remote machine now? (y/n): " CONNECT

if [[ $CONNECT == [yY]* ]]; then
    echo -e "\n${BLUE}Connecting to $REMOTE_USER@$REMOTE_HOST...${NC}"
    ssh -p "$SSH_PORT" "$REMOTE_USER@$REMOTE_HOST"
fi
