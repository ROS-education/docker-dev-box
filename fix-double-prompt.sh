#!/bin/bash
# Quick fix script for double virtual environment prompt issue
# Run this inside your existing container to fix the prompt immediately

echo "=== Fixing Double Virtual Environment Prompt ==="

# Fix the .bashrc to use Python virtual environment activation
cat > ~/.bashrc << 'EOF'
# Activate Python development environment by default (only if not already activated)
if [[ -z "$VIRTUAL_ENV" ]]; then
    source /opt/python-dev-env/bin/activate
fi

# Add helpful aliases for development
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
EOF

# Fix the SSH environment file
echo "PATH=/home/developer/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > ~/.ssh/environment
chmod 600 ~/.ssh/environment

# Unset any existing virtual environment variables to force clean activation
unset VIRTUAL_ENV
unset CONDA_DEFAULT_ENV

echo "=== Fix Applied Successfully ==="
echo "Please start a new shell session or run:"
echo "source ~/.bashrc"
echo
echo "Your prompt should now show: (dev_env) instead of ((dev_env) )"
