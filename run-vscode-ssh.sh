#!/bin/bash

# Simple launcher for the VS Code SSH setup script
echo "Launching VS Code SSH Container setup script..."
exec "$(dirname "$0")/vscode-ssh/vscode-ssh-setup.sh"
