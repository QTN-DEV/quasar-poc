# Use Ubuntu as base image
FROM ubuntu:latest

ENV WAZUH_MANAGER=13.214.175.48
ENV WAZUH_AGENT_NAME=osquery-poc

# Install necessary dependencies, Wazuh agent, and Osquery
RUN apt-get update && apt-get install -y wget sudo lsb-release adduser curl software-properties-common \
    netcat dnsutils gnupg2 && \
    wget -qO - https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    echo "deb https://packages.wazuh.com/4.x/apt stable main" > /etc/apt/sources.list.d/wazuh.list && \
    apt-get update && apt-get install -y wazuh-agent && \
    mkdir -p /etc/apt/keyrings && \
    curl -L https://pkg.osquery.io/deb/pubkey.gpg | tee /etc/apt/keyrings/osquery.asc && \
    add-apt-repository 'deb [arch=amd64 signed-by=/etc/apt/keyrings/osquery.asc] https://pkg.osquery.io/deb deb main' && \
    apt-get update && apt-get install -y osquery

# Copy custom osquery configuration
COPY osquery.conf /etc/osquery/osquery.conf

# Enable and start Wazuh agent service
RUN systemctl enable wazuh-agent && \
    systemctl start wazuh-agent

# Copy custom entrypoint script to manage Osquery and Wazuh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose necessary ports
EXPOSE 1514 1515

# Set entrypoint to manage both Osquery and Wazuh agent
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]