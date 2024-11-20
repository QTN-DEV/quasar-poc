# Base image
FROM ubuntu:22.04

# Install prerequisites
RUN apt-get update && apt-get install -y \
    wget sudo lsb-release adduser curl software-properties-common gnupg

# Install Wazuh agent
RUN wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.1-1_amd64.deb && \
    dpkg -i wazuh-agent_4.9.1-1_amd64.deb && \
    rm wazuh-agent_4.9.1-1_amd64.deb

# Add Osquery GPG key and repository
ARG OSQUERY_KEY
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$OSQUERY_KEY" && \
    add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main' && \
    apt-get update && apt-get install -y osquery

# Create necessary directories
RUN mkdir -p /etc/osquery /var/ossec/logs /var/log/osquery

# Copy configuration files
COPY osquery.conf /etc/osquery/osquery.conf

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose volumes for logs
VOLUME ["/var/ossec/logs", "/var/log/osquery"]

# Run entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]