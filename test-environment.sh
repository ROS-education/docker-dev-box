#!/bin/bash
# Test script for Docker Development Environment
# This script validates the functionality of the containerized development environment

set -e  # Exit on any error

echo "=== Docker Development Environment Test Suite ==="
echo "Testing Alpine Linux-based development container"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# Function to test if container is running
test_container_running() {
    echo -e "${BLUE}Testing container status...${NC}"
    if docker ps | grep -q "dev_box"; then
        print_result 0 "Container is running"
        return 0
    else
        print_result 1 "Container is not running"
        return 1
    fi
}

# Function to test SSH connectivity
test_ssh_connection() {
    echo -e "${BLUE}Testing SSH connection...${NC}"
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p 2222 developer@localhost "echo 'SSH connection successful'" 2>/dev/null; then
        print_result 0 "SSH connection successful"
        return 0
    else
        print_result 1 "SSH connection failed"
        return 1
    fi
}

# Function to test Python environment
test_python_environment() {
    echo -e "${BLUE}Testing Python environment...${NC}"
    local result
    result=$(docker exec dev_box su - developer -c "source /opt/miniconda/envs/dev_env/bin/activate && python --version" 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_result 0 "Python environment: $result"
        return 0
    else
        print_result 1 "Python environment test failed"
        return 1
    fi
}

# Function to test Node.js environment
test_nodejs_environment() {
    echo -e "${BLUE}Testing Node.js environment...${NC}"
    local node_version npm_version
    node_version=$(docker exec dev_box su - developer -c "node --version" 2>/dev/null)
    npm_version=$(docker exec dev_box su - developer -c "npm --version" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        print_result 0 "Node.js: $node_version, npm: $npm_version"
        return 0
    else
        print_result 1 "Node.js environment test failed"
        return 1
    fi
}

# Function to test Docker-in-Docker
test_docker_in_docker() {
    echo -e "${BLUE}Testing Docker-in-Docker functionality...${NC}"
    if docker exec dev_box docker version >/dev/null 2>&1; then
        print_result 0 "Docker-in-Docker is working"
        return 0
    else
        print_result 1 "Docker-in-Docker test failed"
        return 1
    fi
}

# Function to test volume mounts
test_volume_mounts() {
    echo -e "${BLUE}Testing volume mounts...${NC}"
    local test_file="/tmp/test_mount_$$"
    echo "test content" > "$test_file"
    
    # Test workspace mount
    if docker exec dev_box test -d /workspace; then
        print_result 0 "Workspace volume mount exists"
    else
        print_result 1 "Workspace volume mount missing"
        return 1
    fi
    
    rm -f "$test_file"
    return 0
}

# Function to test development tools
test_development_tools() {
    echo -e "${BLUE}Testing development tools...${NC}"
    local tools=("git" "curl" "wget" "cmake" "gdb" "firebase")
    local failed=0
    
    for tool in "${tools[@]}"; do
        if docker exec dev_box which "$tool" >/dev/null 2>&1; then
            print_result 0 "Tool available: $tool"
        else
            print_result 1 "Tool missing: $tool"
            failed=1
        fi
    done
    
    return $failed
}

# Function to test USB access preparation
test_usb_access() {
    echo -e "${BLUE}Testing USB access preparation...${NC}"
    
    # Check if developer user is in required groups
    local groups_result
    groups_result=$(docker exec dev_box groups developer 2>/dev/null)
    
    if echo "$groups_result" | grep -q "dialout"; then
        print_result 0 "User in dialout group"
    else
        print_result 1 "User not in dialout group"
        return 1
    fi
    
    if echo "$groups_result" | grep -q "plugdev"; then
        print_result 0 "User in plugdev group"
    else
        print_result 1 "User not in plugdev group"
        return 1
    fi
    
    return 0
}

# Main test execution
main() {
    echo "Starting test suite..."
    echo
    
    local failed_tests=0
    
    # Test 1: Container status
    if ! test_container_running; then
        echo -e "${YELLOW}Starting container first...${NC}"
        docker-compose up -d
        sleep 10
        if ! test_container_running; then
            echo -e "${RED}Failed to start container. Exiting.${NC}"
            exit 1
        fi
    fi
    
    echo
    
    # Test 2: Python environment
    test_python_environment || ((failed_tests++))
    
    # Test 3: Node.js environment
    test_nodejs_environment || ((failed_tests++))
    
    # Test 4: Docker-in-Docker
    test_docker_in_docker || ((failed_tests++))
    
    # Test 5: Volume mounts
    test_volume_mounts || ((failed_tests++))
    
    # Test 6: Development tools
    test_development_tools || ((failed_tests++))
    
    # Test 7: USB access preparation
    test_usb_access || ((failed_tests++))
    
    # Test 8: SSH connection (optional - may not work without SSH keys)
    echo
    echo -e "${YELLOW}Note: SSH test may fail without proper SSH key setup${NC}"
    test_ssh_connection || echo -e "${YELLOW}SSH test skipped (expected if no SSH keys configured)${NC}"
    
    echo
    echo "=== Test Results Summary ==="
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}All tests passed! Development environment is ready.${NC}"
        echo
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Configure SSH keys using: ./manage-ssh-keys.sh"
        echo "2. Connect via VS Code Remote-SSH to localhost:2222"
        echo "3. Or use devcontainer in VS Code"
        return 0
    else
        echo -e "${RED}$failed_tests test(s) failed. Please check the configuration.${NC}"
        return 1
    fi
}

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo -e "${RED}Error: docker-compose not found. Please install Docker Compose.${NC}"
    exit 1
fi

# Check if docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}Error: docker not found. Please install Docker.${NC}"
    exit 1
fi

# Change to script directory
cd "$(dirname "$0")"

# Run main test function
main "$@"
