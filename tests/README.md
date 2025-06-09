# Test Scripts

This directory contains scripts for testing and validating various aspects of the docker-dev-box environment.

## Test Scripts

- **test-capabilities.sh**: Tests Linux capabilities configuration
- **test-conda-setup.sh**: Validates Conda environment setup and dependencies
- **test-host-network.sh**: Tests host networking configuration and access
- **test-system-control.sh**: Tests system control capabilities
- **test-usb-access.sh**: Tests USB device access from the container

## Validation Scripts

- **validate-arm64-setup.sh**: Validates ARM64-specific configurations
- **validate-complete-setup.sh**: Validates the complete setup including SSH, networking, etc.

## Usage

Run these scripts either directly on the host system or from within the container:

```bash
# From host system
./tests/test-host-network.sh

# From within container
docker exec -it dev_box /workspace/tests/test-host-network.sh
```
