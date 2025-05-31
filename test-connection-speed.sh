#!/bin/bash

# Connection Speed Test Script
# Tests latency and throughput for SSH connections

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}  Connection Speed Test          ${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo
}

test_ssh_latency() {
    local host=${1:-localhost}
    local port=${2:-2222}
    
    echo -e "${GREEN}Testing SSH latency to $host:$port...${NC}"
    
    # Test 10 connections and average
    echo "Running 10 connection tests..."
    for i in {1..10}; do
        time_result=$(time (ssh -o ConnectTimeout=5 -p $port ubuntu@$host 'echo "test"' 2>/dev/null) 2>&1 | grep real | awk '{print $2}')
        echo "Test $i: $time_result"
    done
    echo
}

test_ssh_throughput() {
    local host=${1:-localhost}
    local port=${2:-2222}
    
    echo -e "${GREEN}Testing SSH throughput to $host:$port...${NC}"
    
    # Create a test file
    echo "Creating 10MB test file..."
    dd if=/dev/zero of=/tmp/test_10mb bs=1M count=10 2>/dev/null
    
    # Upload test
    echo "Testing upload speed..."
    time scp -P $port /tmp/test_10mb ubuntu@$host:/tmp/ 2>/dev/null
    
    # Download test
    echo "Testing download speed..."
    time scp -P $port ubuntu@$host:/tmp/test_10mb /tmp/test_download 2>/dev/null
    
    # Cleanup
    rm -f /tmp/test_10mb /tmp/test_download
    ssh -p $port ubuntu@$host 'rm -f /tmp/test_10mb' 2>/dev/null
    echo
}

test_vs_code_startup() {
    local host=${1:-localhost}
    local port=${2:-2222}
    
    echo -e "${GREEN}Testing VS Code Remote-SSH startup time...${NC}"
    
    # Simulate VS Code connection steps
    echo "1. Testing SSH connection establishment..."
    time ssh -o ConnectTimeout=5 -p $port ubuntu@$host 'echo "Connected"' 2>/dev/null
    
    echo "2. Testing environment detection..."
    time ssh -p $port ubuntu@$host 'which python; which node; echo $CONDA_DEFAULT_ENV' 2>/dev/null
    
    echo "3. Testing file system access..."
    time ssh -p $port ubuntu@$host 'ls -la /workspace' 2>/dev/null
    echo
}

print_header

echo -e "${YELLOW}This script tests connection performance for SSH access${NC}"
echo -e "${YELLOW}to your Docker development container.${NC}"
echo

# Get target host
read -p "Enter target host (default: localhost): " TARGET_HOST
TARGET_HOST=${TARGET_HOST:-localhost}

read -p "Enter SSH port (default: 2222): " SSH_PORT  
SSH_PORT=${SSH_PORT:-2222}

echo
echo -e "${BLUE}Testing connection to $TARGET_HOST:$SSH_PORT${NC}"
echo

# Run tests
test_ssh_latency $TARGET_HOST $SSH_PORT
test_ssh_throughput $TARGET_HOST $SSH_PORT  
test_vs_code_startup $TARGET_HOST $SSH_PORT

echo -e "${GREEN}Speed test completed!${NC}"
echo
echo -e "${YELLOW}Tips for better performance:${NC}"
echo "1. Use SSH key authentication (no password prompts)"
echo "2. Enable SSH compression in ~/.ssh/config"
echo "3. Use wired connection for best stability"
echo "4. Consider SSH multiplexing for multiple connections"
