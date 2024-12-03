#!/bin/bash

# Function to print messages with timestamp
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Exit on errors
set -e

# 1. Install Suricata
log_message "Adding Suricata repository and installing Suricata..."
sudo add-apt-repository ppa:oisf/suricata-stable -y
sudo apt-get update
sudo apt-get install suricata -y
log_message "Suricata installed successfully."

# 2. Download and extract Emerging Threats Suricata ruleset
log_message "Downloading and extracting Emerging Threats ruleset..."
cd /tmp/
curl -LO https://rules.emergingthreats.net/open/suricata-6.0.8/emerging.rules.tar.gz
sudo tar -xvzf emerging.rules.tar.gz
sudo mkdir -p /etc/suricata/rules
sudo mv rules/*.rules /etc/suricata/rules/
sudo chmod 640 /etc/suricata/rules/*.rules
log_message "Emerging Threats ruleset configured successfully."

# 3. Update Suricata configuration
log_message "Updating Suricata configuration..."
SURICATA_CONFIG="/etc/suricata/suricata.yaml"

if [ -f "$SURICATA_CONFIG" ]; then
    log_message "Detected Suricata configuration file at $SURICATA_CONFIG."
else
    log_message "Error: Suricata configuration file not found at $SURICATA_CONFIG. Exiting."
    exit 1
fi

UBUNTU_CIDR=$(ip -o -4 addr show | awk '{print $4}' | grep -v "127.0.0.1" | head -1)
INTERFACE=$(ip -o -4 addr show | awk '{print $2}' | grep -v "lo" | head -1)

# Ensure 'HOME_NET' and 'EXTERNAL_NET' are configured
sudo sed -i "s|HOME_NET: .*|HOME_NET: \"$UBUNTU_CIDR\"|g" "$SURICATA_CONFIG"
sudo sed -i "s|EXTERNAL_NET: .*|EXTERNAL_NET: \"any\"|g" "$SURICATA_CONFIG"

# Ensure 'stats' configuration is set
if grep -q "^stats:" "$SURICATA_CONFIG"; then
    log_message "Updating existing 'stats' configuration."
    sudo sed -i '/^stats:/,/^$/d' "$SURICATA_CONFIG"
    sudo sed -i '/# Global stats configuration/a stats:\n  enabled: yes' "$SURICATA_CONFIG"
else
    log_message "Adding 'stats' configuration."
    sudo sed -i '/# Global stats configuration/a stats:\n  enabled: yes' "$SURICATA_CONFIG"
fi

# Ensure 'af-packet' configuration is set
if grep -q "^af-packet:" "$SURICATA_CONFIG"; then
    log_message "Updating existing 'af-packet' configuration."
    sudo sed -i '/^af-packet:/,/^$/d' "$SURICATA_CONFIG"
    sudo sed -i '/# Linux high speed capture support/a af-packet:\n  - interface: '"$INTERFACE" "$SURICATA_CONFIG"
else
    log_message "Adding 'af-packet' configuration."
    sudo sed -i '/# Linux high speed capture support/a af-packet:\n  - interface: '"$INTERFACE" "$SURICATA_CONFIG"
fi

log_message "Suricata configuration updated. HOME_NET: $UBUNTU_CIDR, Network Interface: $INTERFACE."

# 4. Restart Suricata service
log_message "Restarting Suricata service..."
sudo systemctl restart suricata
log_message "Suricata service restarted successfully."

# 5. Configure Wazuh agent to read Suricata logs
log_message "Configuring Wazuh agent to read Suricata logs..."
WAZUH_CONFIG_FILE="/var/ossec/etc/ossec.conf"

# Check if the file exists with sudo
if ! sudo test -f "$WAZUH_CONFIG_FILE"; then
    log_message "Error: Wazuh configuration file not found at $WAZUH_CONFIG_FILE. Exiting."
    exit 1
fi

# Ensure write permissions with sudo
if ! sudo test -w "$WAZUH_CONFIG_FILE"; then
    log_message "Error: Insufficient permissions to modify $WAZUH_CONFIG_FILE. Please run the script with sudo."
    exit 1
fi

# Define the Suricata configuration block
SURICATA_LOG_CONFIG="    <log_format>json</log_format>\n    <location>/var/log/suricata/eve.json</location>"

# Check if Suricata configuration already exists
if ! sudo grep -q "/var/log/suricata/eve.json" "$WAZUH_CONFIG_FILE"; then
    log_message "Adding Suricata log configuration to Wazuh."

    # Insert the configuration inside the existing <ossec_config> block before the closing </ossec_config>
    sudo sed -i "/<\/ossec_config>/i \\
  <localfile>\n$SURICATA_LOG_CONFIG\n  </localfile>" "$WAZUH_CONFIG_FILE"

    log_message "Suricata log configuration added successfully."
else
    log_message "Suricata log configuration already exists. Skipping addition."
fi

log_message "Wazuh configuration updated successfully."