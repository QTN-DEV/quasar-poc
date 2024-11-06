#!/bin/bash

# Start Osquery daemon directly
echo "Starting Osquery daemon..."
/usr/bin/osqueryd --config_path /etc/osquery/osquery.conf --daemonize=true

# Check if log file exists, wait for it to be created if necessary
LOG_FILE="/var/log/osquery/osqueryd.results.log"
if [ ! -f "$LOG_FILE" ]; then
    echo "Waiting for Osquery log file to be created..."
    sleep 5
fi

# Tail the Osquery log to keep the container running
tail -f "$LOG_FILE"