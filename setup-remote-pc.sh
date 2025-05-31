#!/bin/bash

# Remote PC Setup Script for Docker Development Environment
# This script helps set up the development environment on a remote PC

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_PORTS="8443,2222"
CONTAINER_NAME="dev_box"

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}  Docker Dev Environment Setup   ${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if user is in docker group
    if ! groups $USER | grep -q docker; then
        print_warning "User $USER is not in the docker group. You may need to use sudo."
        print_status "To add user to docker group: sudo usermod -aG docker $USER"
    fi
    
    print_status "Dependencies check passed!"
}

setup_environment() {
    print_status "Setting up environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        print_status "Creating .env file..."
        cp sample.env .env 2>/dev/null || touch .env
        
        # Set Docker group GID
        DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 988)
        echo "HOST_DOCKER_GID=$DOCKER_GID" >> .env
        print_status "Set HOST_DOCKER_GID=$DOCKER_GID"
    else
        print_status ".env file already exists"
    fi
    
    # Make scripts executable
    chmod +x *.sh 2>/dev/null || true
    print_status "Made scripts executable"
}

configure_firewall() {
    print_status "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        # Check if UFW is active
        if sudo ufw status | grep -q "Status: active"; then
            print_status "UFW is active, configuring ports..."
            
            # Allow necessary ports
            sudo ufw allow 8443/tcp comment "Code-Server HTTPS"
            sudo ufw allow 2222/tcp comment "Docker SSH Container"
            
            print_status "Firewall configured for ports 8443 and 2222"
        else
            print_warning "UFW is not active. Consider enabling it: sudo ufw --force enable"
        fi
    else
        print_warning "UFW not found. Please configure firewall manually to allow ports 8443 and 2222"
    fi
}

build_and_start() {
    print_status "Building and starting containers..."
    
    # Check if containers are already running
    if docker ps | grep -q $CONTAINER_NAME; then
        print_warning "Container $CONTAINER_NAME is already running"
        read -p "Do you want to restart it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down
        else
            print_status "Skipping container restart"
            return 0
        fi
    fi
    
    # Build and start
    print_status "Building Docker image (this may take a while)..."
    docker-compose build --no-cache
    
    print_status "Starting containers..."
    docker-compose up -d
    
    # Wait a moment for services to start
    sleep 5
    
    # Check if container is running
    if docker ps | grep -q $CONTAINER_NAME; then
        print_status "Container started successfully!"
    else
        print_error "Failed to start container. Check logs: docker-compose logs"
        exit 1
    fi
}

setup_ssh_keys() {
    print_status "Setting up SSH keys..."
    
    # Check if user has SSH key
    if [ ! -f ~/.ssh/id_rsa.pub ] && [ ! -f ~/.ssh/id_ed25519.pub ]; then
        print_status "Generating SSH key pair..."
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
        print_status "SSH key generated: ~/.ssh/id_ed25519"
    fi
    
    # Find the public key to use
    local pubkey=""
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        pubkey=~/.ssh/id_ed25519.pub
    elif [ -f ~/.ssh/id_rsa.pub ]; then
        pubkey=~/.ssh/id_rsa.pub
    else
        print_error "No SSH public key found"
        return 1
    fi
    
    # Copy key to container
    if docker ps | grep -q $CONTAINER_NAME; then
        print_status "Copying SSH key to container..."
        print_status "Using public key: $pubkey"
        
        # Create .ssh directory and set permissions
        docker exec $CONTAINER_NAME mkdir -p /home/ubuntu/.ssh
        docker exec $CONTAINER_NAME chmod 700 /home/ubuntu/.ssh
        
        # Copy the public key
        cat "$pubkey" | docker exec -i $CONTAINER_NAME tee -a /home/ubuntu/.ssh/authorized_keys > /dev/null
        
        # Set proper permissions
        docker exec $CONTAINER_NAME chmod 600 /home/ubuntu/.ssh/authorized_keys
        docker exec $CONTAINER_NAME chown -R ubuntu:ubuntu /home/ubuntu/.ssh
        
        print_status "SSH key copied successfully"
    else
        print_warning "Container not running, skipping SSH key setup"
    fi
}

show_access_info() {
    print_header
    print_status "Setup completed successfully!"
    echo
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}Access Information:${NC}"
    echo -e "  ${BLUE}Code-Server (Web):${NC}    https://$SERVER_IP:8443"
    echo -e "  ${BLUE}SSH to Container:${NC}     ssh -p 2222 ubuntu@$SERVER_IP"
    echo -e "  ${BLUE}Default SSH Password:${NC} ubuntu"
    echo
    
    echo -e "${GREEN}VS Code Remote-SSH Config:${NC}"
    echo "  Add this to ~/.ssh/config on your local machine:"
    echo
    echo "  Host remote-dev-box"
    echo "      HostName $SERVER_IP"
    echo "      Port 2222"
    echo "      User ubuntu"
    echo "      ForwardAgent yes"
    echo "      ServerAliveInterval 60"
    echo
    
    echo -e "${GREEN}Container Status:${NC}"
    docker-compose ps
    echo
    
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Access Code-Server at https://$SERVER_IP:8443"
    echo "  2. Or connect via VS Code Remote-SSH"
    echo "  3. Or SSH directly: ssh -p 2222 ubuntu@$SERVER_IP"
    echo
    echo -e "${YELLOW}Security Note:${NC}"
    echo "  Change the default password: docker exec $CONTAINER_NAME passwd ubuntu"
    echo "  See REMOTE-SETUP.md for production security guidelines"
}

show_help() {
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  setup     - Full setup (default)"
    echo "  check     - Check dependencies only"
    echo "  firewall  - Configure firewall only"
    echo "  build     - Build and start containers only"
    echo "  ssh       - Setup SSH keys only"
    echo "  info      - Show access information"
    echo "  stop      - Stop containers"
    echo "  restart   - Restart containers"
    echo "  logs      - Show container logs"
    echo "  help      - Show this help"
}

case "${1:-setup}" in
    "setup")
        print_header
        check_dependencies
        setup_environment
        configure_firewall
        build_and_start
        setup_ssh_keys
        show_access_info
        ;;
    "check")
        check_dependencies
        ;;
    "firewall")
        configure_firewall
        ;;
    "build")
        build_and_start
        ;;
    "ssh")
        setup_ssh_keys
        ;;
    "info")
        show_access_info
        ;;
    "stop")
        print_status "Stopping containers..."
        docker-compose down
        ;;
    "restart")
        print_status "Restarting containers..."
        docker-compose restart
        show_access_info
        ;;
    "logs")
        print_status "Showing container logs..."
        docker-compose logs -f
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
