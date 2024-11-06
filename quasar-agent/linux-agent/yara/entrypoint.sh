#!/bin/bash

# Ensure required environment variables are provided
if [ -z "$WAZUH_MANAGER" ] || [ -z "$WAZUH_AGENT_NAME" ]; then
  echo "Error: Wazuh Manager IP and Agent Name are required."
  exit 1
fi

# Configure Wazuh agent
echo "Configuring Wazuh agent..."
sed -i "s|MANAGER_IP|$WAZUH_MANAGER|g" /var/ossec/etc/ossec.conf
sed -i "s|AGENT_NAME|$WAZUH_AGENT_NAME|g" /var/ossec/etc/ossec.conf

# Install Wazuh agent
echo "Installing Wazuh agent..."
dpkg -i /wazuh-agent_4.9.1-1_amd64.deb

# Configure the directory for YARA scanning in Wazuh config
if ! grep -q "/tmp/yara/malware" /var/ossec/etc/ossec.conf; then
  sed -i '/<syscheck>/a\  <directories realtime="yes">/tmp/yara/malware</directories>' /var/ossec/etc/ossec.conf
fi

# Start Wazuh agent
service wazuh-agent start

# Tail the logs to keep the container running
tail -f /var/ossec/logs/ossec.log