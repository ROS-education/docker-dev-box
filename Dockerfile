# Use Alpine Linux as base image for smaller footprint
# Pinning to a specific version for reproducibility
FROM alpine:3.20

# Define ARG for host docker group GID.
# IMPORTANT: Set this at build time (--build-arg HOST_DOCKER_GID=$(getent group docker | cut -d: -f3))
# to match your HOST's docker group GID for socket permissions.
# Defaulting to 988 as per original, but overriding is recommended.
ARG HOST_DOCKER_GID=988

# Define automatic build arguments provided by BuildKit
# TARGETARCH will be 'amd64' or 'arm64' depending on the build target
ARG TARGETARCH

# Configure developer user name
ARG USERNAME=developer

# Install base dependencies and development tools
RUN apk add --no-cache \
    bash \
    bash-completion \
    ca-certificates \
    curl \
    gnupg \
    sudo \
    git \
    openssl \
    net-tools \
    supervisor \
    clang \
    clang-dev \
    llvm \
    wget \
    unzip \
    openjdk17-jre-headless \
    openssh-server \
    rsync \
    shadow \
    tzdata \
    libusb-dev \
    eudev-dev \
    usbutils \
    make \
    cmake \
    gdb

# Install Docker CLI from static binaries (Alpine doesn't have official Docker packages)
RUN \
    # Determine architecture for Docker CLI download
    if [ -n "${TARGETARCH:-}" ]; then \
        case ${TARGETARCH} in \
            amd64) DOCKER_ARCH="x86_64" ;; \
            arm64) DOCKER_ARCH="aarch64" ;; \
            *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
        esac; \
    else \
        RUNTIME_ARCH=$(uname -m); \
        case ${RUNTIME_ARCH} in \
            x86_64) DOCKER_ARCH="x86_64" ;; \
            aarch64) DOCKER_ARCH="aarch64" ;; \
            *) echo "Unsupported runtime architecture: ${RUNTIME_ARCH}"; exit 1 ;; \
        esac; \
    fi && \
    echo "Using Docker architecture: ${DOCKER_ARCH}" && \
    # Download and install Docker CLI
    curl -fsSL "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-24.0.7.tgz" -o docker.tgz && \
    tar xzf docker.tgz --strip 1 -C /usr/local/bin docker/docker && \
    rm docker.tgz && \
    # Install Docker Compose plugin
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -fsSL "https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-${DOCKER_ARCH}" -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Install Google Cloud CLI
RUN \
    # Determine architecture for gcloud CLI
    if [ -n "${TARGETARCH:-}" ]; then \
        case ${TARGETARCH} in \
            amd64) GCLOUD_ARCH="x86_64" ;; \
            arm64) GCLOUD_ARCH="arm" ;; \
            *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
        esac; \
    else \
        RUNTIME_ARCH=$(uname -m); \
        case ${RUNTIME_ARCH} in \
            x86_64) GCLOUD_ARCH="x86_64" ;; \
            aarch64) GCLOUD_ARCH="arm" ;; \
            *) echo "Unsupported runtime architecture: ${RUNTIME_ARCH}"; exit 1 ;; \
        esac; \
    fi && \
    echo "Using gcloud architecture: ${GCLOUD_ARCH}" && \
    curl -fsSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-455.0.0-linux-${GCLOUD_ARCH}.tar.gz" -o gcloud.tar.gz && \
    tar xzf gcloud.tar.gz -C /opt && \
    rm gcloud.tar.gz && \
    /opt/google-cloud-sdk/install.sh --quiet --path-update=false && \
    ln -s /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud && \
    ln -s /opt/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil

# Set environment variable for Python installation path (using Alpine's system Python)
ENV PYTHON_PATH=/usr/bin
# Set environment variable for updated PATH
ENV PATH=/home/${USERNAME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Ensure sudo access to Python environment
RUN echo 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/sudoers

# Install Python 3.12 and development tools from Alpine packages
RUN apk add --no-cache \
    python3=~3.12 \
    python3-dev \
    py3-pip \
    py3-setuptools \
    py3-wheel \
    py3-virtualenv \
    build-base \
    linux-headers \
    && ln -sf python3 /usr/bin/python \
    && ln -sf pip3 /usr/bin/pip

# Create Python virtual environment for development
RUN python3 -m venv /opt/python-dev-env \
    && /opt/python-dev-env/bin/pip install --upgrade pip setuptools wheel

# Install development tools in the Python virtual environment
RUN /opt/python-dev-env/bin/pip install \
    jupyter \
    ipython \
    numpy \
    pandas \
    matplotlib \
    requests \
    && echo "Development environment ready with Python 3.12 from Alpine packages"

# Install Node.js and npm from Alpine (keep system-level for global tools)
RUN apk add --no-cache nodejs npm

# Install Firebase CLI globally using npm from Alpine packages
# Downgrade npm to a compatible version with Node.js 20.15.1
RUN npm install -g npm@10.8.3 && \
    npm install -g firebase-tools

# Install ngrok using bash shell to handle case statement properly
RUN /bin/bash -c 'set -e; \
    ARCH=$(uname -m); \
    echo "Detected architecture: $ARCH"; \
    case $ARCH in \
        x86_64) NGROK_ZIP="ngrok-v3-stable-linux-amd64.zip" ;; \
        aarch64) NGROK_ZIP="ngrok-v3-stable-linux-arm64.zip" ;; \
        armv7l) NGROK_ZIP="ngrok-v3-stable-linux-arm.zip" ;; \
        armv6l) NGROK_ZIP="ngrok-v3-stable-linux-arm.zip" ;; \
        arm64) NGROK_ZIP="ngrok-v3-stable-linux-arm64.zip" ;; \
        *) echo "Unsupported runtime architecture: $ARCH"; exit 1 ;; \
    esac; \
    echo "Using ngrok package: $NGROK_ZIP"; \
    curl -O https://bin.equinox.io/c/bNyj1mQVY4c/${NGROK_ZIP}; \
    unzip -o ${NGROK_ZIP}; \
    mv ngrok /usr/local/bin/ngrok; \
    rm ${NGROK_ZIP}; \
    ngrok version'

# Symlink Node.js and npm from Alpine packages to /usr/local/bin for sudo access
RUN ln -sf /usr/bin/node /usr/local/bin/node && \
    ln -sf /usr/bin/npm /usr/local/bin/npm

# Configure developer user (Alpine uses adduser instead of useradd)
RUN adduser -D -s /bin/bash -u 1000 ${USERNAME} && \
    echo "${USERNAME}:developer" | chpasswd && \
    mkdir -p /home/${USERNAME}/.n8n && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.n8n && \
    mkdir -p /home/${USERNAME}/.config && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config && \
    mkdir -p /workspace && \
    chown -R ${USERNAME}:${USERNAME} /workspace && \
    ln -sfn /workspace /home/${USERNAME}/workspace

# Create docker group with specific GID from build argument to match HOST docker group GID.
# Then add developer user to this group to allow access to the mounted docker socket.
RUN addgroup -g ${HOST_DOCKER_GID:-988} docker || true && \
    adduser ${USERNAME} docker

# Initialize Python environment for the developer user's bash shell
USER ${USERNAME}
RUN echo '# Source .bashrc for SSH sessions' > /home/${USERNAME}/.bash_profile && \
    echo 'if [ -f ~/.bashrc ]; then' >> /home/${USERNAME}/.bash_profile && \
    echo '    source ~/.bashrc' >> /home/${USERNAME}/.bash_profile && \
    echo 'fi' >> /home/${USERNAME}/.bash_profile && \
    # Setup Python virtual environment activation in .bashrc
    echo '' >> /home/${USERNAME}/.bashrc && \
    echo '# Activate Python development environment by default' >> /home/${USERNAME}/.bashrc && \
    echo 'if [[ -z "$VIRTUAL_ENV" ]]; then' >> /home/${USERNAME}/.bashrc && \
    echo '    source /opt/python-dev-env/bin/activate' >> /home/${USERNAME}/.bashrc && \
    echo 'fi' >> /home/${USERNAME}/.bashrc && \
    # Add helpful aliases for development
    echo 'alias ll="ls -la"' >> /home/${USERNAME}/.bashrc && \
    echo 'alias la="ls -A"' >> /home/${USERNAME}/.bashrc && \
    echo 'alias l="ls -CF"' >> /home/${USERNAME}/.bashrc

# Create SSH directory for developer user
RUN mkdir -p /home/${USERNAME}/.ssh && \
    chmod 700 /home/${USERNAME}/.ssh && \
    # Create SSH environment file for basic PATH (virtual environment activated via .bashrc)
    echo "PATH=/home/${USERNAME}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" > /home/${USERNAME}/.ssh/environment && \
    chmod 600 /home/${USERNAME}/.ssh/environment

# Switch back to root for subsequent steps
USER root

# Allow developer user to use sudo without password (architecture independent)
RUN echo '${USERNAME} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/${USERNAME}-nopasswd && \
    chmod 0440 /etc/sudoers.d/${USERNAME}-nopasswd

# Install USB utilities and add developer user to dialout and plugdev groups for USB access
RUN adduser ${USERNAME} dialout && \
    adduser ${USERNAME} plugdev || addgroup plugdev && adduser ${USERNAME} plugdev && \
    adduser ${USERNAME} tty || true

# Create udev rules for USB device access
RUN mkdir -p /etc/udev/rules.d && \
    # Allow all users in plugdev group to access USB devices
    echo 'SUBSYSTEM=="usb", MODE="0664", GROUP="plugdev"' > /etc/udev/rules.d/99-usb-permissions.rules && \
    echo 'SUBSYSTEM=="tty", MODE="0664", GROUP="dialout"' >> /etc/udev/rules.d/99-usb-permissions.rules && \
    echo 'SUBSYSTEM=="usb_device", MODE="0664", GROUP="plugdev"' >> /etc/udev/rules.d/99-usb-permissions.rules && \
    # Allow access to common development USB devices
    echo 'ATTRS{idVendor}=="*", ATTRS{idProduct}=="*", MODE="0664", GROUP="plugdev"' >> /etc/udev/rules.d/99-usb-permissions.rules

# Configure SSH server for Remote-SSH compatibility
RUN mkdir -p /var/run/sshd && \
    # Generate host keys
    ssh-keygen -A && \
    # Configure SSH server settings for VS Code Remote-SSH
    echo 'Port 22' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'AuthorizedKeysFile .ssh/authorized_keys' >> /etc/ssh/sshd_config && \
    echo 'ChallengeResponseAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'UsePAM yes' >> /etc/ssh/sshd_config && \
    echo 'X11Forwarding yes' >> /etc/ssh/sshd_config && \
    echo 'PrintMotd no' >> /etc/ssh/sshd_config && \
    echo 'AcceptEnv LANG LC_*' >> /etc/ssh/sshd_config && \
    echo 'Subsystem sftp /usr/lib/ssh/sftp-server' >> /etc/ssh/sshd_config && \
    # SSH keepalive settings for better Remote-SSH experience
    echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config && \
    echo 'ClientAliveCountMax 10' >> /etc/ssh/sshd_config && \
    # Allow environment variables for Python environment activation
    echo 'AcceptEnv VIRTUAL_ENV PATH' >> /etc/ssh/sshd_config && \
    echo 'PermitUserEnvironment yes' >> /etc/ssh/sshd_config

# Skip code-server installation for Alpine version
# Use VS Code Remote-SSH instead for better Alpine compatibility
# Code-server has glibc compatibility issues on Alpine Linux

# Switch to developer user for subsequent steps
USER ${USERNAME}

# Skip VS Code extensions installation since we're not using code-server
# Use VS Code Remote-SSH instead which will install extensions locally 
 
# Set Workdir as ubuntu user
WORKDIR /workspace

# Switch back to root user before CMD to start supervisord as root
USER root

# Copy local supervisor directory structure
# IMPORTANT: Ensure supervisor/supervisord.conf DOES NOT try to start dockerd
COPY supervisor /opt/supervisor
RUN chown -R ${USERNAME}:${USERNAME} /opt/supervisor

VOLUME ["/workspace", "/home/${USERNAME}/.config", "/home/${USERNAME}/.n8n"]
EXPOSE 22

# --- IMPORTANT NOTES FOR SHARING HOST DOCKER DAEMON AND USB DEVICES ---
#
# 1. Runtime Flags: You MUST run this container with:
#    -v /var/run/docker.sock:/var/run/docker.sock
#    This mounts the host's Docker socket into the container.
#
# 2. USB Device Access: For full USB device access, run with:
#    --privileged
#    -v /dev:/dev
#    -v /sys/fs/cgroup:/sys/fs/cgroup:ro
#    Or for specific USB devices:
#    --device=/dev/bus/usb:/dev/bus/usb
#    --device=/dev/ttyUSB0:/dev/ttyUSB0 (for specific serial devices)
#    --device=/dev/ttyACM0:/dev/ttyACM0 (for Arduino/microcontroller devices)
#
# 3. Build Argument: You SHOULD build this image with:
#    --build-arg HOST_DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 988)
#    Replace '988' with the actual GID if the command fails. This ensures the 'docker'
#    group inside the container has the same GID as the 'docker' group on your host,
#    granting the 'developer' user permission to use the mounted socket. If the GID inside
#    doesn't match the GID owning the socket on the host, you'll get permission errors.
#
# 4. Supervisor Configuration: Ensure your supervisor/supervisord.conf file
#    DOES NOT contain an active [program:dockerd] section. For Alpine version,
#    code-server is also disabled due to glibc compatibility issues.
#    Supervisor only manages SSH daemon and other Alpine-compatible services.
#
# 5. USB Device Discovery: The container includes usbutils (lsusb) and proper group
#    memberships for USB device access. The developer user is added to dialout, plugdev,
#    and tty groups for comprehensive device access.
#
# 6. Example Docker Run Command for Full USB Access:
#    docker run --privileged -v /dev:/dev -v /var/run/docker.sock:/var/run/docker.sock \
#               -p 2222:22 your-image-name

# Configure bash completion and history
RUN echo "source /usr/share/bash-completion/bash_completion" >> /etc/bash.bashrc && \
    echo "HISTFILE=/home/${USERNAME}/.bash_history" >> /etc/bash.bashrc && \
    echo "HISTSIZE=10000" >> /etc/bash.bashrc && \
    echo "HISTFILESIZE=20000" >> /etc/bash.bashrc && \
    echo "PROMPT_COMMAND='history -a'" >> /etc/bash.bashrc && \
    echo "shopt -s histappend" >> /etc/bash.bashrc

# Run supervisord using the main configuration file
# Supervisor now only manages SSH daemon (code-server disabled for Alpine compatibility)
CMD ["/usr/bin/supervisord", "-c", "/opt/supervisor/supervisord.conf"]
