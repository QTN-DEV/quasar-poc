# Base image
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget sudo curl gnupg2 lsb-release make gcc autoconf libtool \
    libssl-dev pkg-config jq clamav clamav-daemon inotify-tools

# Set up Wazuh repository and install Wazuh Agent
RUN wget -qO - https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - \
    && echo "deb https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update && apt-get install -y wazuh-agent \
    && ls /var/ossec/bin/ || (echo "Wazuh agent installation failed" && exit 1)

# Create necessary directories and set permissions for ClamAV
RUN mkdir -p /var/run/clamav && chown -R clamav:clamav /var/run/clamav \
    && mkdir -p /var/log/clamav && chown -R clamav:clamav /var/log/clamav

# Update ClamAV database without using systemctl
RUN sed -i 's/^#Foreground .*/Foreground yes/' /etc/clamav/freshclam.conf \
    && freshclam

# Copy entrypoint and ClamAV inotify scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY clamav_inotify.sh /usr/local/bin/clamav_inotify.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/clamav_inotify.sh

# Expose volumes for logs and configuration
VOLUME ["/var/ossec/logs", "/var/log/clamav"]

# Expose necessary ports for Wazuh Agent communication
EXPOSE 1514/udp 1515/tcp

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]