#!/bin/bash

# Get the container's IP address
CONTAINER_IP=$(hostname -I | awk '{print $1}')

# Update the Suricata configuration file with the container's IP as HOME_NET
sed -i "s|HOME_NET:.*|HOME_NET: \"$CONTAINER_IP\"|" /etc/suricata/suricata.yaml
sed -i "s|EXTERNAL_NET:.*|EXTERNAL_NET: \"any\"|" /etc/suricata/suricata.yaml
sed -i "s|default-rule-path:.*|default-rule-path: /etc/suricata/rules|" /etc/suricata/suricata.yaml
sed -i "/rule-files:/a\  - \"*.rules\"" /etc/suricata/suricata.yaml
sed -i "/rule-files:/,/suricata.rules/d" /etc/suricata/suricata.yaml

# Enable stats
sed -i "/# Global stats configuration/,+1 s/enabled: .*/enabled: yes/" /etc/suricata/suricata.yaml

# Configure af-packet interface to enX0
sed -i "/af-packet:/,+1 s/interface: .*/interface: enX0/" /etc/suricata/suricata.yaml

# Start Wazuh agent and Suricata services
service wazuh-agent start
service suricata start

# Tail the logs to keep the container running
tail -f /var/ossec/logs/ossec.log /var/log/suricata/eve.json