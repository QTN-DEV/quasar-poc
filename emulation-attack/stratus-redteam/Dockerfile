# Base image
FROM ubuntu:20.04

# Install prerequisites
RUN apt-get update && \
    apt-get install -y wget tar curl unzip sudo bash && \
    apt-get clean

# Install Stratus Red Team
RUN wget https://github.com/DataDog/stratus-red-team/releases/download/v2.8.0/stratus-red-team_2.8.0_Linux_x86_64.tar.gz && \
    tar xvf stratus-red-team_2.8.0_Linux_x86_64.tar.gz && \
    mv stratus /usr/local/bin/stratus && \
    rm stratus-red-team_2.8.0_Linux_x86_64.tar.gz

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm -rf awscliv2.zip aws/

# Install GCP CLI
RUN apt-get update && apt-get install -y python3 python3-pip && \
    curl -sSL https://sdk.cloud.google.com | bash && \
    echo "source /root/google-cloud-sdk/path.bash.inc" >> /root/.bashrc

# Set up environment variables
ENV PATH="/root/google-cloud-sdk/bin:$PATH"

# Add bash script for user interaction
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Entrypoint script for dynamic attack selection
ENTRYPOINT ["/entrypoint.sh"]