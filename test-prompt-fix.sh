#!/bin/bash
# Test script to verify the virtual environment prompt fix

echo "=== Testing Virtual Environment Prompt Fix ==="
echo

# Build the container with the fix
echo "Building updated container..."
docker-compose build --no-cache

# Start the container
echo "Starting container..."
docker-compose up -d

# Wait for container to be ready
echo "Waiting for container to initialize..."
sleep 10

# Test different connection methods
echo
echo "=== Testing Direct Shell Access ==="
echo "Expected: Single (dev_env) prompt"
docker exec dev_box su - developer -c 'echo "Current prompt prefix: $(echo $PS1 | grep -o "(.*)")"'

echo
echo "=== Testing Environment Variables ==="
docker exec dev_box su - developer -c 'echo "VIRTUAL_ENV: $VIRTUAL_ENV"'

echo
echo "=== Testing Python Environment ==="
docker exec dev_box su - developer -c 'python --version && which python'

echo
echo "=== Testing SSH Environment ==="
echo "SSH environment file contents:"
docker exec dev_box cat /home/developer/.ssh/environment

echo
echo "=== Interactive Test (Manual) ==="
echo "Connect via SSH and check the prompt manually:"
echo "ssh -p 2222 developer@localhost"
echo "Password: developer"
echo "The prompt should show: (dev_env) developer@hostname:/workspace$"
echo "NOT: ((dev_env) ) ((dev_env) ) developer@hostname:/workspace$"

echo
echo "Test completed. Check the output above for any issues."
