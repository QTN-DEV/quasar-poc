#!/bin/bash

# setup_wazuh.sh
# Bash script to automate the configuration of Wazuh Docker Compose setup based on user input.

set -e

# Function to prompt user for number of workers and indexers
get_user_input() {
    echo "Enter the number of Wazuh Indexers (minimum 3):"
    read -r INDEXER_COUNT

    # Validate that INDEXER_COUNT is an integer >= 3
    while ! [[ "$INDEXER_COUNT" =~ ^[0-9]+$ ]] || [ "$INDEXER_COUNT" -lt 3 ]; do
        echo "Invalid input. Please enter an integer greater than or equal to 3 for indexers:"
        read -r INDEXER_COUNT
    done

    # Workers = Indexers -1
    WORKER_COUNT=$((INDEXER_COUNT - 1))
    echo "Number of Wazuh Workers will be: $WORKER_COUNT"
    echo "Number of Wazuh Indexers will be: $INDEXER_COUNT"
}

# Function to duplicate the directory structure
duplicate_directory() {
    BASE_DIR="triple-node"
    NEW_DIR_PREFIX="node"

    # Determine the naming based on the count
    if [ "$WORKER_COUNT" -eq 2 ]; then
        NEW_DIR_NAME="triple-node"
    else
        NEW_DIR_NAME=""
        # Example: quadruple-node for 3 workers & 4 indexers
        if [ "$WORKER_COUNT" -eq 3 ]; then
            NEW_DIR_NAME="quadruple-node"
        elif [ "$WORKER_COUNT" -eq 4 ]; then
            NEW_DIR_NAME="quintuple-node"
        elif [ "$WORKER_COUNT" -eq 5 ]; then
            NEW_DIR_NAME="sextuple-node"
        else
            # Generic naming if beyond predefined
            NEW_DIR_NAME="${WORKER_COUNT}w-${INDEXER_COUNT}i-node"
        fi
    fi

    # If the count is still 2, retain the original
    if [ "$WORKER_COUNT" -ne 2 ]; then
        cp -r "$BASE_DIR" "$NEW_DIR_NAME"
        echo "Directory duplicated to $NEW_DIR_NAME"
    else
        NEW_DIR_NAME="$BASE_DIR"
        echo "Using existing directory $NEW_DIR_NAME"
    fi
}

# Function to update docker-compose.yml
update_docker_compose() {
    DOCKER_COMPOSE="$NEW_DIR_NAME/docker-compose.yml"

    # Backup original docker-compose.yml
    cp "$DOCKER_COMPOSE" "${DOCKER_COMPOSE}.bak"
    echo "Backup of docker-compose.yml created as docker-compose.yml.bak"

    # Function to add indexer services
    add_indexer_services() {
        for ((i=4; i<=INDEXER_COUNT; i++)); do
            cat >> "$DOCKER_COMPOSE" <<EOL

      wazuh$i.indexer:
        image: wazuh/wazuh-indexer:4.9.1
        hostname: wazuh$i.indexer
        restart: always
        environment:
          - "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"
          - "bootstrap.memory_lock=true"
        ulimits:
          memlock:
            soft: -1
            hard: -1
          nofile:
            soft: 65536
            hard: 65536
        volumes:
          - wazuh-indexer-data-$i:/var/lib/wazuh-indexer
          - ./config/wazuh_indexer_ssl_certs/root-ca.pem:/usr/share/wazuh-indexer/certs/root-ca.pem
          - ./config/wazuh_indexer_ssl_certs/wazuh$i.indexer-key.pem:/usr/share/wazuh-indexer/certs/wazuh$i.indexer.key
          - ./config/wazuh_indexer_ssl_certs/wazuh$i.indexer.pem:/usr/share/wazuh-indexer/certs/wazuh$i.indexer.pem
          - ./config/wazuh_indexer/wazuh$i.indexer.yml:/usr/share/wazuh-indexer/opensearch.yml
          - ./config/wazuh_indexer/internal_users.yml:/usr/share/wazuh-indexer/opensearch-security/internal_users.yml
EOL
        done
        echo "Indexer services added to docker-compose.yml"
    }

    # Function to add worker services
    add_worker_services() {
        # Create wazuh1.worker.conf from the base worker.conf
        cp "$NEW_DIR_NAME/config/wazuh_cluster/wazuh_worker.conf" "$NEW_DIR_NAME/config/wazuh_cluster/wazuh1.worker.conf"
        sed -i "s/<node_name>worker01<\/node_name>/<node_name>worker1<\/node_name>/g" "$NEW_DIR_NAME/config/wazuh_cluster/wazuh1.worker.conf"
        sed -i "s/<host>https:\/\/wazuh1.indexer:9200<\/host>/<host>https:\/\/wazuh1.indexer:9200<\/host>/g" "$NEW_DIR_NAME/config/wazuh_cluster/wazuh1.worker.conf"
        echo "Created wazuh1.worker.conf"

        for ((i=2; i<=WORKER_COUNT; i++)); do
            cp "$NEW_DIR_NAME/config/wazuh_cluster/wazuh_worker.conf" "$NEW_DIR_NAME/config/wazuh_cluster/wazuh${i}.worker.conf"
            # Update cluster configuration inside the new worker.conf
            sed -i "s/<node_name>worker01<\/node_name>/<node_name>worker$i<\/node_name>/g" "$NEW_DIR_NAME/config/wazuh_cluster/wazuh${i}.worker.conf"
            sed -i "s/<host>https:\/\/wazuh1.indexer:9200<\/host>/<host>https:\/\/wazuh$i.indexer:9200<\/host>/g" "$NEW_DIR_NAME/config/wazuh_cluster/wazuh${i}.worker.conf"
            echo "Created wazuh${i}.worker.conf"
        done
        echo "Worker services added to docker-compose.yml"
    }

    # Add new indexer services if needed
    if [ "$INDEXER_COUNT" -gt 3 ]; then
        add_indexer_services
    fi

    # Add new worker services if needed
    if [ "$WORKER_COUNT" -gt 1 ]; then
        add_worker_services
    fi

    # Update volumes for new indexers
    if [ "$INDEXER_COUNT" -gt 3 ]; then
        for ((i=4; i<=INDEXER_COUNT; i++)); do
            echo "      wazuh-indexer-data-$i:" >> "$DOCKER_COMPOSE"
        done
        echo "Volumes for new indexers added to docker-compose.yml"
    fi

    echo "docker-compose.yml updated successfully."
}

# Function to update wazuhX_worker.conf
update_wazuh_cluster_conf() {
    CONFIG_DIR="$NEW_DIR_NAME/config/wazuh_cluster"
    for ((i=1; i<=WORKER_COUNT; i++)); do
        WORKER_CONF="$CONFIG_DIR/wazuh${i}.worker.conf"

        if [ ! -f "$WORKER_CONF" ]; then
            echo "Error: $WORKER_CONF does not exist."
            echo "Please ensure the worker configuration files are created correctly."
            exit 1
        fi

        # Update <host> entries to include all indexers
        # Remove existing <hosts> block
        sed -i '/<hosts>/,/<\/hosts>/d' "$WORKER_CONF"

        # Add updated <hosts> block with correct indentation
        {
            echo "      <hosts>"
            for ((j=1; j<=INDEXER_COUNT; j++)); do
                echo "        <host>https://wazuh$j.indexer:9200</host>"
            done
            echo "      </hosts>"
        } >> "$WORKER_CONF"

        echo "Updated $WORKER_CONF with all indexers"
    done
    echo "Wazuh cluster configuration files updated successfully."
}

# Function to update wazuhY.indexer.yml
update_wazuh_indexer_conf() {
    CONFIG_DIR="$NEW_DIR_NAME/config/wazuh_indexer"
    for ((i=1; i<=INDEXER_COUNT; i++)); do
        INDEXER_CONF="$CONFIG_DIR/wazuh$i.indexer.yml"

        if [ ! -f "$INDEXER_CONF" ]; then
            echo "Error: $INDEXER_CONF does not exist."
            echo "Please ensure the indexer configuration files are present."
            exit 1
        fi

        # Backup original
        cp "$INDEXER_CONF" "${INDEXER_CONF}.bak"
        echo "Backup of $INDEXER_CONF created as ${INDEXER_CONF}.bak"

        # Update network.host and node.name
        sed -i "s/^network.host: .*/network.host: wazuh$i.indexer/g" "$INDEXER_CONF"
        sed -i "s/^node.name: .*/node.name: wazuh$i.indexer/g" "$INDEXER_CONF"

        # Update cluster.initial_master_nodes
        sed -i "/^cluster.initial_master_nodes:/,/^[^ ]/ s/\- wazuh[0-9]\+\.indexer/- wazuh$i.indexer/" "$INDEXER_CONF"

        # Update discovery.seed_hosts
        sed -i "/^discovery.seed_hosts:/,/^[^ ]/ s/\- wazuh[0-9]\+\.indexer/- wazuh$i.indexer/" "$INDEXER_CONF"

        # Update SSL certificate paths
        sed -i "s|plugins.security.ssl.http.pemcert_filepath:.*|plugins.security.ssl.http.pemcert_filepath: \${OPENSEARCH_PATH_CONF}/certs/wazuh$i.indexer.pem|g" "$INDEXER_CONF"
        sed -i "s|plugins.security.ssl.http.pemkey_filepath:.*|plugins.security.ssl.http.pemkey_filepath: \${OPENSEARCH_PATH_CONF}/certs/wazuh$i.indexer.key|g" "$INDEXER_CONF"
        sed -i "s|plugins.security.ssl.transport.pemcert_filepath:.*|plugins.security.ssl.transport.pemcert_filepath: \${OPENSEARCH_PATH_CONF}/certs/wazuh$i.indexer.pem|g" "$INDEXER_CONF"
        sed -i "s|plugins.security.ssl.transport.pemkey_filepath:.*|plugins.security.ssl.transport.pemkey_filepath: \${OPENSEARCH_PATH_CONF}/certs/wazuh$i.indexer.key|g" "$INDEXER_CONF"

        # Update plugins.security.nodes_dn with correct indentation
        sed -i "/^plugins.security.nodes_dn:/a\    - \"CN=wazuh$i.indexer,OU=Wazuh,O=Wazuh,L=California,C=US\"" "$INDEXER_CONF"

        echo "Updated $INDEXER_CONF with new configurations"
    done
    echo "Wazuh indexer configuration files updated successfully."
}

# Function to update cert.yml
update_cert_yml() {
    CERT_YML="$NEW_DIR_NAME/config/cert.yml"

    if [ ! -f "$CERT_YML" ]; then
        echo "Error: $CERT_YML does not exist."
        echo "Please ensure the cert.yml file is present."
        exit 1
    fi

    # Backup original
    cp "$CERT_YML" "${CERT_YML}.bak"
    echo "Backup of cert.yml created as cert.yml.bak"

    # Function to add indexers
    add_indexers_to_cert() {
        for ((i=4; i<=INDEXER_COUNT; i++)); do
            echo "          - name: wazuh$i.indexer" >> "$CERT_YML"
            echo "            ip: wazuh$i.indexer" >> "$CERT_YML"
            echo "Added wazuh$i.indexer to cert.yml"
        done
    }

    # Function to add workers
    add_workers_to_cert() {
        for ((i=1; i<=WORKER_COUNT; i++)); do
            echo "        - name: wazuh.worker$i" >> "$CERT_YML"
            echo "          ip: wazuh.worker$i" >> "$CERT_YML"
            echo "Added wazuh.worker$i to cert.yml"
        done
    }

    # Add new indexers
    if [ "$INDEXER_COUNT" -gt 3 ]; then
        add_indexers_to_cert
    fi

    # Add new workers
    if [ "$WORKER_COUNT" -ge 1 ]; then
        add_workers_to_cert
    fi

    echo "cert.yml updated successfully."
}

# Function to update nginx.conf
update_nginx_conf() {
    NGINX_CONF="$NEW_DIR_NAME/config/nginx/nginx.conf"

    if [ ! -f "$NGINX_CONF" ]; then
        echo "Error: $NGINX_CONF does not exist."
        echo "Please ensure the nginx.conf file is present."
        exit 1
    fi

    # Backup original
    cp "$NGINX_CONF" "${NGINX_CONF}.bak"
    echo "Backup of nginx.conf created as nginx.conf.bak"

    # Add new workers to the upstream 'mycluster'
    # Assuming workers are named wazuh.worker, wazuh.worker2, etc.
    # First, remove existing server lines inside upstream
    sed -i '/upstream mycluster {/,/}/d' "$NGINX_CONF"

    # Recreate the upstream block with correct indentation
    {
        echo "    upstream mycluster {"
        echo "        hash \$remote_addr consistent;"
        for ((i=1; i<=WORKER_COUNT; i++)); do
            if [ "$i" -eq 1 ]; then
                echo "        server wazuh.worker:1514;"
            else
                echo "        server wazuh.worker$i:1514;"
            fi
        done
        echo "    }"
        echo "    server {"
        echo "        listen 1514;"
        echo "        proxy_pass mycluster;"
        echo "    }"
    } >> "$NGINX_CONF"

    echo "nginx.conf updated successfully."
}

# Function to update OpenSearch Dashboards and Wazuh Dashboard configurations
update_dashboard_conf() {
    # Update opensearch_dashboards.yml
    DASHBOARD_YML="$NEW_DIR_NAME/config/wazuh_dashboard/opensearch_dashboards.yml"

    if [ ! -f "$DASHBOARD_YML" ]; then
        echo "Error: $DASHBOARD_YML does not exist."
        echo "Please ensure the opensearch_dashboards.yml file is present."
        exit 1
    fi

    cp "$DASHBOARD_YML" "${DASHBOARD_YML}.bak"
    echo "Backup of opensearch_dashboards.yml created as opensearch_dashboards.yml.bak"

    # Remove existing opensearch.hosts line
    sed -i '/^opensearch.hosts:/d' "$DASHBOARD_YML"

    # Add updated opensearch.hosts line with correct indentation
    {
        echo "opensearch.hosts: ["
        for ((i=1; i<=INDEXER_COUNT; i++)); do
            if [ "$i" -ne "$INDEXER_COUNT" ]; then
                echo "  \"https://wazuh$i.indexer:9200\","
            else
                echo "  \"https://wazuh$i.indexer:9200\""
            fi
        done
        echo "]"
    } >> "$DASHBOARD_YML"
    echo "Updated opensearch_dashboards.yml with new indexers"

    # Update Wazuh Dashboard wazuh.yml
    WAZUH_YML="$NEW_DIR_NAME/config/wazuh_dashboard/wazuh.yml"

    if [ ! -f "$WAZUH_YML" ]; then
        echo "Error: $WAZUH_YML does not exist."
        echo "Please ensure the wazuh.yml file is present."
        exit 1
    fi

    cp "$WAZUH_YML" "${WAZUH_YML}.bak"
    echo "Backup of wazuh.yml created as wazuh.yml.bak"

    # Update the URL to point to the master if needed
    # Assuming master remains the same, no change is needed unless master is replicated
    sed -i "s|https://wazuh.master|https://wazuh.master|g" "$WAZUH_YML"

    echo "Updated wazuh.yml with new configurations"
    echo "Dashboard configuration files updated successfully."
}

# Function to update Wazuh.yml
update_wazuh_yml() {
    WAZUH_YML="$NEW_DIR_NAME/config/wazuh_dashboard/wazuh.yml"

    if [ ! -f "$WAZUH_YML" ]; then
        echo "Error: $WAZUH_YML does not exist."
        echo "Please ensure the wazuh.yml file is present."
        exit 1
    fi

    cp "$WAZUH_YML" "${WAZUH_YML}.bak"
    echo "Backup of wazuh.yml created as wazuh.yml.bak"

    # If there are any dynamic fields to update based on indexers or workers, handle here
    # For example, updating enrollment.dns or hosts

    echo "wazuh.yml updated successfully."
}

# Function to pause the script and wait for user input
pause_script() {
    read -p "Press [Enter] to continue..."
}

# Main execution flow
main() {
    get_user_input
    pause_script

    duplicate_directory
    pause_script

    update_docker_compose
    pause_script

    update_wazuh_cluster_conf
    pause_script

    update_wazuh_indexer_conf
    pause_script

    update_cert_yml
    pause_script

    update_nginx_conf
    pause_script

    update_dashboard_conf
    pause_script

    update_wazuh_yml
    pause_script

    echo "Configuration duplication and updates completed successfully."
    echo "New configuration is available in the directory: $NEW_DIR_NAME"
}

# Execute the main function
main