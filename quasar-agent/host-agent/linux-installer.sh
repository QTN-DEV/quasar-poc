#!/bin/bash

# Function to install Wazuh Agent
install_wazuh_agent() {
    echo "Installing Wazuh Agent..."
    curl -sO https://packages.wazuh.com/4.x/apt/KEY.gpg
    sudo apt-key add KEY.gpg
    echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
    sudo apt-get update
    sudo apt-get install wazuh-agent -y
    sudo systemctl daemon-reload
    sudo systemctl enable wazuh-agent
    sudo systemctl start wazuh-agent
    echo "Wazuh Agent installation completed."
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

# Function to configure Suricata
configure_suricata() {
    echo "Configuring Suricata to output logs in JSON format..."
    sudo sed -i 's/^#\s*output-json:/output-json:/' /etc/suricata/suricata.yaml
    sudo systemctl restart suricata
    echo "Suricata configuration completed."
}

# Function to configure Suricata
configure_yara() {
    echo "Configuring Suricata to output logs in JSON format..."
    sudo sed -i 's/^#\s*output-json:/output-json:/' /etc/suricata/suricata.yaml
    sudo systemctl restart suricata
    echo "Suricata configuration completed."
}

# Function to configure Suricata
configure_clamav() {
    echo "Configuring Suricata to output logs in JSON format..."
    sudo sed -i 's/^#\s*output-json:/output-json:/' /etc/suricata/suricata.yaml
    sudo systemctl restart suricata
    echo "Suricata configuration completed."
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

configure_wazuh_for_clamav() {
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

configure_wazuh_for_yara() {
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

# Function to perform default installation
install_all() {
    install_wazuh_agent
    install_clamav
    install_yara
    install_suricata
    configure_suricata
    configure_clamav
    configure_yara
    configure_wazuh_for_suricata
    configure_wazuh_for_clamav
    configure_wazuh_for_yara

# Display simplified menu
show_menu() {
    echo "Choose an installation option:"
    echo "1) Default Installation (Wazuh Agent, ClamAV, YARA, Suricata)"
    echo "2) Install Wazuh Agent with ClamAV"
    echo "3) Install Wazuh Agent with YARA"
    echo "4) Install Wazuh Agent with Suricata"
    echo "5) Exit"
    read -p "Enter your choice [1-5]: " choice
    case $choice in
        1)
            install_all
            ;;
        2)
            install_wazuh_agent
            install_clamav
            configure_clamav
            configure_wazuh_for_clamav
            ;;
        3)
            install_wazuh_agent
            install_yara
            configure_yara
            configure_wazuh_for_yara
            ;;
        4)
            install_wazuh_agent
            install_suricata
            configure_suricata
            configure_wazuh_for_suricata
            ;;
        5)
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