#!/bin/bash
# Build the Docker image
docker build -t privesc-lab .

# Run the container, mapping port 2222 on host to 22 in container
docker run -d -p 2222:22 --name privesc-container privesc-lab
