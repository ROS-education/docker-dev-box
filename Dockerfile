# Multi-architecture support: Docker will automatically select the appropriate 
# architecture based on the build context or --platform flag.
# Supports both AMD64 (x86_64) and ARM64 (aarch64) architectures
# Pinning to a specific date tag for reproducibility
FROM ubuntu:noble-20250404

# Define ARG for host docker group GID.
# IMPORTANT: Set this at build time (--build-arg HOST_DOCKER_GID=$(getent group docker | cut -d: -f3))
# to match your HOST's docker group GID for socket permissions.
# Defaulting to 988 as per original, but overriding is recommended.
ARG HOST_DOCKER_GID=988

# Define automatic build arguments provided by BuildKit
# TARGETARCH will be 'amd64' or 'arm64' depending on the build target
ARG TARGETARCH
ARG TARGETPLATFORM

# Print build information for debugging
RUN echo "Building for platform: ${TARGETPLATFORM:-unknown}" && \
    echo "Target architecture: ${TARGETARCH:-unknown}" && \
    echo "Runtime architecture: $(uname -m)" && \
    echo "Runtime platform: $(uname -a)"

# Install base dependencies, including supervisor, clangd, wget, curl, unzip, and openssh-server
# These packages are generally available for both amd64 and arm64
# Add retry logic for improved reliability
RUN for i in 1 2 3; do \
        apt-get update && break || \
        (echo "Attempt $i failed, retrying in 5 seconds..." && sleep 5); \
    done && \
    apt-get install -y --no-install-recommends \
    # Base requirement
    ca-certificates \ 
    curl \
    gnupg \
    sudo \
    git \
    openssl \
    net-tools \
    supervisor \
    clangd \
    wget \ 
    unzip \
    openjdk-17-jre-headless \
    openssh-server \
    rsync \
    # Network utilities for host networking
    netcat-openbsd \
    iproute2 \
    iptables \
    iputils-ping \
    traceroute \
    dnsutils \
    tcpdump \
    nmap \
 && rm -rf /var/lib/apt/lists/*

# Add Docker's official GPG key & repository for CLI tools
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # Install Docker CLI tools in the same layer
    apt-get update && apt-get install -y --no-install-recommends \
    docker-ce-cli \
    docker-compose-plugin \
    docker-buildx-plugin \
 && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# Install Google Cloud CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    gnupg \
    lsb-release && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y --no-install-recommends google-cloud-sdk && \
    rm -rf /var/lib/apt/lists/*

# Set environment variable for Miniconda installation path
ENV MINICONDA_PATH=/opt/miniconda
# Set environment variable for updated PATH (Conda and ~/.local/bin added)
ENV PATH=$MINICONDA_PATH/bin:/home/ubuntu/.local/bin:$PATH

# Ensure sudo conda works for all users
RUN echo 'Defaults secure_path="/opt/miniconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' >> /etc/sudoers && \
    ln -s /opt/miniconda/bin/conda /usr/local/bin/conda

# Install Miniconda - Enhanced multi-architecture support
# Supports AMD64 (x86_64) and ARM64 (aarch64) architectures
RUN \
    # Determine the architecture suffix for the Miniconda filename
    # Use TARGETARCH if available (from BuildKit), otherwise detect at runtime
    if [ -n "${TARGETARCH:-}" ]; then \
        echo "Using BuildKit TARGETARCH: ${TARGETARCH}"; \
        case ${TARGETARCH} in \
            amd64) MINICONDA_ARCH_SUFFIX="x86_64" ;; \
            arm64) MINICONDA_ARCH_SUFFIX="aarch64" ;; \
            arm/v7) MINICONDA_ARCH_SUFFIX="aarch64" ;; \
            *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
        esac; \
    else \
        # Fallback to runtime detection
        echo "TARGETARCH not set, using runtime architecture detection"; \
        RUNTIME_ARCH=$(uname -m); \
        case ${RUNTIME_ARCH} in \
            x86_64) MINICONDA_ARCH_SUFFIX="x86_64" ;; \
            aarch64) MINICONDA_ARCH_SUFFIX="aarch64" ;; \
            armv7l) MINICONDA_ARCH_SUFFIX="aarch64" ;; \
            arm64) MINICONDA_ARCH_SUFFIX="aarch64" ;; \
            *) echo "Unsupported runtime architecture: ${RUNTIME_ARCH}"; exit 1 ;; \
        esac; \
    fi && \
    echo "Using Miniconda architecture: ${MINICONDA_ARCH_SUFFIX}" && \
    # Download the correct installer with retry logic
    wget --retry-connrefused --waitretry=5 --read-timeout=20 --timeout=15 --tries=5 \
         "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${MINICONDA_ARCH_SUFFIX}.sh" \
         -O ~/miniconda.sh && \
    # Verify download
    [ -f ~/miniconda.sh ] && [ -s ~/miniconda.sh ] || (echo "Miniconda download failed" && exit 1) && \
    # Install Miniconda
    bash ~/miniconda.sh -b -p $MINICONDA_PATH && \
    rm ~/miniconda.sh && \
    # Configure Conda
    $MINICONDA_PATH/bin/conda config --system --set auto_activate_base false && \
    $MINICONDA_PATH/bin/conda clean -afy && \
    # Verify installation
    $MINICONDA_PATH/bin/conda --version

# Create Conda environment 'dev_env' with specified tools
# Conda-forge generally has good multi-arch support (linux-64, linux-aarch64)
RUN conda create -n dev_env -c conda-forge \
    python=3.12 \
    nodejs=22 \
    cmake \
    cxx-compiler \
    make \
    gdb \
    -y && \
    conda clean -afy

# Activate the 'dev_env', install Firebase CLI globally using npm, and install ngrok  
RUN bash -c "source /opt/miniconda/etc/profile.d/conda.sh && conda activate dev_env && npm install -g firebase-tools"

# Install ngrok with enhanced multi-architecture support
# Supports AMD64, ARM64, and legacy ARM architectures
RUN /bin/bash -c 'set -e; \
    # Determine architecture - prefer TARGETARCH from BuildKit, fallback to runtime detection
    if [ -n "${TARGETARCH:-}" ]; then \
        echo "Using BuildKit TARGETARCH: ${TARGETARCH}"; \
        case ${TARGETARCH} in \
            amd64) NGROK_ZIP="ngrok-v3-stable-linux-amd64.zip" ;; \
            arm64) NGROK_ZIP="ngrok-v3-stable-linux-arm64.zip" ;; \
            arm/v7) NGROK_ZIP="ngrok-v3-stable-linux-arm.zip" ;; \
            arm/v6) NGROK_ZIP="ngrok-v3-stable-linux-arm.zip" ;; \
            *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
        esac; \
    else \
        # Runtime architecture detection
        ARCH=$(uname -m); \
        echo "TARGETARCH not set, detected runtime architecture: $ARCH"; \
        case $ARCH in \
            x86_64) NGROK_ZIP="ngrok-v3-stable-linux-amd64.zip" ;; \
            aarch64) NGROK_ZIP="ngrok-v3-stable-linux-arm64.zip" ;; \
            armv7l) NGROK_ZIP="ngrok-v3-stable-linux-arm.zip" ;; \
            armv6l) NGROK_ZIP="ngrok-v3-stable-linux-arm.zip" ;; \
            arm64) NGROK_ZIP="ngrok-v3-stable-linux-arm64.zip" ;; \
            *) echo "Unsupported runtime architecture: $ARCH"; exit 1 ;; \
        esac; \
    fi; \
    echo "Using ngrok package: $NGROK_ZIP"; \
    # Download with retry logic
    curl --retry 5 --retry-delay 2 --retry-max-time 30 \
         -O https://bin.equinox.io/c/bNyj1mQVY4c/${NGROK_ZIP}; \
    # Verify download
    [ -f ${NGROK_ZIP} ] && [ -s ${NGROK_ZIP} ] || (echo "ngrok download failed" && exit 1); \
    unzip -o ${NGROK_ZIP}; \
    chmod +x ngrok; \
    mv ngrok /usr/local/bin/ngrok; \
    rm ${NGROK_ZIP}; \
    # Verify installation
    ngrok version'

# Symlink Node.js and npm from Conda env to /usr/local/bin for sudo access
RUN ln -s /opt/miniconda/envs/dev_env/bin/node /usr/local/bin/node && \
    ln -s /opt/miniconda/envs/dev_env/bin/npm /usr/local/bin/npm

# Configure existing ubuntu user (architecture independent)
ARG USERNAME=ubuntu
RUN useradd -m -s /bin/bash ${USERNAME} || true && \
    usermod -u 1000 ${USERNAME} && \
    groupmod -g 1000 ${USERNAME} && \
    usermod --shell /bin/bash ${USERNAME} && \
    mkdir -p /home/${USERNAME}/.n8n && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.n8n && \
    mkdir -p /home/${USERNAME}/.conda && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.conda && \
    mkdir -p /home/${USERNAME}/.config && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config && \
    mkdir -p /workspace && \
    chown -R ${USERNAME}:${USERNAME} /workspace && \
    ln -sfn /workspace /home/${USERNAME}/workspace && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Create docker group with specific GID from build argument to match HOST docker group GID.
# Then add ubuntu user to this group to allow access to the mounted docker socket.
# (architecture independent)
RUN groupadd --gid ${HOST_DOCKER_GID:-988} docker || groupmod -g ${HOST_DOCKER_GID:-988} docker || true
RUN usermod -aG docker ubuntu

# Initialize Conda for the ubuntu user's bash shell and set default env
USER ubuntu
RUN /opt/miniconda/bin/conda init bash && \
    echo '# Source .bashrc for SSH sessions' > /home/ubuntu/.bash_profile && \
    echo 'if [ -f ~/.bashrc ]; then' >> /home/ubuntu/.bash_profile && \
    echo '    source ~/.bashrc' >> /home/ubuntu/.bash_profile && \
    echo 'fi' >> /home/ubuntu/.bash_profile && \
    # Ensure conda activation in .bashrc (conda init should handle this, but being explicit)
    echo '' >> /home/ubuntu/.bashrc && \
    echo '# Activate dev_env conda environment by default' >> /home/ubuntu/.bashrc && \
    echo 'conda activate dev_env' >> /home/ubuntu/.bashrc && \
    # Add helpful aliases for development
    echo 'alias ll="ls -la"' >> /home/ubuntu/.bashrc && \
    echo 'alias la="ls -A"' >> /home/ubuntu/.bashrc && \
    echo 'alias l="ls -CF"' >> /home/ubuntu/.bashrc

# Switch back to root for subsequent steps
USER root

# Allow ubuntu user to use sudo without password (architecture independent)
RUN echo 'ubuntu ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ubuntu-nopasswd && \
    chmod 0440 /etc/sudoers.d/ubuntu-nopasswd

# Install USB utilities and add ubuntu user to dialout and plugdev groups for USB access
RUN apt-get update && apt-get install -y --no-install-recommends \
    usbutils \
    libusb-1.0-0-dev \
    libudev-dev \
    && rm -rf /var/lib/apt/lists/* && \
    # Add ubuntu user to groups that typically have USB device access
    usermod -aG dialout ubuntu && \
    usermod -aG plugdev ubuntu && \
    usermod -aG tty ubuntu

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
    # Configure SSH server settings for VS Code Remote-SSH
    echo 'Port 2222' >> /etc/ssh/sshd_config && \
    echo 'ListenAddress 0.0.0.0' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'AuthorizedKeysFile .ssh/authorized_keys' >> /etc/ssh/sshd_config && \
    echo 'ChallengeResponseAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'UsePAM yes' >> /etc/ssh/sshd_config && \
    echo 'X11Forwarding yes' >> /etc/ssh/sshd_config && \
    echo 'PrintMotd no' >> /etc/ssh/sshd_config && \
    echo 'AcceptEnv LANG LC_*' >> /etc/ssh/sshd_config && \
    echo 'Subsystem sftp /usr/lib/openssh/sftp-server' >> /etc/ssh/sshd_config && \
    # SSH keepalive settings for better Remote-SSH experience
    echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config && \
    echo 'ClientAliveCountMax 10' >> /etc/ssh/sshd_config && \
    # Allow environment variables for conda activation
    echo 'AcceptEnv CONDA_DEFAULT_ENV CONDA_PREFIX PATH' >> /etc/ssh/sshd_config && \
    echo 'PermitUserEnvironment yes' >> /etc/ssh/sshd_config && \
    # Fix SSH login issues
    sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Set a default password for ubuntu user (change this in production!)
RUN echo 'ubuntu:ubuntu' | chpasswd

# Create SSH directory for ubuntu user
RUN mkdir -p /home/ubuntu/.ssh && \
    chown ubuntu:ubuntu /home/ubuntu/.ssh && \
    chmod 700 /home/ubuntu/.ssh && \
    # Create SSH environment file for conda activation
    echo 'PATH=/opt/miniconda/bin:/opt/miniconda/envs/dev_env/bin:/home/ubuntu/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' > /home/ubuntu/.ssh/environment && \
    echo 'CONDA_DEFAULT_ENV=dev_env' >> /home/ubuntu/.ssh/environment && \
    echo 'CONDA_PREFIX=/opt/miniconda/envs/dev_env' >> /home/ubuntu/.ssh/environment && \
    chown ubuntu:ubuntu /home/ubuntu/.ssh/environment && \
    chmod 600 /home/ubuntu/.ssh/environment

# Set Workdir as ubuntu user
USER ubuntu
WORKDIR /workspace

# Switch back to root user before CMD to start supervisord as root
USER root

# Copy local app directory structure (formerly supervisor)
# IMPORTANT: Ensure app/supervisord.conf DOES NOT try to start dockerd
COPY app /app
RUN chown -R ubuntu:ubuntu /app

VOLUME ["/workspace", "/home/ubuntu/.config", "/home/ubuntu/.conda"]
EXPOSE 2222

# --- IMPORTANT NOTES FOR SHARING HOST DOCKER DAEMON, USB DEVICES, AND HOST NETWORK ---
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
# 3. Host Network Access: For host network access, run with:
#    --network host
#    This gives the container direct access to host network interfaces.
#    Services will be accessible on host IP addresses directly.
#    SSH: host_ip:22
#
# 4. Build Argument: You SHOULD build this image with:
#    --build-arg HOST_DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 988)
#    Replace '988' with the actual GID if the command fails. This ensures the 'docker'
#    group inside the container has the same GID as the 'docker' group on your host,
#    granting the 'ubuntu' user permission to use the mounted socket. If the GID inside
#    doesn't match the GID owning the socket on the host, you'll get permission errors.
#
# 5. Supervisor Configuration: Ensure your app/supervisord.conf file
#    DOES NOT contain a [program:dockerd] section. Supervisor should only manage
#    SSH and any other desired services within the container.
#
# 6. USB Device Discovery: The container includes usbutils (lsusb) and proper group
#    memberships for USB device access. The ubuntu user is added to dialout, plugdev,
#    and tty groups for comprehensive device access.
#
# 7. Example Docker Run Command for Full Host Integration:
#    docker run --privileged --network host -v /dev:/dev \
#               -v /var/run/docker.sock:/var/run/docker.sock \
#               -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#               your-image-name
#
# 8. Host Network Benefits:
#    - Direct access to host network interfaces
#    - No port mapping needed - services bind to host ports directly
#    - Better network performance
#    - Access to host network configuration and routes
#    - Can bind to specific host network interfaces
#    --build-arg HOST_DOCKER_GID=$(getent group docker | cut -d: -f3 || echo 988)
#    Replace '988' with the actual GID if the command fails. This ensures the 'docker'
#    group inside the container has the same GID as the 'docker' group on your host,
#    granting the 'ubuntu' user permission to use the mounted socket. If the GID inside
#    doesn't match the GID owning the socket on the host, you'll get permission errors.
#
# 4. Supervisor Configuration: Ensure your app/supervisord.conf file
#    DOES NOT contain a [program:dockerd] section. Supervisor should only manage
#    SSH and any other desired services within the container.
#
# 5. USB Device Discovery: The container includes usbutils (lsusb) and proper group
#    memberships for USB device access. The ubuntu user is added to dialout, plugdev,
#    and tty groups for comprehensive device access.
#
# 6. Example Docker Run Command for Full USB Access:
#    docker run --privileged -v /dev:/dev -v /var/run/docker.sock:/var/run/docker.sock \
#               -p 2222:22 your-image-name

# Install bash-completion and configure bash history
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash-completion && \
    echo "source /usr/share/bash-completion/bash_completion" >> /etc/bash.bashrc && \
    echo "HISTFILE=/home/ubuntu/.bash_history" >> /etc/bash.bashrc && \
    echo "HISTSIZE=10000" >> /etc/bash.bashrc && \
    echo "HISTFILESIZE=20000" >> /etc/bash.bashrc && \
    echo "PROMPT_COMMAND='history -a'" >> /etc/bash.bashrc && \
    echo "shopt -s histappend" >> /etc/bash.bashrc && \
    # Configure bash completion specifically for ubuntu user
    echo "# Enable bash completion" >> /home/ubuntu/.bashrc && \
    echo "if ! shopt -oq posix; then" >> /home/ubuntu/.bashrc && \
    echo "  if [ -f /usr/share/bash-completion/bash_completion ]; then" >> /home/ubuntu/.bashrc && \
    echo "    . /usr/share/bash-completion/bash_completion" >> /home/ubuntu/.bashrc && \
    echo "  elif [ -f /etc/bash_completion ]; then" >> /home/ubuntu/.bashrc && \
    echo "    . /etc/bash_completion" >> /home/ubuntu/.bashrc && \
    echo "  fi" >> /home/ubuntu/.bashrc && \
    echo "fi" >> /home/ubuntu/.bashrc && \
    rm -rf /var/lib/apt/lists/*

# Run supervisord using the main configuration file
# Supervisor should now only manage SSH and any other non-docker services
CMD ["/usr/bin/supervisord", "-c", "/app/supervisord.conf"]
