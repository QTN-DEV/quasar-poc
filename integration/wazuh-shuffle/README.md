# Shuffle and Wazuh Integration via Webhook

This guide explains how to integrate **Wazuh** with **Shuffle** using webhooks to automate incident response. Once the integration is complete, Wazuh will send alerts to Shuffle, where workflows can be triggered and further actions can be automated.

## Prerequisites

- A **Wazuh server** set up and running.
- A **Shuffle** instance running via Docker (using the provided `docker-compose.yml`).
- Admin access to both **Wazuh** and **Shuffle** instances.
- A **Shuffle webhook trigger** created to receive alerts from Wazuh.

## Step-by-Step Integration Guide

### 1. Prepare Shuffle Environment

Ensure that your **Shuffle** environment is set up properly using the provided Docker setup.

1. **Clone the Shuffle repository or create a directory for your setup.**

   ```bash
   git clone https://github.com/shuffle-shuffle/shuffle.git
   cd shuffle

2. Edit the .env.example file with the appropriate values for your environment.

    Rename .env.example to .env:

    ```bash
    cp .env.example .env
    ```
    
    Modify the following entries in .env:

    - SHUFFLE_DEFAULT_APIKEY: Set your API key for Shuffle.
    - SHUFFLE_OPENSEARCH_PASSWORD: Set the password for OpenSearch (used by Shuffle).
    - BACKEND_HOSTNAME: Set the hostname for Shuffle’s backend (e.g., shuffle-backend).

    If you're running Shuffle on a remote server, make sure that your server’s firewall allows traffic on the ports you are exposing.

3. Start Shuffle using Docker Compose.

    The Docker Compose file (docker-compose.yml) includes services for frontend, backend, Orborus (task execution), and OpenSearch (data store). Run the following command to start Shuffle:

    ```bash
    docker-compose up -d
    ```

4. Verify that all containers are running.

    Use docker ps to check that the Shuffle services (frontend, backend, Orborus, and OpenSearch) are running as expected.

    ```bash
    docker ps
    ```

### 2. Create a Webhook Trigger in Shuffle

    - Log in to Shuffle’s frontend (usually accessible at http://localhost:3001 or the FRONTEND_PORT you defined in the .env file).

    - Navigate to the "Triggers" section and create a new webhook trigger. This will provide a webhook URI that you can use to send data to Shuffle.

    - Copy the webhook URI: It will be in the format:

    ```
    http://<YOUR_SHUFFLE_URL>/api/v1/hooks/<HOOK_ID>
    ```

    This webhook URI will be used in the Wazuh configuration to forward alerts to Shuffle.

### 3. Configure Wazuh to Send Alerts to Shuffle

    - Edit the Wazuh manager configuration file (/var/ossec/etc/ossec.conf) to include a new integration for Shuffle.

    Open the file using your preferred text editor:

    ```bash
    sudo nano /var/ossec/etc/ossec.conf
    ```
    - Add the following configuration to the <integration> section:

    Replace <YOUR_SHUFFLE_URL> and <HOOK_ID> with the appropriate values from the Shuffle webhook URI you copied earlier.

    ```xml
    <integration>
    <name>shuffle</name>
    <hook_url>http://<YOUR_SHUFFLE_URL>/api/v1/hooks/<HOOK_ID></hook_url>
    <level>3</level>
    <alert_format>json</alert_format>
    </integration>
    ```
        - <level>: This specifies the minimum alert level to forward to Shuffle. In this example, level 3 and above will be forwarded. You can adjust this to suit your needs.
        - <alert_format>: This should be set to json to match the expected format of the Shuffle webhook.

    You can also filter by rule_id, group, or event_location if you want to send more specific types of alerts.

    - Save the file and restart the Wazuh manager to apply the changes:

    ```bash
    sudo systemctl restart wazuh-manager
    ```