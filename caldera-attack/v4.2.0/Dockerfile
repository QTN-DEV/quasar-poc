# Use a lightweight Ubuntu base image
FROM ubuntu:22.04 AS base

# Update and install necessary tools
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    curl \
    python3 \
    python3-venv \
    python3-pip \
    git \
    && apt-get clean

# Clone the CALDERA repository with the specific version (4.2.0) recursively to pull all plugins
RUN git clone https://github.com/mitre/caldera.git --recursive --branch 4.2.0 /app/caldera

# Set working directory
WORKDIR /app/caldera

# Install Python requirements
RUN pip3 install --no-cache-dir -r requirements.txt

# Expose the port used by CALDERA
EXPOSE 8888

# Command to run the CALDERA server
CMD ["python3", "server.py", "--insecure"]