#!/bin/bash

# Check and substitute Wazuh Manager IP in ossec.conf
if [[ -z "$WAZUH_MANAGER" ]]; then
    echo "Error: Wazuh Manager IP not set. Exiting."
    exit 1
fi
sed -i "s/MANAGER_IP/$WAZUH_MANAGER/g" /var/ossec/etc/ossec.conf

echo "Starting Wazuh Agent..."
/var/ossec/bin/ossec-control start || {
    echo "Failed to start Wazuh Agent."
    exit 1
}

echo "Starting ClamAV daemon..."
clamd || {
    echo "Failed to start ClamAV daemon."
    exit 1
}

# Check if ClamAV socket directory exists and has the correct permissions
if [[ ! -d /var/run/clamav ]]; then
    mkdir -p /var/run/clamav
    chown -R clamav:clamav /var/run/clamav
fi

echo "Starting ClamAV inotify monitoring..."
/usr/local/bin/clamav_inotify.sh || {
    echo "Failed to start ClamAV inotify monitoring."
    exit 1
}

# Keep the container running
tail -f /var/log/ossec/ossec.log /var/log/clamav/clamd.log
