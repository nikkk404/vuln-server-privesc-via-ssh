# Use the specified Ubuntu image
FROM ubuntu:22.04

# Install necessary packages
RUN apt-get update && apt-get install -y \
    gcc \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for SSH access
RUN useradd -m -s /bin/bash tester && echo 'tester:password123' | chpasswd

# Set up the vulnerable SUID binary
WORKDIR /usr/src/app
COPY vuln.c .
RUN gcc -o /usr/local/bin/vuln vuln.c \
    && chown root:root /usr/local/bin/vuln \
    && chmod 4755 /usr/local/bin/vuln

# Create the flag file
RUN echo "FLAG{hackathon_privesc_success_2025}" > /root/flag.txt \
    && chown root:root /root/flag.txt \
    && chmod 600 /root/flag.txt

# Configure SSH
RUN mkdir /var/run/sshd
RUN echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
EXPOSE 22

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]
