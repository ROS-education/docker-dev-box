#!/bin/bash
# Simple test script to verify the virtual environment prompt fix

echo "=== Testing Virtual Environment Prompt Fix ==="
echo

# Check if container is built
if ! docker images | grep -q dev-box-test; then
    echo "Building container..."
    docker build -t dev-box-test .
fi

# Start the container
echo "Starting test container..."
CONTAINER_ID=$(docker run -d --name dev-box-prompt-test dev-box-test tail -f /dev/null)

if [ $? -ne 0 ]; then
    echo "Failed to start container"
    exit 1
fi

# Wait for container to initialize
echo "Waiting for container to initialize..."
sleep 5

echo
echo "=== Testing SSH Environment File ==="
echo "SSH environment PATH (should NOT include /opt/miniconda/envs/dev_env/bin):"
docker exec dev-box-prompt-test cat /home/developer/.ssh/environment

echo
echo "=== Testing Bashrc Activation ==="
echo "Bashrc virtual environment setup:"
docker exec dev-box-prompt-test grep -A3 -B1 "VIRTUAL_ENV" /home/developer/.bashrc

echo
echo "=== Testing Direct Shell Access ==="
echo "Testing prompt behavior:"
docker exec dev-box-prompt-test su - developer -c 'bash -l -c "echo \"VIRTUAL_ENV set to: \$VIRTUAL_ENV\"; echo \"Python location: \$(which python)\"; echo \"Prompt test: \$PS1\" | head -c 100"'

echo
echo "=== Testing Environment Variables ==="
docker exec dev-box-prompt-test su - developer -c 'bash -l -c "env | grep -E \"(VIRTUAL_ENV|PS1)\" | head -5"'

# Cleanup
echo
echo "Cleaning up test container..."
docker stop dev-box-prompt-test > /dev/null 2>&1
docker rm dev-box-prompt-test > /dev/null 2>&1

echo "Test completed!"
