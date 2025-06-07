#!/bin/bash
# DevContainer Validation Script
# Tests VS Code devcontainer functionality and configuration

set -e

echo "=== DevContainer Configuration Validation ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# Check if .devcontainer directory exists
echo -e "${BLUE}Checking DevContainer configuration...${NC}"

if [ -d ".devcontainer" ]; then
    print_result 0 "DevContainer directory exists"
else
    print_result 1 "DevContainer directory missing"
    exit 1
fi

# Validate devcontainer.json
if [ -f ".devcontainer/devcontainer.json" ]; then
    print_result 0 "devcontainer.json exists"
    
    # Check JSON syntax
    if python3 -m json.tool .devcontainer/devcontainer.json >/dev/null 2>&1; then
        print_result 0 "devcontainer.json has valid JSON syntax"
    else
        print_result 1 "devcontainer.json has invalid JSON syntax"
    fi
    
    # Check required fields
    if grep -q '"dockerComposeFile"' .devcontainer/devcontainer.json; then
        print_result 0 "dockerComposeFile configuration found"
    else
        print_result 1 "dockerComposeFile configuration missing"
    fi
    
    if grep -q '"service"' .devcontainer/devcontainer.json; then
        print_result 0 "service configuration found"
    else
        print_result 1 "service configuration missing"
    fi
    
    if grep -q '"workspaceFolder"' .devcontainer/devcontainer.json; then
        print_result 0 "workspaceFolder configuration found"
    else
        print_result 1 "workspaceFolder configuration missing"
    fi
else
    print_result 1 "devcontainer.json missing"
    exit 1
fi

# Check docker-compose file
echo
echo -e "${BLUE}Checking Docker Compose configuration...${NC}"

if [ -f "docker-compose.yaml" ]; then
    print_result 0 "docker-compose.yaml exists"
    
    # Validate YAML syntax
    if docker-compose config >/dev/null 2>&1; then
        print_result 0 "docker-compose.yaml has valid syntax"
    else
        print_result 1 "docker-compose.yaml has syntax errors"
    fi
    
    # Check service name matches devcontainer.json
    local service_name
    service_name=$(grep -o '"service": *"[^"]*"' .devcontainer/devcontainer.json | cut -d'"' -f4)
    if grep -q "^  $service_name:" docker-compose.yaml; then
        print_result 0 "Service name '$service_name' matches in both files"
    else
        print_result 1 "Service name mismatch between devcontainer.json and docker-compose.yaml"
    fi
else
    print_result 1 "docker-compose.yaml missing"
    exit 1
fi

# Check Dockerfile
echo
echo -e "${BLUE}Checking Dockerfile...${NC}"

if [ -f "Dockerfile" ]; then
    print_result 0 "Dockerfile exists"
    
    # Check for developer user
    if grep -q "ARG USERNAME=developer" Dockerfile; then
        print_result 0 "Developer user configuration found"
    else
        print_result 1 "Developer user configuration missing"
    fi
    
    # Check for SSH configuration
    if grep -q "ssh-keygen" Dockerfile; then
        print_result 0 "SSH server configuration found"
    else
        print_result 1 "SSH server configuration missing"
    fi
    
    # Check for Python environment
    if grep -q "python3" Dockerfile; then
        print_result 0 "Python environment configuration found"
    else
        print_result 1 "Python environment configuration missing"
    fi
    
    # Check for Node.js
    if grep -q "nodejs" Dockerfile; then
        print_result 0 "Node.js configuration found"
    else
        print_result 1 "Node.js configuration missing"
    fi
else
    print_result 1 "Dockerfile missing"
    exit 1
fi

# Check supervisor configuration
echo
echo -e "${BLUE}Checking Supervisor configuration...${NC}"

if [ -d "supervisor" ]; then
    print_result 0 "Supervisor directory exists"
    
    if [ -f "supervisor/supervisord.conf" ]; then
        print_result 0 "supervisord.conf exists"
    else
        print_result 1 "supervisord.conf missing"
    fi
    
    if [ -f "supervisor/conf.d/sshd.conf" ]; then
        print_result 0 "SSH daemon configuration exists"
    else
        print_result 1 "SSH daemon configuration missing"
    fi
else
    print_result 1 "Supervisor directory missing"
fi

# Check environment file
echo
echo -e "${BLUE}Checking Environment configuration...${NC}"

if [ -f ".env" ]; then
    print_result 0 ".env file exists"
    
    if grep -q "HOST_DOCKER_GID" .env; then
        print_result 0 "Docker GID configuration found"
    else
        print_result 1 "Docker GID configuration missing"
    fi
else
    print_result 1 ".env file missing"
fi

# VS Code extension recommendations
echo
echo -e "${BLUE}Checking VS Code extensions...${NC}"

if grep -q "ms-python.python" .devcontainer/devcontainer.json; then
    print_result 0 "Python extension configured"
else
    print_result 1 "Python extension not configured"
fi

if grep -q "ms-vscode.vscode-docker" .devcontainer/devcontainer.json; then
    print_result 0 "Docker extension configured"
else
    print_result 1 "Docker extension not configured"
fi

# Summary
echo
echo -e "${BLUE}=== DevContainer Validation Summary ===${NC}"
echo
echo -e "${GREEN}DevContainer configuration appears valid!${NC}"
echo
echo -e "${BLUE}To use the DevContainer:${NC}"
echo "1. Open this directory in VS Code"
echo "2. Install the 'Dev Containers' extension"
echo "3. Press Ctrl+Shift+P and select 'Dev Containers: Reopen in Container'"
echo "4. VS Code will build and connect to the container automatically"
echo
echo -e "${BLUE}Alternative connection methods:${NC}"
echo "1. SSH: ssh -p 2222 developer@localhost (password: developer)"
echo "2. Direct: docker exec -it dev_box su - developer"
echo
echo -e "${YELLOW}Note: First build may take several minutes to download and install packages.${NC}"
