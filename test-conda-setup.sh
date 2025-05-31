#!/bin/bash

# Test script to verify conda environment setup
# This script should be run inside the Docker container

set -e

echo "=== Testing Conda Environment Setup ==="
echo

# Test 1: Check if conda is available
echo "1. Testing conda availability..."
if command -v conda >/dev/null 2>&1; then
    echo "✅ conda command found: $(which conda)"
    conda --version
else
    echo "❌ conda command not found"
    exit 1
fi
echo

# Test 2: Check if conda can be sourced
echo "2. Testing conda initialization..."
if [ -f /opt/miniconda/etc/profile.d/conda.sh ]; then
    echo "✅ conda.sh found"
    source /opt/miniconda/etc/profile.d/conda.sh
    echo "✅ conda.sh sourced successfully"
else
    echo "❌ conda.sh not found"
    exit 1
fi
echo

# Test 3: List conda environments
echo "3. Listing conda environments..."
conda env list
echo

# Test 4: Check if dev_env exists
echo "4. Checking if dev_env exists..."
if conda env list | grep -q "dev_env"; then
    echo "✅ dev_env environment found"
else
    echo "❌ dev_env environment not found"
    exit 1
fi
echo

# Test 5: Try to activate dev_env
echo "5. Testing dev_env activation..."
conda activate dev_env
if [ "$CONDA_DEFAULT_ENV" = "dev_env" ]; then
    echo "✅ dev_env activated successfully"
    echo "Current environment: $CONDA_DEFAULT_ENV"
else
    echo "❌ Failed to activate dev_env"
    echo "Current environment: ${CONDA_DEFAULT_ENV:-none}"
    exit 1
fi
echo

# Test 6: Check installed packages
echo "6. Checking installed packages in dev_env..."
echo "Python version: $(python --version)"
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo

# Test 7: Test npm global install path
echo "7. Testing npm configuration..."
echo "npm prefix: $(npm config get prefix)"
echo "npm global packages:"
npm list -g --depth=0 | head -10
echo

echo "=== All tests completed successfully! ==="
