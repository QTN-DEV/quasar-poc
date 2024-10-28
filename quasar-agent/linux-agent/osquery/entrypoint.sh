#!/bin/bash

# Start Wazuh agent
service wazuh-agent start

# Start Osquery daemon
service osqueryd start

# Check if Osquery log exists
if [ ! -f /var/log/osquery/osqueryd.results.log ]; then
    echo "Warning: /var/log/osquery/osqueryd.results.log not found. Osquery may not be generating logs."
fi

# Tail the logs to keep the container running
tail -f /var/ossec/logs/ossec.log /var/log/osquery/osqueryd.results.log