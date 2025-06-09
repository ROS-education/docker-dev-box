# Supervisor Configuration

This directory contains configuration files for [Supervisor](http://supervisord.org/), a process control system used to manage services inside the container.

## Files

- **supervisord.conf**: Main supervisor configuration file
- **conf.d/sshd.conf**: SSH daemon service configuration (port 2222)

## Service Configuration

The SSH daemon is configured to:
- Listen on port 2222
- Accept both password and key-based authentication
- Allow the default user (`ubuntu`) with password `ubuntu` (for development use only)

## Customization

To add new services, create additional configuration files in the `conf.d` directory and rebuild the container.

## Security Note

For production environments:
- Change the default password
- Configure SSH key-based authentication
- Consider disabling password authentication
