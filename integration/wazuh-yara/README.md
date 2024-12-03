# YARA and Wazuh Integration Script

This script automates the integration of YARA with the Wazuh agent. It sets up YARA, downloads the latest rules, and configures the Wazuh agent to monitor a directory for malware files.

---

## Features
- Installs YARA and its dependencies.
- Downloads YARA rules from Nextron Systems.
- Sets up an Active Response script for Wazuh integration.
- Configures the Wazuh agent to monitor a directory for real-time file analysis.

---

## Prerequisites
- An Ubuntu or CentOS system with root or `sudo` access.
- Wazuh agent installed and configured.
- Access to the internet for downloading YARA and rules.

---

## Script Steps
1. **Install Dependencies**:
    - Installs required packages like `gcc`, `libssl-dev`, `jq`, and `curl`.

2. **Install YARA**:
    - Downloads and installs the specified version of YARA (default: 4.2.3).

3. **Download YARA Rules**:
    - Fetches rules from Nextron Systems using the provided API key.

4. **Create YARA Active Response Script**:
    - Generates a script for Wazuh's active response to scan files with YARA.

5. **Configure Wazuh Agent**:
    - Sets up the Wazuh agent to monitor a specified directory for real-time file analysis.

---

## How to Use

1. Download the script to your system.
2. Make the script executable:
    ```bash
    chmod +x setup_yara_wazuh.sh
    ```
3. Run the script with `sudo`:
    ```bash
    sudo ./setup_yara_wazuh.sh
    ```

---

## Manual Steps

If you encounter issues with YARA's library path, configure it manually:
```bash
sudo su
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig
```

---

## Expected Output

After successful execution:
- YARA will be installed and configured.
- The Wazuh agent will monitor `/tmp/yara/malware` for real-time malware analysis.
- A YARA active response script will be available in `/var/ossec/active-response/bin/yara.sh`.

---

## Troubleshooting

- **Permission Issues**: Ensure you run the script with `sudo`.
- **YARA Library Path Errors**: Run the manual steps to configure the library path.
- **Wazuh Agent Issues**: Verify `/var/ossec/etc/ossec.conf` for proper configuration.

---

## File Locations

- **YARA Installation Path**: `/usr/local/bin/yara`
- **Rules Directory**: `/tmp/yara/rules`
- **Malware Monitoring Directory**: `/tmp/yara/malware`
- **Wazuh Active Response Script**: `/var/ossec/active-response/bin/yara.sh`

---