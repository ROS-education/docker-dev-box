#!/bin/bash

# Set script to exit on error
set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ORIGINAL_DOCKERFILE="$SCRIPT_DIR/Dockerfile"
OPTIMIZED_DOCKERFILE="$SCRIPT_DIR/Dockerfile.optimized"
CLEAN_DOCKERFILE="$SCRIPT_DIR/Dockerfile.clean"
BACKUP_DOCKERFILE="$SCRIPT_DIR/Dockerfile.backup"

echo "VS Code SSH Container Dockerfile Switcher"
echo "----------------------------------------"
echo

if [ ! -f "$OPTIMIZED_DOCKERFILE" ]; then
    echo "Error: Optimized Dockerfile not found!"
    exit 1
fi

if [ ! -f "$ORIGINAL_DOCKERFILE" ]; then
    echo "Error: Original Dockerfile not found!"
    exit 1
fi

echo "Select an option:"
echo "1) Use optimized Dockerfile (faster build with apt-get)"
echo "2) Use original Dockerfile (slower build with conda)"
echo "3) Use clean Dockerfile (optimized without filepath comment)"
echo "4) Compare Dockerfiles"
echo "q) Quit"
echo

read -p "Enter your choice (1-4, q): " choice

case $choice in
    1)
        echo "Backing up current Dockerfile to Dockerfile.backup..."
        cp "$ORIGINAL_DOCKERFILE" "$BACKUP_DOCKERFILE"
        
        echo "Switching to optimized Dockerfile..."
        cp "$OPTIMIZED_DOCKERFILE" "$ORIGINAL_DOCKERFILE"
        
        echo "Done! The optimized Dockerfile is now active."
        echo "You can now build the container with faster performance."
        echo ""
        echo "To build the container, run: ./vscode-ssh-setup.sh"
        ;;
    2)
        if [ -f "$BACKUP_DOCKERFILE" ]; then
            echo "Restoring original Dockerfile from backup..."
            cp "$BACKUP_DOCKERFILE" "$ORIGINAL_DOCKERFILE"
            echo "Original Dockerfile restored."
        else
            echo "No backup found. The original Dockerfile is already active."
        fi
        ;;
    3)
        echo "Backing up current Dockerfile to Dockerfile.backup..."
        cp "$ORIGINAL_DOCKERFILE" "$BACKUP_DOCKERFILE"
        
        echo "Switching to clean Dockerfile (no filepath comment)..."
        cp "$CLEAN_DOCKERFILE" "$ORIGINAL_DOCKERFILE"
        
        echo "Done! The clean Dockerfile is now active."
        echo "You can now build the container with faster performance."
        echo ""
        echo "To build the container, run: ./vscode-ssh-setup.sh"
        ;;
    4)
        echo "Comparing Dockerfiles - select option:"
        echo "a) Compare original vs optimized"
        echo "b) Compare original vs clean"
        echo "c) Compare optimized vs clean"
        read -p "Select comparison (a-c): " compare_option
        
        echo ""
        if [ "$compare_option" = "a" ]; then
            echo "Comparing original vs optimized Dockerfiles..."
            if command -v colordiff &> /dev/null; then
                colordiff -u "$ORIGINAL_DOCKERFILE" "$OPTIMIZED_DOCKERFILE" | less -R
            else
                diff -u "$ORIGINAL_DOCKERFILE" "$OPTIMIZED_DOCKERFILE" | less
            fi
        elif [ "$compare_option" = "b" ]; then
            echo "Comparing original vs clean Dockerfiles..."
            if command -v colordiff &> /dev/null; then
                colordiff -u "$ORIGINAL_DOCKERFILE" "$CLEAN_DOCKERFILE" | less -R
            else
                diff -u "$ORIGINAL_DOCKERFILE" "$CLEAN_DOCKERFILE" | less
            fi
        elif [ "$compare_option" = "c" ]; then
            echo "Comparing optimized vs clean Dockerfiles..."
            if command -v colordiff &> /dev/null; then
                colordiff -u "$OPTIMIZED_DOCKERFILE" "$CLEAN_DOCKERFILE" | less -R
            else
                diff -u "$OPTIMIZED_DOCKERFILE" "$CLEAN_DOCKERFILE" | less
            fi
        else
            echo "Invalid comparison option."
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
