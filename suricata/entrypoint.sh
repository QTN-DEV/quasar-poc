#!/bin/bash

# Get the container's IP address
CONTAINER_IP=$(hostname -I | awk '{print $1}')

# Update the Suricata configuration file with the container's IP as HOME_NET
sed -i "s|HOME_NET:.*|HOME_NET: \"$CONTAINER_IP\"|" /etc/suricata/suricata.yaml

# Start Wazuh agent and Suricata services
service wazuh-agent start
service suricata start

# Tail the logs to keep the container running
tail -f /var/ossec/logs/ossec.log /var/log/suricata/eve.json