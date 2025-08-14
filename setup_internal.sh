#!/bin/bash

# Install necessary packages
apt-get update && apt-get install -y \
    gcc \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for SSH access
useradd -m -s /bin/bash tester && echo 'tester:password123' | chpasswd

# Set up the vulnerable SUID binary
gcc -o /usr/local/bin/vuln vuln.c \
    && chown root:root /usr/local/bin/vuln \
    && chmod 4755 /usr/local/bin/vuln

# Configure SSH
mkdir -p /var/run/sshd
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
