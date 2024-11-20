#!/bin/bash

# Clear the console for a clean start
clear

# Define the Wazuh package URL and agent version
WAZUH_PACKAGE_URL="https://packages.wazuh.com/4.x/deb/wazuh-agent_4.8.0-1_amd64.deb"
PACKAGE_NAME="wazuh-agent_4.8.0-1_amd64.deb"

# Prompt for Wazuh Manager IP
read -p "Enter the Wazuh Manager IP: " WAZUH_MANAGER
if [[ -z "$WAZUH_MANAGER" ]]; then
    echo "Error: Wazuh Manager IP is required."
    exit 1
fi

# Prompt for Wazuh Agent Name
read -p "Enter the Wazuh Agent Name: " WAZUH_AGENT_NAME
if [[ -z "$WAZUH_AGENT_NAME" ]]; then
    echo "Error: Wazuh Agent Name is required."
    exit 1
fi

# Download the Wazuh package
echo "Downloading Wazuh Agent package from $WAZUH_PACKAGE_URL..."
wget -O "/tmp/$PACKAGE_NAME" "$WAZUH_PACKAGE_URL"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to download the Wazuh Agent package."
    exit 1
fi
echo "Download completed. Package saved to /tmp/$PACKAGE_NAME."

# Install the Wazuh Agent package
echo "Installing Wazuh Agent..."
sudo dpkg -i "/tmp/$PACKAGE_NAME"
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to install the Wazuh Agent package."
    exit 1
fi
echo "Wazuh Agent installed successfully."

# Configure Wazuh Agent
echo "Configuring Wazuh Agent..."
sudo sed -i "s/MANAGER_IP/$WAZUH_MANAGER/" /var/ossec/etc/ossec.conf
sudo sed -i "s/AGENT_NAME/$WAZUH_AGENT_NAME/" /var/ossec/etc/ossec.conf

# Start the Wazuh Agent service
echo "Starting Wazuh Agent service..."
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to start the Wazuh Agent service."
    exit 1
fi
echo "Wazuh Agent service started successfully."

# Confirm successful installation
echo "Installation complete. You can verify the Wazuh Agent status using the command:"
echo "sudo systemctl status wazuh-agent"