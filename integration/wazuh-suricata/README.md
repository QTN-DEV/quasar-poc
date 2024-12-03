# Suricata and Wazuh Integration Script

This script automates the integration of Suricata with the Wazuh agent on an Ubuntu endpoint. It configures Suricata to send logs to the Wazuh server, ensuring proper setup and avoiding duplicate configurations.

---

## Features
- Installs Suricata and Emerging Threats ruleset.
- Configures Suricata to monitor the appropriate network interface.
- Integrates Suricata logs with the Wazuh agent.
- Prevents duplicate log configurations in the Wazuh agent.

---

## Prerequisites
- An Ubuntu system with root or `sudo` access.
- Wazuh agent installed and configured.
- Access to the internet for downloading Suricata and rules.

---

## Script Steps
1. **Install Suricata**:
    - Adds the Suricata stable repository.
    - Installs Suricata using `apt`.

2. **Configure Suricata Rules**:
    - Downloads and extracts the Emerging Threats ruleset.
    - Configures Suricata to use these rules.

3. **Update Suricata Settings**:
    - Sets `HOME_NET` and `EXTERNAL_NET` in the `suricata.yaml` file.
    - Configures Suricata to monitor the primary network interface.

4. **Restart Suricata Service**:
    - Applies the new settings by restarting Suricata.

5. **Integrate with Wazuh Agent**:
    - Adds Suricata's log configuration to the Wazuh agent.
    - Prevents duplication of log configurations.

---

## How to Use

1. Download the script to your Ubuntu system.
2. Make the script executable:
    ```bash
    chmod +x setup_suricata_wazuh.sh
    ```
3. Run the script with `sudo`:
    ```bash
    sudo ./setup_suricata_wazuh.sh
    ```

---

## Expected Output

After successful execution:
- Suricata will be installed and configured.
- Suricata logs (`/var/log/suricata/eve.json`) will be monitored by the Wazuh agent.
- No duplicate configurations will exist in the Wazuh agent's configuration file.

---

## Troubleshooting

- **Permission Issues**: Ensure you run the script with `sudo`.
- **Suricata Configuration Errors**: Verify the `/etc/suricata/suricata.yaml` file for proper YAML formatting.
- **Wazuh Agent Issues**: Check `/var/ossec/etc/ossec.conf` for duplicate entries or misconfigurations.

---

## File Locations

- Suricata Configuration: `/etc/suricata/suricata.yaml`
- Wazuh Agent Configuration: `/var/ossec/etc/ossec.conf`

---