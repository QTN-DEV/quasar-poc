FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y wget sudo lsb-release adduser curl software-properties-common

# Add Suricata PPA (only install if the option is selected in entrypoint)
RUN add-apt-repository ppa:oisf/suricata-stable

# Download Wazuh agent
RUN wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.1-1_amd64.deb

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose Suricata eve.json log file path (only applicable if Suricata is installed)
VOLUME ["/var/log/suricata"]

# Use custom entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]