#!/bin/bash

# Function to prompt for Wazuh Manager IP and Agent Name
prompt_wazuh_details() {
    read -p "Enter Wazuh Manager IP: " wazuh_manager_ip
    read -p "Enter Wazuh Agent name: " wazuh_agent_name
}

# Function to install Wazuh Agent
install_wazuh_agent() {
    echo "Installing Wazuh Agent..."
    wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.8.0-1_amd64.deb
    sudo WAZUH_MANAGER="$wazuh_manager_ip" WAZUH_AGENT_NAME="$wazuh_agent_name" dpkg -i ./wazuh-agent_4.8.0-1_amd64.deb
    sudo systemctl daemon-reload
    sudo systemctl enable wazuh-agent
    sudo systemctl start wazuh-agent
    echo "Wazuh Agent installation completed."
}

# Function to uninstall Wazuh Agent
uninstall_wazuh_agent() {
    echo "Uninstalling Wazuh Agent..."
    sudo apt-get remove --purge wazuh-agent -y
    sudo systemctl disable wazuh-agent
    sudo systemctl daemon-reload
    echo "Wazuh Agent uninstalled successfully."
}

# Function to install ClamAV
install_clamav() {
    echo "Installing ClamAV..."
    sudo apt-get install clamav clamav-daemon -y
    sudo systemctl stop clamav-freshclam
    sudo freshclam
    sudo systemctl start clamav-freshclam
    sudo systemctl enable clamav-daemon
    sudo systemctl start clamav-daemon
    echo "ClamAV installation completed."
}

# Function to install YARA
install_yara() {
    echo "Installing YARA..."
    sudo apt-get install yara -y
    echo "YARA installation completed."
}

# Function to install Suricata
install_suricata() {
    echo "Installing Suricata..."
    sudo add-apt-repository ppa:oisf/suricata-stable -y
    sudo apt-get update
    sudo apt-get install suricata -y
    sudo systemctl enable suricata
    sudo systemctl start suricata
    echo "Suricata installation completed."
}

get_homenet_ip() {
    # Get the first non-loopback interface IP with subnet
    ip -4 -o addr show | awk '!/ lo/{print $4; exit}'
}

# Function to download and set up Emerging Threats rules
setup_rules() {
    echo "Downloading and extracting Emerging Threats Suricata ruleset..."
    cd /tmp/ && curl -LO https://rules.emergingthreats.net/open/suricata-6.0.8/emerging.rules.tar.gz
    sudo tar -xvzf emerging.rules.tar.gz
    sudo mkdir -p /etc/suricata/rules
    sudo mv rules/*.rules /etc/suricata/rules/
    sudo chmod 640 /etc/suricata/rules/*.rules
    echo "Ruleset setup completed."
}

# Function to modify Suricata configuration
configure_suricata() {
    local homenet_ip
    homenet_ip=$(get_homenet_ip)
    if [ -z "$homenet_ip" ]; then
        echo "Error: Unable to determine HOME_NET IP. Exiting."
        exit 1
    fi

    echo "Modifying /etc/suricata/suricata.yaml with HOME_NET: $homenet_ip"
    sudo sed -i "s|HOME_NET:.*|HOME_NET: \"$homenet_ip\"|" /etc/suricata/suricata.yaml
    sudo sed -i '/rule-files:/,/af-packet:/ s|^[[:space:]]*-.*rules|  - "*.rules"|' /etc/suricata/suricata.yaml

    # Get the primary non-loopback network interface
    local interface
    interface=$(ip -o -4 route show to default | awk '{print $5}')

    if [ -z "$interface" ]; then
        echo "Error: Unable to determine network interface. Exiting."
        exit 1
    fi

    echo "Setting af-packet interface to: $interface"
    sudo sed -i "/af-packet:/,/interface:/ s|^[[:space:]]*interface:.*|  - interface: $interface|" /etc/suricata/suricata.yaml
    echo "Suricata configuration updated."
}

# Function to restart Suricata
restart_suricata() {
    echo "Restarting Suricata service..."
    sudo systemctl restart suricata
    echo "Suricata service restarted."
}

# Function to configure Wazuh Agent for Suricata logs
configure_wazuh_for_suricata() {
    echo "Configuring Wazuh Agent to monitor Suricata logs..."
    sudo bash -c 'cat << EOF >> /var/ossec/etc/ossec.conf
<localfile>
  <log_format>json</log_format>
  <location>/var/log/suricata/eve.json</location>
</localfile>
EOF'
    sudo systemctl restart wazuh-agent
    echo "Wazuh Agent configuration for Suricata completed."
}

# Function to configure Wazuh Agent for ClamAV logs
configure_wazuh_for_clamav() {
    echo "Configuring Wazuh Agent to monitor ClamAV logs..."
    sudo bash -c 'cat << EOF >> /var/ossec/etc/ossec.conf
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/clamav/clamav.log</location>
</localfile>
EOF'
    sudo systemctl restart wazuh-agent
    echo "Wazuh Agent configuration for ClamAV completed."
}

# Function to configure Wazuh Agent for YARA logs
configure_wazuh_for_yara() {
    echo "Configuring Wazuh Agent to monitor YARA logs..."
    sudo bash -c 'cat << EOF >> /var/ossec/etc/ossec.conf
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/yara/yara.log</location>
</localfile>
EOF'
    sudo systemctl restart wazuh-agent
    echo "Wazuh Agent configuration for YARA completed."
}

# Function to install all add-ons
install_add_ons() {
    install_suricata
    configure_suricata
    setup_rules
    restart_suricata
    configure_wazuh_for_suricata
}

# Display simplified menu
show_menu() {
    echo "Choose an installation option:"
    echo "1) Install Wazuh Agent only"
    echo "2) Uninstall Wazuh Agent"
    echo "3) Exit"
    read -p "Enter your choice [1-4]: " choice
    case $choice in
        1)
            prompt_wazuh_details
            install_wazuh_agent
            ;;
        2)
            uninstall_wazuh_agent
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            ;;
    esac
}

# Main loop
while true; do
    show_menu
done