# TheHive and Cortex Deployment with Docker Compose

This project provides a lightweight and secure Docker Compose setup for deploying **TheHive** and **Cortex**. 

## Features
- **TheHive**: Incident Response Platform
- **Cortex**: Threat Analysis and Automation Engine
- **Cassandra**: Database backend for TheHive
- **Elasticsearch**: Indexing backend for TheHive
- **MinIO**: Object storage for file and attachment management

## Prerequisites
- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Install Docker Compose](https://docs.docker.com/compose/install/)

## Setup Instructions
1. Clone the repository:
    ```bash
    git clone https://github.com/your-repo/thehive-cortex-docker.git
    cd thehive-cortex-docker
    ```

2. Configure environment variables:
    - Copy `.env.example` to `.env`:
        ```bash
        cp .env.example .env
        ```
    - Edit the `.env` file to set custom values for ports, secrets, and credentials.

3. Start the services:
    ```bash
    docker-compose up -d
    ```

4. Verify the deployment:
    ```bash
    docker-compose ps
    ```

## Accessing Services
- **TheHive**: `http://<your-server-ip>:9000`
- **Cortex**: `http://<your-server-ip>:9001`

## Managing Services
- **Stop Services**:
    ```bash
    docker-compose down
    ```
- **View Logs**:
    ```bash
    docker-compose logs -f
    ```

## Environment Variables
Edit the `.env` file for custom configuration. Below are some key variables:
- **TheHive**:
    - `THEHIVE_PORT` (default: `9000`)
    - `THEHIVE_SECRET`
- **Cassandra**:
    - `CASSANDRA_PORT` (default: `9042`)
    - `CASSANDRA_CLUSTER_NAME`
- **Elasticsearch**:
    - `ELASTICSEARCH_PORT` (default: `9500`)
    - `ELASTICSEARCH_JAVA_OPTS`
- **MinIO**:
    - `MINIO_PORT` (default: `9002`)
    - `MINIO_ROOT_USER`
    - `MINIO_ROOT_PASSWORD`
- **Cortex**:
    - `CORTEX_PORT` (default: `9001`)

## Troubleshooting
- If services are not accessible, verify the configured ports in `.env`.
- Check logs for errors:
    ```bash
    docker-compose logs thehive
    docker-compose logs cortex.local
    ```

## Notes
- Ensure ports are open in your firewall.
- Place `.env` in the same directory as `docker-compose.yml` for automatic loading.

Enjoy your deployment of **TheHive** and **Cortex**! 🚀