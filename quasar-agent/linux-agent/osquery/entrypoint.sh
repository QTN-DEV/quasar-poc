#!/bin/bash

# Configure Wazuh agent
if [ -z "$WAZUH_MANAGER" ] || [ -z "$WAZUH_AGENT_NAME" ]; then
  echo "Error: Wazuh Manager IP and Agent Name are required."
  exit 1
fi

echo "Configuring Wazuh agent..."
sed -i "s|MANAGER_IP|$WAZUH_MANAGER|g" /var/ossec/etc/ossec.conf
sed -i "s|AGENT_NAME|$WAZUH_AGENT_NAME|g" /var/ossec/etc/ossec.conf

# Start Wazuh agent
echo "Starting Wazuh agent..."
service wazuh-agent start

# Start Osquery daemon
echo "Starting Osquery daemon..."
/usr/bin/osqueryd --config_path /etc/osquery/osquery.conf --daemonize=true

# Check if log files exist, wait for them to be created if necessary
OSQUERY_LOG="/var/log/osquery/osqueryd.results.log"
WAZUH_LOG="/var/ossec/logs/ossec.log"

echo "Waiting for log files to be created..."
while [ ! -f "$OSQUERY_LOG" ] || [ ! -f "$WAZUH_LOG" ]; do
  sleep 5
done

# Tail the logs to keep the container running
tail -f "$WAZUH_LOG" "$OSQUERY_LOG"