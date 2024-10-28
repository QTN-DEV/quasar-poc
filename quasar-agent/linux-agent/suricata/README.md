## Wazuh Agent Bundled with Suricata

### How To Use

This script gives users flexibility for setting up the Wazuh agent alone or with Suricata, and allows them to input the Wazuh Manager IP and Agent Name dynamically through environment variables or runtime options.

1. Wazuh Agent Only 
    ```
    docker run -e WAZUH_MANAGER=YOUR_MANAGER_IP -e WAZUH_AGENT_NAME=YOUR_AGENT_NAME your_docker_image
    ```

2. Wazuh Agent with Suricata
    ```
    docker run -e WAZUH_MANAGER=YOUR_MANAGER_IP -e WAZUH_AGENT_NAME=YOUR_AGENT_NAME your_docker_image -s

    ```