#!/bin/bash

set -e

# Define variables
YARA_VERSION="4.2.3"
YARA_INSTALL_PATH="/usr/local/bin"
RULES_DIR="/tmp/yara/rules"
ACTIVE_RESPONSE_PATH="/var/ossec/active-response/bin"
YARA_SCRIPT="$ACTIVE_RESPONSE_PATH/yara.sh"
MALWARE_DIR="/tmp/yara/malware"
API_KEY="1111111111111111111111111111111111111111111111111111111111111111"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    echo "Installing required dependencies..."
    sleep 2
    if command -v apt &>/dev/null; then
        apt update
        apt install -y make gcc autoconf libtool libssl-dev pkg-config jq curl
    elif command -v yum &>/dev/null; then
        yum makecache
        yum install -y epel-release
        yum update
        yum install -y make automake gcc autoconf libtool openssl-devel pkg-config jq curl
    else
        echo "Unsupported package manager. Please use a system with apt or yum."
        exit 1
    fi
    echo "Dependencies installed successfully."
    sleep 2
}

# Install YARA
install_yara() {
    echo "Downloading and installing YARA version $YARA_VERSION..."
    sleep 2
    curl -LO "https://github.com/VirusTotal/yara/archive/v${YARA_VERSION}.tar.gz"
    tar -xvzf "v${YARA_VERSION}.tar.gz" -C "$YARA_INSTALL_PATH/" && rm -f "v${YARA_VERSION}.tar.gz"
    cd "$YARA_INSTALL_PATH/yara-${YARA_VERSION}/"
    ./bootstrap.sh && ./configure && make && make install && make check
    echo "YARA installed successfully."
    sleep 2

    if ! command -v yara &>/dev/null; then
        echo "Configuring library path for YARA..."
        echo "/usr/local/lib" >> /etc/ld.so.conf
        ldconfig
        echo "Library path configured successfully."
        sleep 2
    fi
}

# Download YARA rules
download_rules() {
    echo "Downloading YARA rules..."
    sleep 2
    mkdir -p "$RULES_DIR"
    curl 'https://valhalla.nextron-systems.com/api/v1/get' \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --compressed \
        --data "demo=demo&apikey=${API_KEY}&format=text" \
        -o "${RULES_DIR}/yara_rules.yar"
    echo "YARA rules downloaded successfully."
    sleep 2
}

# Create yara.sh script for Active Response
create_yara_script() {
    echo "Creating YARA Active Response script..."
    sleep 2
    mkdir -p "$ACTIVE_RESPONSE_PATH"
    cat > "$YARA_SCRIPT" << 'EOF'
#!/bin/bash
# Wazuh - Yara active response
# Copyright (C) 2015-2022, Wazuh Inc.

read INPUT_JSON
YARA_PATH=$(echo $INPUT_JSON | jq -r .parameters.extra_args[1])
YARA_RULES=$(echo $INPUT_JSON | jq -r .parameters.extra_args[3])
FILENAME=$(echo $INPUT_JSON | jq -r .parameters.alert.syscheck.path)

LOG_FILE="logs/active-responses.log"
size=0
actual_size=$(stat -c %s ${FILENAME})
while [ ${size} -ne ${actual_size} ]; do
    sleep 1
    size=${actual_size}
    actual_size=$(stat -c %s ${FILENAME})
done

if [[ ! $YARA_PATH ]] || [[ ! $YARA_RULES ]]; then
    echo "wazuh-yara: ERROR - Yara active response error. Yara path and rules parameters are mandatory." >> ${LOG_FILE}
    exit 1
fi

yara_output="$("${YARA_PATH}"/yara -w -r "$YARA_RULES" "$FILENAME")"

if [[ $yara_output != "" ]]; then
    while read -r line; do
        echo "wazuh-yara: INFO - Scan result: $line" >> ${LOG_FILE}
    done <<< "$yara_output"
fi

exit 0
EOF
    chmod 750 "$YARA_SCRIPT"
    chown root:wazuh "$YARA_SCRIPT"
    echo "YARA Active Response script created successfully."
    sleep 2
}

# Configure Wazuh agent
configure_wazuh_agent() {
    echo "Configuring Wazuh agent to monitor YARA malware directory..."
    sleep 2
    mkdir -p "$MALWARE_DIR"
    sed -i "/<directories>/a <directories realtime=\"yes\">${MALWARE_DIR}</directories>" /var/ossec/etc/ossec.conf
    systemctl restart wazuh-agent
    echo "Wazuh agent configured and restarted successfully."
    sleep 2
}

# Main function
main() {
    echo "Starting YARA and Wazuh integration setup..."
    sleep 2
    check_root
    install_dependencies
    install_yara
    download_rules
    create_yara_script
    configure_wazuh_agent
    echo "YARA and Wazuh integration setup completed successfully."
    echo "You can now monitor the directory $MALWARE_DIR for malware files."
    echo "If you encounter issues with the YARA library path, please perform the following steps manually:"
    echo -e "\nManual Steps:\n"
    echo "sudo su"
    echo 'echo "/usr/local/lib" >> /etc/ld.so.conf'
    echo "ldconfig"
}

main