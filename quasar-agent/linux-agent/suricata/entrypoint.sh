#!/bin/bash

# Check if the required environment variables are provided
if [ -z "$WAZUH_MANAGER" ] || [ -z "$WAZUH_AGENT_NAME" ]; then
  echo "Error: Wazuh Manager IP and Agent Name are required."
  exit 1
fi

# Update the Wazuh agent configuration with the provided Manager IP and Agent Name
echo "Configuring Wazuh agent..."
sed -i "s|MANAGER_IP|$WAZUH_MANAGER|g" /var/ossec/etc/ossec.conf
sed -i "s|AGENT_NAME|$WAZUH_AGENT_NAME|g" /var/ossec/etc/ossec.conf

# Install Wazuh agent
echo "Installing Wazuh agent with Manager IP: $WAZUH_MANAGER and Agent Name: $WAZUH_AGENT_NAME"
dpkg -i /wazuh-agent_4.9.1-1_amd64.deb

# Check if Suricata needs to be installed
if [ "$INSTALL_SURICATA" = true ]; then
  echo "Installing Suricata..."
  apt-get update && apt-get install -y suricata
  # Download and configure Suricata ruleset
  curl -LO https://rules.emergingthreats.net/open/suricata-6.0.8/emerging.rules.tar.gz
  tar -xvzf emerging.rules.tar.gz
  mkdir -p /etc/suricata/rules
  mv rules/*.rules /etc/suricata/rules/
  chmod 640 /etc/suricata/rules/*.rules

  # Get the container's IP address
  CONTAINER_IP=$(hostname -I | awk '{print $1}')

  # Update the Suricata configuration file with the container's IP as HOME_NET
  sed -i "s|HOME_NET:.*|HOME_NET: \"$CONTAINER_IP\"|" /etc/suricata/suricata.yaml
  sed -i "s|EXTERNAL_NET:.*|EXTERNAL_NET: \"any\"|" /etc/suricata/suricata.yaml
  sed -i "s|default-rule-path:.*|default-rule-path: /etc/suricata/rules|" /etc/suricata/suricata.yaml
  sed -i "/rule-files:/a\  - \"*.rules\"" /etc/suricata/suricata.yaml
  sed -i "/rule-files:/,/suricata.rules/d" /etc/suricata/suricata.yaml
  sed -i "/af-packet:/,+1 s/interface: .*/interface: eth0/" /etc/suricata/suricata.yaml

  # Add Suricata log monitoring configuration in Wazuh
  if ! grep -q "/var/log/suricata/eve.json" /var/ossec/etc/ossec.conf; then
      sed -i '/<ossec_config>/a\  <localfile>\n    <log_format>json</log_format>\n    <location>/var/log/suricata/eve.json</location>\n  </localfile>' /var/ossec/etc/ossec.conf
  fi

  # Enable stats for Suricata
  sed -i "/# Global stats configuration/,+1 s/enabled: .*/enabled: yes/" /etc/suricata/suricata.yaml

  # Start Suricata service
  service suricata start

  echo "Suricata installed and started"
fi

# Start Wazuh agent
service wazuh-agent start

# Check if Suricata log exists
if [ "$INSTALL_SURICATA" = true ] && [ ! -f /var/log/suricata/eve.json ]; then
    echo "Warning: /var/log/suricata/eve.json not found. Suricata may not be generating logs."
fi

# Tail the logs to keep the container running
tail -f /var/ossec/logs/ossec.log ${INSTALL_SURICATA:+/var/log/suricata/eve.json}