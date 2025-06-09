# Scripts

This directory contains utility scripts for building, deploying, and managing the docker-dev-box environment.

## Build Scripts

- **build-multiarch.sh**: Builds multi-architecture Docker images (AMD64 and ARM64)
- **build-arm64-complete.sh**: Complete ARM64-specific build script with enhanced compatibility

## Image Management

- **tag-multiarch-images.sh**: Tags built images with appropriate architecture tags

## SSH and Remote Management

- **manage-ssh-keys.sh**: Manages SSH keys for secure remote access
- **transfer-to-remote.sh**: Transfers project files to remote systems

## Usage

Most scripts include help information and can be executed directly:

```bash
# Build for all architectures
./scripts/build-multiarch.sh --platform all

# Tag images after building
./scripts/tag-multiarch-images.sh

# Transfer project to remote system
./scripts/transfer-to-remote.sh
```
