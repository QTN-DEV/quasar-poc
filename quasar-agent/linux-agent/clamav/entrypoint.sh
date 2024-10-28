#!/bin/bash

# Get the container's IP address
CONTAINER_IP=$(hostname -I | awk '{print $1}')

# Update the Suricata configuration file with the container's IP as HOME_NET
sed -i "s|HOME_NET:.*|HOME_NET: \"$CONTAINER_IP\"|" /etc/suricata/suricata.yaml
sed -i "s|EXTERNAL_NET:.*|EXTERNAL_NET: \"any\"|" /etc/suricata/suricata.yaml
sed -i "s|default-rule-path:.*|default-rule-path: /etc/suricata/rules|" /etc/suricata/suricata.yaml
sed -i "/rule-files:/a\  - \"*.rules\"" /etc/suricata/suricata.yaml
sed -i "/rule-files:/,/suricata.rules/d" /etc/suricata/suricata.yaml
sed -i "/af-packet:/,+1 s/interface: .*/interface: eth0/" /etc/suricata/suricata.yaml

# Ensure the Suricata log configuration is only added once
if ! grep -q "/var/log/suricata/eve.json" /var/ossec/etc/ossec.conf; then
    # Add Suricata log monitoring configuration
    sed -i '/<ossec_config>/a\  <localfile>\n    <log_format>json</log_format>\n    <location>/var/log/suricata/eve.json</location>\n  </localfile>' /var/ossec/etc/ossec.conf
fi

# Enable stats
sed -i "/# Global stats configuration/,+1 s/enabled: .*/enabled: yes/" /etc/suricata/suricata.yaml

# Start Wazuh agent and Suricata services
service wazuh-agent start
service suricata start

# Check if Suricata log exists
if [ ! -f /var/log/suricata/eve.json ]; then
    echo "Warning: /var/log/suricata/eve.json not found. Suricata may not be generating logs."
fi

# Tail the logs to keep the container running
tail -f /var/ossec/logs/ossec.log /var/log/suricata/eve.json