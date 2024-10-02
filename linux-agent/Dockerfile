FROM ubuntu:latest

ENV WAZUH_MANAGER=13.214.175.48
ENV WAZUH_AGENT_NAME=quasar-poc

# Install dependencies, Suricata, and Wazuh agent
RUN apt-get update && apt-get install -y wget sudo lsb-release adduser curl software-properties-common && \
    add-apt-repository ppa:oisf/suricata-stable && \
    apt-get update && apt-get install -y suricata

# Install Wazuh agent
RUN wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb && \
    WAZUH_MANAGER=$WAZUH_MANAGER WAZUH_AGENT_NAME=$WAZUH_AGENT_NAME dpkg -i ./wazuh-agent_4.9.0-1_amd64.deb && \
    rm ./wazuh-agent_4.9.0-1_amd64.deb

# Download and configure Suricata ruleset
RUN cd /tmp/ && \
    curl -LO https://rules.emergingthreats.net/open/suricata-6.0.8/emerging.rules.tar.gz && \
    tar -xvzf emerging.rules.tar.gz && \
    mkdir -p /etc/suricata/rules && \
    mv rules/*.rules /etc/suricata/rules/ && \
    chmod 640 /etc/suricata/rules/*.rules

# Script to dynamically set HOME_NET based on container IP
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Add Suricata logging to Wazuh agent config in the right position
RUN sed -i '/<ossec_config>/a\  <localfile>\n    <log_format>json</log_format>\n    <location>/var/log/suricata/eve.json</location>\n  </localfile>' /var/ossec/etc/ossec.conf

# Expose Suricata eve.json log file path
VOLUME ["/var/log/suricata"]

# Use custom entrypoint script to start services
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]