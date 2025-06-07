#!/bin/bash

# Test script to verify Python virtual environment setup
# This script tests the running container

set -e

echo "=== Testing Python Virtual Environment Setup ==="
echo

# Test 1: Check if Python is available
echo "1. Testing Python availability..."
if docker exec dev_box which python >/dev/null 2>&1; then
    PYTHON_VERSION=$(docker exec dev_box python --version)
    PYTHON_PATH=$(docker exec dev_box which python)
    echo "✅ Python command found: $PYTHON_PATH"
    echo "$PYTHON_VERSION"
else
    echo "❌ Python command not found"
    exit 1
fi
echo

# Test 2: Check if virtual environment exists
echo "2. Testing virtual environment existence..."
if docker exec dev_box test -d "/opt/python-dev-env"; then
    echo "✅ Python virtual environment found at /opt/python-dev-env"
    echo "Virtual environment contents:"
    docker exec dev_box ls -la /opt/python-dev-env/bin/ | head -5
else
    echo "❌ Python virtual environment not found at /opt/python-dev-env"
    exit 1
fi
echo

# Test 3: Check if virtual environment can be activated
echo "3. Testing virtual environment activation..."
ACTIVATION_TEST=$(docker exec dev_box bash -c "source /opt/python-dev-env/bin/activate && echo \$VIRTUAL_ENV")
if [ -n "$ACTIVATION_TEST" ]; then
    echo "✅ Virtual environment activated successfully"
    echo "Current virtual environment: $ACTIVATION_TEST"
else
    echo "❌ Failed to activate virtual environment"
    exit 1
fi
echo

# Test 4: Check Python in virtual environment
echo "4. Testing Python in virtual environment..."
PYTHON_VERSION=$(docker exec dev_box bash -c "source /opt/python-dev-env/bin/activate && python --version")
PYTHON_PATH=$(docker exec dev_box bash -c "source /opt/python-dev-env/bin/activate && which python")
PIP_VERSION=$(docker exec dev_box bash -c "source /opt/python-dev-env/bin/activate && pip --version")
echo "Python version: $PYTHON_VERSION"
echo "Python path: $PYTHON_PATH"
echo "Pip version: $PIP_VERSION"
echo

# Test 5: Check installed packages
echo "5. Checking installed Python packages..."
echo "Installed packages:"
docker exec dev_box bash -c "source /opt/python-dev-env/bin/activate && pip list" | head -10
echo

# Test 6: Test Node.js (system-level)
echo "6. Testing Node.js (system-level)..."
NODE_VERSION=$(docker exec dev_box node --version)
NPM_VERSION=$(docker exec dev_box npm --version)
NODE_PATH=$(docker exec dev_box which node)
echo "Node.js version: $NODE_VERSION"
echo "npm version: $NPM_VERSION"
echo "Node.js path: $NODE_PATH"
echo

# Test 7: Test npm global packages
echo "7. Testing npm configuration..."
NPM_PREFIX=$(docker exec dev_box npm config get prefix)
echo "npm prefix: $NPM_PREFIX"
echo "npm global packages:"
docker exec dev_box npm list -g --depth=0 | head -10
echo

# Test 8: Test basic Python functionality
echo "8. Testing basic Python functionality..."
docker exec dev_box bash -c "source /opt/python-dev-env/bin/activate && python -c \"import sys; print(f'Python executable: {sys.executable}')\""
docker exec dev_box bash -c "source /opt/python-dev-env/bin/activate && python -c \"import numpy; print(f'NumPy version: {numpy.__version__}')\""
docker exec dev_box bash -c "source /opt/python-dev-env/bin/activate && python -c \"import pandas; print(f'Pandas version: {pandas.__version__}')\""
echo

# Test 9: Test auto-activation for developer user
echo "9. Testing auto-activation for developer user..."
DEV_PYTHON_VERSION=$(docker exec dev_box su - developer -c "bash -i -c 'python --version'" 2>/dev/null)
DEV_PYTHON_PATH=$(docker exec dev_box su - developer -c "bash -i -c 'which python'" 2>/dev/null)
DEV_VIRTUAL_ENV=$(docker exec dev_box su - developer -c "bash -i -c 'echo \$VIRTUAL_ENV'" 2>/dev/null)
echo "Developer user Python version: $DEV_PYTHON_VERSION"
echo "Developer user Python path: $DEV_PYTHON_PATH"
echo "Developer user virtual environment: $DEV_VIRTUAL_ENV"
echo

echo "=== All Python virtual environment tests completed successfully! ==="
