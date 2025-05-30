FROM arm64v8/debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    openssh-server \
    git \
    curl \
    wget \
    nano \
    sudo \
    build-essential \
    gdb \
    python3 \
    python3-pip \
    usbutils \
    libusb-1.0-0 \
    udisks2 \
    udev \
    util-linux \
    fdisk \
    bzip2 \
    ca-certificates \
    && apt-get clean

# Setup SSH
RUN mkdir -p /var/run/sshd
RUN echo 'root:password' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# SSH login fix
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Create a dev user
RUN useradd -m -s /bin/bash dev && \
    echo "dev:password" | chpasswd && \
    adduser dev sudo && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Miniconda
ENV CONDA_DIR /opt/miniconda3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -O /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda clean -a -y

# Make conda command available to root only (not in regular user PATH)
# RUN echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> /etc/profile && \
#     echo "conda activate" >> /etc/profile && \
#     echo "export PATH=$CONDA_DIR/bin:$PATH" >> /etc/profile

# Give sudo access to conda command for dev user
RUN echo "dev ALL=(ALL) NOPASSWD: $CONDA_DIR/bin/conda *" >> /etc/sudoers && \
    echo "Defaults env_keep += \"PATH\"" >> /etc/sudoers

# Create dev_env environment with Python tools
# Note: C/C++ tools (gcc, g++, make) are already installed via build-essential
RUN conda create -y -n dev_env python=3.11 && \
    conda install -y -n dev_env \
        numpy \
        pandas \
        matplotlib \
        jupyter && \
    conda install -y -n dev_env -c conda-forge \
        cmake && \
    conda clean -a -y

# Set up workspace directory
RUN mkdir -p /home/dev/workspace
RUN chown -R dev:dev /home/dev/workspace

# Create mount points for USB devices
RUN mkdir -p /media
RUN chmod 777 /media

# Configure SSH for better VS Code remote experience
RUN echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config
RUN echo "ClientAliveCountMax 120" >> /etc/ssh/sshd_config

# Configure dev user's bash profile (conda requires sudo)
RUN echo '. /opt/miniconda3/etc/profile.d/conda.sh' >> /home/dev/.bashrc && \
    echo 'alias conda="sudo /opt/miniconda3/bin/conda"' >> /home/dev/.bashrc && \
    echo 'alias sconda="/usr/local/bin/conda-wrapper.sh"' >> /home/dev/.bashrc && \
    echo 'export CONDA_EXE="/opt/miniconda3/bin/conda"' >> /home/dev/.bashrc && \
    echo 'sudo /opt/miniconda3/bin/conda activate dev_env' >> /home/dev/.bashrc

# Add USB access rules
COPY 99-usb-permissions.rules /etc/udev/rules.d/

# Add USB mount helper script
RUN echo '#!/bin/bash\n\
if [ "$#" -ne 1 ]; then\n\
    echo "Usage: $0 <device>"\n\
    echo "Example: $0 /dev/sdb1"\n\
    exit 1\n\
fi\n\
\n\
DEVICE=$1\n\
MOUNT_POINT="/media/$(basename $DEVICE)"\n\
\n\
mkdir -p "$MOUNT_POINT"\n\
mount "$DEVICE" "$MOUNT_POINT"\n\
\n\
if [ $? -eq 0 ]; then\n\
    echo "Device $DEVICE mounted at $MOUNT_POINT"\n\
    ls -la "$MOUNT_POINT"\n\
else\n\
    echo "Failed to mount $DEVICE"\n\
fi' > /usr/local/bin/mount-usb.sh

RUN chmod +x /usr/local/bin/mount-usb.sh

# Add SSH key management script
COPY manage-ssh-keys.sh /usr/local/bin/manage-ssh-keys.sh
RUN chmod +x /usr/local/bin/manage-ssh-keys.sh

# Add conda wrapper script for easier usage
RUN echo '#!/bin/bash\n\
# Conda wrapper script to handle sudo requirements\n\
CONDA_BIN="/opt/miniconda3/bin/conda"\n\
\n\
if [ "$#" -eq 0 ]; then\n\
    echo "Usage: conda <command> [args...]"\n\
    echo "Available commands: list, env, install, create, activate, etc."\n\
    exit 1\n\
fi\n\
\n\
# Handle conda activate specially since it needs to be sourced\n\
if [ "$1" = "activate" ]; then\n\
    if [ "$#" -gt 1 ]; then\n\
        source /opt/miniconda3/bin/activate "$2"\n\
    else\n\
        source /opt/miniconda3/bin/activate\n\
    fi\n\
else\n\
    # For all other conda commands, use sudo\n\
    sudo "$CONDA_BIN" "$@"\n\
fi' > /usr/local/bin/conda-wrapper.sh && \
    chmod +x /usr/local/bin/conda-wrapper.sh

WORKDIR /home/dev/workspace

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
