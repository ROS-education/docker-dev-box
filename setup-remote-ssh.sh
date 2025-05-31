#!/bin/bash

# Remote SSH Setup Helper for Docker Dev Box
# This script helps set up SSH connections to the Docker container

set -e

CONTAINER_NAME="dev_box"
SSH_PORT="2222"
SSH_USER="ubuntu"
HOST="localhost"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat << EOF
Remote SSH Setup Helper for Docker Dev Box

Usage: $0 [COMMAND]

Commands:
    setup-keys      Set up SSH key authentication
    copy-key        Copy your SSH public key to the container
    test-connection Test SSH connection to the container
    show-config     Show VS Code Remote-SSH configuration
    reset-keys      Remove known host entries and reset
    help           Show this help message

Examples:
    $0 setup-keys      # Set up SSH key authentication
    $0 test-connection # Test SSH connection
    $0 show-config     # Show VS Code config

Container Details:
    Host: $HOST
    Port: $SSH_PORT
    User: $SSH_USER
    Container: $CONTAINER_NAME

EOF
}

check_container() {
    if ! docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        print_error "Container '$CONTAINER_NAME' is not running"
        print_info "Start the container with: docker-compose up -d"
        exit 1
    fi
}

setup_keys() {
    print_info "Setting up SSH key authentication..."
    
    # Check if SSH key exists
    if [[ ! -f "$HOME/.ssh/id_rsa.pub" && ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        print_warning "No SSH public key found. Generating new ed25519 key..."
        ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
        print_success "SSH key generated: $HOME/.ssh/id_ed25519"
    fi
    
    copy_key
}

copy_key() {
    check_container
    
    print_info "Copying SSH public key to container..."
    
    # Find the public key
    local pubkey=""
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        pubkey="$HOME/.ssh/id_ed25519.pub"
    elif [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
        pubkey="$HOME/.ssh/id_rsa.pub"
    else
        print_error "No SSH public key found"
        print_info "Generate one with: ssh-keygen -t ed25519"
        exit 1
    fi
    
    # Copy key to container
    print_info "Using public key: $pubkey"
    
    # Create .ssh directory and authorized_keys in container
    docker exec "$CONTAINER_NAME" mkdir -p /home/ubuntu/.ssh
    docker exec "$CONTAINER_NAME" chmod 700 /home/ubuntu/.ssh
    
    # Copy the public key
    cat "$pubkey" | docker exec -i "$CONTAINER_NAME" tee -a /home/ubuntu/.ssh/authorized_keys > /dev/null
    
    # Set proper permissions
    docker exec "$CONTAINER_NAME" chmod 600 /home/ubuntu/.ssh/authorized_keys
    docker exec "$CONTAINER_NAME" chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    
    print_success "SSH public key copied successfully"
    print_info "You can now use key-based authentication"
}

test_connection() {
    check_container
    
    print_info "Testing SSH connection to $HOST:$SSH_PORT..."
    
    # Remove any existing known_hosts entry
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[$HOST]:$SSH_PORT" 2>/dev/null || true
    
    # Test connection
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$SSH_PORT" "$SSH_USER@$HOST" "echo 'SSH connection successful!'" 2>/dev/null; then
        print_success "SSH connection test passed!"
        print_info "Connection details:"
        echo "  Host: $HOST"
        echo "  Port: $SSH_PORT"
        echo "  User: $SSH_USER"
    else
        print_error "SSH connection test failed"
        print_info "Troubleshooting steps:"
        echo "1. Check if container is running: docker ps"
        echo "2. Check SSH service: docker exec $CONTAINER_NAME supervisorctl status sshd"
        echo "3. Check SSH logs: docker exec $CONTAINER_NAME journalctl -u ssh"
        echo "4. Try password authentication: ssh -p $SSH_PORT $SSH_USER@$HOST"
        return 1
    fi
}

show_config() {
    cat << EOF

VS Code Remote-SSH Configuration:

Add this to your VS Code SSH config (~/.ssh/config):

Host docker-dev-box
    HostName $HOST
    Port $SSH_PORT
    User $SSH_USER
    ForwardAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 10

Then in VS Code:
1. Install the "Remote - SSH" extension
2. Press Ctrl+Shift+P (Cmd+Shift+P on Mac)
3. Type "Remote-SSH: Connect to Host"
4. Select "docker-dev-box"

OR use this connection string directly:
ssh://$SSH_USER@$HOST:$SSH_PORT

Container Access Commands:
- SSH: ssh -p $SSH_PORT $SSH_USER@$HOST
- SCP: scp -P $SSH_PORT file.txt $SSH_USER@$HOST:/workspace/
- SFTP: sftp -P $SSH_PORT $SSH_USER@$HOST

EOF
}

reset_keys() {
    print_warning "This will remove known host entries for $HOST:$SSH_PORT"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[$HOST]:$SSH_PORT" 2>/dev/null || true
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$HOST" 2>/dev/null || true
        print_success "Known host entries removed"
    else
        print_info "Operation cancelled"
    fi
}

main() {
    local command="${1:-help}"
    
    case "$command" in
        "setup-keys")
            setup_keys
            ;;
        "copy-key")
            copy_key
            ;;
        "test-connection")
            test_connection
            ;;
        "show-config")
            show_config
            ;;
        "reset-keys")
            reset_keys
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
