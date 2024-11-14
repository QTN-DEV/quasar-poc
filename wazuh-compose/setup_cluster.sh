#!/bin/bash

# Wazuh HA Cluster Setup Script
# This script configures Wazuh in a Docker Compose environment with dynamic support for multiple nodes.

set -e

# Function to prompt the user for cluster type and size
get_user_input() {
    echo "Choose the cluster setup type:"
    echo "1. Single Node"
    echo "2. Multi-Node (HA Cluster)"
    read -p "Enter your choice (1 or 2): " setup_choice
    
    if [[ "$setup_choice" == "1" ]]; then
        echo "Setting up a Single Node..."
        CLUSTER_TYPE="single-node"
        NEW_DIR="single-node"
    elif [[ "$setup_choice" == "2" ]]; then
        echo "Setting up a Multi-Node Cluster (HA)..."
        CLUSTER_TYPE="multi-node"
        read -p "Enter the number of workers (minimum 1): " WORKER_COUNT
        INDEXER_COUNT=$((WORKER_COUNT + 2))  # 1 master + WORKER_COUNT workers + 1 extra indexer
        NEW_DIR="${WORKER_COUNT}w-${INDEXER_COUNT}i-cluster"
    else
        echo "Invalid choice. Exiting."
        exit 1
    fi
}

# Function to prepare directory structure and configuration files
prepare_directories_and_files() {
    if [[ "$CLUSTER_TYPE" == "multi-node" ]]; then
        mkdir -p "$NEW_DIR/config/wazuh_cluster" "$NEW_DIR/config/wazuh_indexer" "$NEW_DIR/config/nginx"
        
        # Copy base files into the new directory
        cp -r "$CLUSTER_TYPE/"* "$NEW_DIR/"

        # Generate manager configuration file with the same indexer hosts
        MANAGER_CONF="$NEW_DIR/config/wazuh_cluster/wazuh_manager.conf"
        cat <<EOF > "$MANAGER_CONF"
<ossec_config>
  <global>
    <jsonout_output>yes</jsonout_output>
    <alerts_log>yes</alerts_log>
    <logall>no</logall>
    <logall_json>no</logall_json>
    <email_notification>no</email_notification>
    <smtp_server>smtp.example.wazuh.com</smtp_server>
    <email_from>wazuh@example.wazuh.com</email_from>
    <email_to>recipient@example.wazuh.com</email_to>
    <email_maxperhour>12</email_maxperhour>
    <email_log_source>alerts.log</email_log_source>
    <agents_disconnection_time>10m</agents_disconnection_time>
    <agents_disconnection_alert_time>0</agents_disconnection_alert_time>
  </global>

  <alerts>
    <log_alert_level>3</log_alert_level>
    <email_alert_level>12</email_alert_level>
  </alerts>

  <!-- Choose between "plain", "json", or "plain,json" for the format of internal logs -->
  <logging>
    <log_format>plain</log_format>
  </logging>

  <remote>
    <connection>secure</connection>
    <port>1514</port>
    <protocol>tcp</protocol>
    <queue_size>131072</queue_size>
  </remote>

  <!-- Policy monitoring -->
  <rootcheck>
    <disabled>no</disabled>
    <check_files>yes</check_files>
    <check_trojans>yes</check_trojans>
    <check_dev>yes</check_dev>
    <check_sys>yes</check_sys>
    <check_pids>yes</check_pids>
    <check_ports>yes</check_ports>
    <check_if>yes</check_if>

    <!-- Frequency that rootcheck is executed - every 12 hours -->
    <frequency>43200</frequency>

    <rootkit_files>etc/rootcheck/rootkit_files.txt</rootkit_files>
    <rootkit_trojans>etc/rootcheck/rootkit_trojans.txt</rootkit_trojans>

    <skip_nfs>yes</skip_nfs>
  </rootcheck>

  <wodle name="cis-cat">
    <disabled>yes</disabled>
    <timeout>1800</timeout>
    <interval>1d</interval>
    <scan-on-start>yes</scan-on-start>

    <java_path>wodles/java</java_path>
    <ciscat_path>wodles/ciscat</ciscat_path>
  </wodle>

  <!-- Osquery integration -->
  <wodle name="osquery">
    <disabled>yes</disabled>
    <run_daemon>yes</run_daemon>
    <log_path>/var/log/osquery/osqueryd.results.log</log_path>
    <config_path>/etc/osquery/osquery.conf</config_path>
    <add_labels>yes</add_labels>
  </wodle>

  <!-- System inventory -->
  <wodle name="syscollector">
    <disabled>no</disabled>
    <interval>1h</interval>
    <scan_on_start>yes</scan_on_start>
    <hardware>yes</hardware>
    <os>yes</os>
    <network>yes</network>
    <packages>yes</packages>
    <ports all="no">yes</ports>
    <processes>yes</processes>

    <!-- Database synchronization settings -->
    <synchronization>
      <max_eps>10</max_eps>
    </synchronization>
  </wodle>

  <sca>
    <enabled>yes</enabled>
    <scan_on_start>yes</scan_on_start>
    <interval>12h</interval>
    <skip_nfs>yes</skip_nfs>
  </sca>

  <vulnerability-detection>
    <enabled>yes</enabled>
    <index-status>yes</index-status>
    <feed-update-interval>60m</feed-update-interval>
  </vulnerability-detection>

  <indexer>
    <enabled>yes</enabled>
    <hosts>
$(for ((j=1; j<=INDEXER_COUNT; j++)); do echo "      <host>https://wazuh${j}.indexer:9200</host>"; done)
    </hosts>
    <ssl>
      <certificate_authorities>
        <ca>/etc/ssl/root-ca.pem</ca>
      </certificate_authorities>
      <certificate>/etc/ssl/filebeat.pem</certificate>
      <key>/etc/ssl/filebeat.key</key>
    </ssl>
  </indexer>

  <!-- File integrity monitoring -->
  <syscheck>
    <disabled>no</disabled>

    <!-- Frequency that syscheck is executed default every 12 hours -->
    <frequency>43200</frequency>

    <scan_on_start>yes</scan_on_start>

    <!-- Generate alert when new file detected -->
    <alert_new_files>yes</alert_new_files>

    <!-- Don't ignore files that change more than 'frequency' times -->
    <auto_ignore frequency="10" timeframe="3600">no</auto_ignore>

    <!-- Directories to check  (perform all possible verifications) -->
    <directories>/etc,/usr/bin,/usr/sbin</directories>
    <directories>/bin,/sbin,/boot</directories>

    <!-- Files/directories to ignore -->
    <ignore>/etc/mtab</ignore>
    <ignore>/etc/hosts.deny</ignore>
    <ignore>/etc/mail/statistics</ignore>
    <ignore>/etc/random-seed</ignore>
    <ignore>/etc/random.seed</ignore>
    <ignore>/etc/adjtime</ignore>
    <ignore>/etc/httpd/logs</ignore>
    <ignore>/etc/utmpx</ignore>
    <ignore>/etc/wtmpx</ignore>
    <ignore>/etc/cups/certs</ignore>
    <ignore>/etc/dumpdates</ignore>
    <ignore>/etc/svc/volatile</ignore>

    <!-- File types to ignore -->
    <ignore type="sregex">.log$|.swp$</ignore>

    <!-- Check the file, but never compute the diff -->
    <nodiff>/etc/ssl/private.key</nodiff>

    <skip_nfs>yes</skip_nfs>
    <skip_dev>yes</skip_dev>
    <skip_proc>yes</skip_proc>
    <skip_sys>yes</skip_sys>

    <!-- Nice value for Syscheck process -->
    <process_priority>10</process_priority>

    <!-- Maximum output throughput -->
    <max_eps>100</max_eps>

    <!-- Database synchronization settings -->
    <synchronization>
      <enabled>yes</enabled>
      <interval>5m</interval>
      <max_interval>1h</max_interval>
      <max_eps>10</max_eps>
    </synchronization>
  </syscheck>

  <!-- Active response -->
  <global>
    <white_list>127.0.0.1</white_list>
    <white_list>^localhost.localdomain$</white_list>
  </global>

  <command>
    <name>disable-account</name>
    <executable>disable-account</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>restart-wazuh</name>
    <executable>restart-wazuh</executable>
  </command>

  <command>
    <name>firewall-drop</name>
    <executable>firewall-drop</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>host-deny</name>
    <executable>host-deny</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>route-null</name>
    <executable>route-null</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>win_route-null</name>
    <executable>route-null.exe</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>netsh</name>
    <executable>netsh.exe</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <!--
  <active-response>
    active-response options here
  </active-response>
  -->

  <!-- Log analysis -->
  <localfile>
    <log_format>command</log_format>
    <command>df -P</command>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>netstat -tulpn | sed 's/\([[:alnum:]]\+\)\ \+[[:digit:]]\+\ \+[[:digit:]]\+\ \+\(.*\):\([[:digit:]]*\)\ \+\([0-9\.\:\*]\+\).\+\ \([[:digit:]]*\/[[:alnum:]\-]*\).*/\1 \2 == \3 == \4 \5/' | sort -k 4 -g | sed 's/ == \(.*\) ==/:\1/' | sed 1,2d</command>
    <alias>netstat listening ports</alias>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>last -n 20</command>
    <frequency>360</frequency>
  </localfile>

  <ruleset>
    <!-- Default ruleset -->
    <decoder_dir>ruleset/decoders</decoder_dir>
    <rule_dir>ruleset/rules</rule_dir>
    <rule_exclude>0215-policy_rules.xml</rule_exclude>
    <list>etc/lists/audit-keys</list>
    <list>etc/lists/amazon/aws-eventnames</list>
    <list>etc/lists/security-eventchannel</list>

    <!-- User-defined ruleset -->
    <decoder_dir>etc/decoders</decoder_dir>
    <rule_dir>etc/rules</rule_dir>
  </ruleset>

  <rule_test>
    <enabled>yes</enabled>
    <threads>1</threads>
    <max_sessions>64</max_sessions>
    <session_timeout>15m</session_timeout>
  </rule_test>

  <!-- Configuration for wazuh-authd -->
  <auth>
    <disabled>no</disabled>
    <port>1515</port>
    <use_source_ip>no</use_source_ip>
    <purge>yes</purge>
    <use_password>no</use_password>
    <ciphers>HIGH:!ADH:!EXP:!MD5:!RC4:!3DES:!CAMELLIA:@STRENGTH</ciphers>
    <!-- <ssl_agent_ca></ssl_agent_ca> -->
    <ssl_verify_host>no</ssl_verify_host>
    <ssl_manager_cert>etc/sslmanager.cert</ssl_manager_cert>
    <ssl_manager_key>etc/sslmanager.key</ssl_manager_key>
    <ssl_auto_negotiate>no</ssl_auto_negotiate>
  </auth>

  <cluster>
    <name>wazuh</name>
    <node_name>manager</node_name>
    <node_type>master</node_type>
    <key>c98b6ha9b6169zc5f67rae55ae4z5647</key>
    <port>1516</port>
    <bind_addr>0.0.0.0</bind_addr>
    <nodes>
        <node>wazuh.master</node>
    </nodes>
    <hidden>no</hidden>
    <disabled>no</disabled>
  </cluster>

</ossec_config>

<ossec_config>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/ossec/logs/active-responses.log</location>
  </localfile>

</ossec_config>

EOF
        echo "Generated $MANAGER_CONF with indexer hosts."

        # Generate worker configuration files
        rm -f "$NEW_DIR/config/wazuh_cluster/wazuh_worker.conf"  # Remove old worker config if it exists
        
        for ((i=1; i<=WORKER_COUNT; i++)); do
            WORKER_CONF="$NEW_DIR/config/wazuh_cluster/wazuh${i}_worker.conf"
            cat <<EOF > "$WORKER_CONF"
<ossec_config>
  <global>
    <jsonout_output>yes</jsonout_output>
    <alerts_log>yes</alerts_log>
    <logall>no</logall>
    <logall_json>no</logall_json>
    <email_notification>no</email_notification>
    <smtp_server>smtp.example.wazuh.com</smtp_server>
    <email_from>wazuh@example.wazuh.com</email_from>
    <email_to>recipient@example.wazuh.com</email_to>
    <email_maxperhour>12</email_maxperhour>
    <email_log_source>alerts.log</email_log_source>
    <agents_disconnection_time>10m</agents_disconnection_time>
    <agents_disconnection_alert_time>0</agents_disconnection_alert_time>
  </global>

  <alerts>
    <log_alert_level>3</log_alert_level>
    <email_alert_level>12</email_alert_level>
  </alerts>

  <!-- Choose between "plain", "json", or "plain,json" for the format of internal logs -->
  <logging>
    <log_format>plain</log_format>
  </logging>

  <remote>
    <connection>secure</connection>
    <port>1514</port>
    <protocol>tcp</protocol>
    <queue_size>131072</queue_size>
  </remote>

  <!-- Policy monitoring -->
  <rootcheck>
    <disabled>no</disabled>
    <check_files>yes</check_files>
    <check_trojans>yes</check_trojans>
    <check_dev>yes</check_dev>
    <check_sys>yes</check_sys>
    <check_pids>yes</check_pids>
    <check_ports>yes</check_ports>
    <check_if>yes</check_if>

    <!-- Frequency that rootcheck is executed - every 12 hours -->
    <frequency>43200</frequency>

    <rootkit_files>etc/rootcheck/rootkit_files.txt</rootkit_files>
    <rootkit_trojans>etc/rootcheck/rootkit_trojans.txt</rootkit_trojans>

    <skip_nfs>yes</skip_nfs>
  </rootcheck>

  <wodle name="cis-cat">
    <disabled>yes</disabled>
    <timeout>1800</timeout>
    <interval>1d</interval>
    <scan-on-start>yes</scan-on-start>

    <java_path>wodles/java</java_path>
    <ciscat_path>wodles/ciscat</ciscat_path>
  </wodle>

  <!-- Osquery integration -->
  <wodle name="osquery">
    <disabled>yes</disabled>
    <run_daemon>yes</run_daemon>
    <log_path>/var/log/osquery/osqueryd.results.log</log_path>
    <config_path>/etc/osquery/osquery.conf</config_path>
    <add_labels>yes</add_labels>
  </wodle>

  <!-- System inventory -->
  <wodle name="syscollector">
    <disabled>no</disabled>
    <interval>1h</interval>
    <scan_on_start>yes</scan_on_start>
    <hardware>yes</hardware>
    <os>yes</os>
    <network>yes</network>
    <packages>yes</packages>
    <ports all="no">yes</ports>
    <processes>yes</processes>

    <!-- Database synchronization settings -->
    <synchronization>
      <max_eps>10</max_eps>
    </synchronization>
  </wodle>

  <sca>
    <enabled>yes</enabled>
    <scan_on_start>yes</scan_on_start>
    <interval>12h</interval>
    <skip_nfs>yes</skip_nfs>
  </sca>

  <vulnerability-detection>
    <enabled>yes</enabled>
    <index-status>yes</index-status>
    <feed-update-interval>60m</feed-update-interval>
  </vulnerability-detection>

  <indexer>
    <enabled>yes</enabled>
    <hosts>
$(for ((j=1; j<=INDEXER_COUNT; j++)); do echo "      <host>https://wazuh${j}.indexer:9200</host>"; done)
    </hosts>
    <ssl>
      <certificate_authorities>
        <ca>/etc/ssl/root-ca.pem</ca>
      </certificate_authorities>
      <certificate>/etc/ssl/filebeat.pem</certificate>
      <key>/etc/ssl/filebeat.key</key>
    </ssl>
  </indexer>

  <!-- File integrity monitoring -->
  <syscheck>
    <disabled>no</disabled>

    <!-- Frequency that syscheck is executed default every 12 hours -->
    <frequency>43200</frequency>

    <scan_on_start>yes</scan_on_start>

    <!-- Generate alert when new file detected -->
    <alert_new_files>yes</alert_new_files>

    <!-- Don't ignore files that change more than 'frequency' times -->
    <auto_ignore frequency="10" timeframe="3600">no</auto_ignore>

    <!-- Directories to check  (perform all possible verifications) -->
    <directories>/etc,/usr/bin,/usr/sbin</directories>
    <directories>/bin,/sbin,/boot</directories>

    <!-- Files/directories to ignore -->
    <ignore>/etc/mtab</ignore>
    <ignore>/etc/hosts.deny</ignore>
    <ignore>/etc/mail/statistics</ignore>
    <ignore>/etc/random-seed</ignore>
    <ignore>/etc/random.seed</ignore>
    <ignore>/etc/adjtime</ignore>
    <ignore>/etc/httpd/logs</ignore>
    <ignore>/etc/utmpx</ignore>
    <ignore>/etc/wtmpx</ignore>
    <ignore>/etc/cups/certs</ignore>
    <ignore>/etc/dumpdates</ignore>
    <ignore>/etc/svc/volatile</ignore>

    <!-- File types to ignore -->
    <ignore type="sregex">.log$|.swp$</ignore>

    <!-- Check the file, but never compute the diff -->
    <nodiff>/etc/ssl/private.key</nodiff>

    <skip_nfs>yes</skip_nfs>
    <skip_dev>yes</skip_dev>
    <skip_proc>yes</skip_proc>
    <skip_sys>yes</skip_sys>

    <!-- Nice value for Syscheck process -->
    <process_priority>10</process_priority>

    <!-- Maximum output throughput -->
    <max_eps>100</max_eps>

    <!-- Database synchronization settings -->
    <synchronization>
      <enabled>yes</enabled>
      <interval>5m</interval>
      <max_interval>1h</max_interval>
      <max_eps>10</max_eps>
    </synchronization>
  </syscheck>

  <!-- Active response -->
  <global>
    <white_list>127.0.0.1</white_list>
    <white_list>^localhost.localdomain$</white_list>
  </global>

  <command>
    <name>disable-account</name>
    <executable>disable-account</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>restart-wazuh</name>
    <executable>restart-wazuh</executable>
  </command>

  <command>
    <name>firewall-drop</name>
    <executable>firewall-drop</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>host-deny</name>
    <executable>host-deny</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>route-null</name>
    <executable>route-null</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>win_route-null</name>
    <executable>route-null.exe</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <command>
    <name>netsh</name>
    <executable>netsh.exe</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <!--
  <active-response>
    active-response options here
  </active-response>
  -->

  <!-- Log analysis -->
  <localfile>
    <log_format>command</log_format>
    <command>df -P</command>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>netstat -tulpn | sed 's/\([[:alnum:]]\+\)\ \+[[:digit:]]\+\ \+[[:digit:]]\+\ \+\(.*\):\([[:digit:]]*\)\ \+\([0-9\.\:\*]\+\).\+\ \([[:digit:]]*\/[[:alnum:]\-]*\).*/\1 \2 == \3 == \4 \5/' | sort -k 4 -g | sed 's/ == \(.*\) ==/:\1/' | sed 1,2d</command>
    <alias>netstat listening ports</alias>
    <frequency>360</frequency>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>last -n 20</command>
    <frequency>360</frequency>
  </localfile>

  <ruleset>
    <!-- Default ruleset -->
    <decoder_dir>ruleset/decoders</decoder_dir>
    <rule_dir>ruleset/rules</rule_dir>
    <rule_exclude>0215-policy_rules.xml</rule_exclude>
    <list>etc/lists/audit-keys</list>
    <list>etc/lists/amazon/aws-eventnames</list>
    <list>etc/lists/security-eventchannel</list>

    <!-- User-defined ruleset -->
    <decoder_dir>etc/decoders</decoder_dir>
    <rule_dir>etc/rules</rule_dir>
  </ruleset>

  <rule_test>
    <enabled>yes</enabled>
    <threads>1</threads>
    <max_sessions>64</max_sessions>
    <session_timeout>15m</session_timeout>
  </rule_test>

  <!-- Configuration for wazuh-authd -->
  <auth>
    <disabled>no</disabled>
    <port>1515</port>
    <use_source_ip>no</use_source_ip>
    <purge>yes</purge>
    <use_password>no</use_password>
    <ciphers>HIGH:!ADH:!EXP:!MD5:!RC4:!3DES:!CAMELLIA:@STRENGTH</ciphers>
    <!-- <ssl_agent_ca></ssl_agent_ca> -->
    <ssl_verify_host>no</ssl_verify_host>
    <ssl_manager_cert>etc/sslmanager.cert</ssl_manager_cert>
    <ssl_manager_key>etc/sslmanager.key</ssl_manager_key>
    <ssl_auto_negotiate>no</ssl_auto_negotiate>
  </auth>

  <cluster>
    <name>wazuh</name>
    <node_name>worker01</node_name>
    <node_type>worker</node_type>
    <key>c98b6ha9b6169zc5f67rae55ae4z5647</key>
    <port>1516</port>
    <bind_addr>0.0.0.0</bind_addr>
    <nodes>
        <node>wazuh.master</node>
    </nodes>
    <hidden>no</hidden>
    <disabled>no</disabled>
  </cluster>

</ossec_config>

<ossec_config>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/ossec/logs/active-responses.log</location>
  </localfile>

</ossec_config>

EOF
            echo "Generated $WORKER_CONF"
        done

        # Generate indexer configuration files
        for ((i=1; i<=INDEXER_COUNT; i++)); do
            INDEXER_CONF="$NEW_DIR/config/wazuh_indexer/wazuh${i}.indexer.yml"
            cat <<EOF > "$INDEXER_CONF"
network.host: wazuh${i}.indexer
node.name: wazuh${i}.indexer
cluster.initial_master_nodes:
$(for ((j=1; j<=INDEXER_COUNT; j++)); do echo "  - wazuh${j}.indexer"; done)
cluster.name: "wazuh-cluster"
discovery.seed_hosts:
$(for ((j=1; j<=INDEXER_COUNT; j++)); do echo "  - wazuh${j}.indexer"; done)
node.max_local_storage_nodes: "$INDEXER_COUNT"
path.data: /var/lib/wazuh-indexer
path.logs: /var/log/wazuh-indexer
plugins.security.ssl.http.pemcert_filepath: \${OPENSEARCH_PATH_CONF}/certs/wazuh${i}.indexer.pem
plugins.security.ssl.http.pemkey_filepath: \${OPENSEARCH_PATH_CONF}/certs/wazuh${i}.indexer.key
plugins.security.ssl.http.pemtrustedcas_filepath: \${OPENSEARCH_PATH_CONF}/certs/root-ca.pem
plugins.security.ssl.transport.pemcert_filepath: \${OPENSEARCH_PATH_CONF}/certs/wazuh${i}.indexer.pem
plugins.security.ssl.transport.pemkey_filepath: \${OPENSEARCH_PATH_CONF}/certs/wazuh${i}.indexer.key
plugins.security.ssl.transport.pemtrustedcas_filepath: \${OPENSEARCH_PATH_CONF}/certs/root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.ssl.transport.resolve_hostname: false
plugins.security.authcz.admin_dn:
- "CN=admin,OU=Wazuh,O=Wazuh,L=California,C=US"
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.nodes_dn:
$(for ((j=1; j<=INDEXER_COUNT; j++)); do echo "- CN=wazuh${j}.indexer,OU=Wazuh,O=Wazuh,L=California,C=US"; done)
- CN=filebeat,OU=Wazuh,O=Wazuh,L=California,C=US
plugins.security.restapi.roles_enabled:
- "all_access"
- "security_rest_api_access"
plugins.security.allow_default_init_securityindex: true
cluster.routing.allocation.disk.threshold_enabled: false
compatibility.override_main_response_version: true
EOF
            echo "Generated $INDEXER_CONF"
        done

        # Generate nginx.conf
        NGINX_CONF="$NEW_DIR/config/nginx/nginx.conf"
        cat <<EOF > "$NGINX_CONF"
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    tcp_nopush      on;
    keepalive_timeout  65;
    server_tokens   off;
    gzip            on;
}

stream {
    upstream mycluster {
        hash \$remote_addr consistent;
        server wazuh.master:1514;
$(for ((i=1; i<=WORKER_COUNT; i++)); do echo "        server wazuh${i}.worker:1514;"; done)
    }
    server {
        listen 1514;
        proxy_pass mycluster;
    }
}
EOF
        echo "Generated $NGINX_CONF"
        
    else
        echo "Single Node setup: No additional configuration files required."
    fi
}

# Function to create docker-compose.yml for multi-node setup
# Function to create docker-compose.yml for multi-node setup
create_docker_compose() {
    # Skip docker-compose.yml modifications for single-node setup
    if [[ "$CLUSTER_TYPE" == "single-node" ]]; then
        echo "Single Node setup: No docker-compose modifications needed."
        return
    fi

    DOCKER_COMPOSE_FILE="$NEW_DIR/docker-compose.yml"
    echo "Creating docker-compose.yml in $NEW_DIR..."

    cat <<EOF > "$DOCKER_COMPOSE_FILE"
version: '3.7'

services:
  wazuh.master:
    image: wazuh/wazuh-manager:4.9.1
    hostname: wazuh.master
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 655360
        hard: 655360
    ports:
      - "1515:1515"
      - "514:514/udp"
      - "55000:55000"
    environment:
      - INDEXER_URL=https://wazuh1.indexer:9200
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=SecretPassword
      - FILEBEAT_SSL_VERIFICATION_MODE=full
      - SSL_CERTIFICATE_AUTHORITIES=/etc/ssl/root-ca.pem
      - SSL_CERTIFICATE=/etc/ssl/filebeat.pem
      - SSL_KEY=/etc/ssl/filebeat.key
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=MyS3cr37P450r.*-
    volumes:
      - master-wazuh-api-configuration:/var/ossec/api/configuration
      - master-wazuh-etc:/var/ossec/etc
      - master-wazuh-logs:/var/ossec/logs
      - master-wazuh-queue:/var/ossec/queue
      - master-wazuh-var-multigroups:/var/ossec/var/multigroups
      - master-wazuh-integrations:/var/ossec/integrations
      - master-wazuh-active-response:/var/ossec/active-response/bin
      - master-wazuh-agentless:/var/ossec/agentless
      - master-wazuh-wodles:/var/ossec/wodles
      - master-filebeat-etc:/etc/filebeat
      - master-filebeat-var:/var/lib/filebeat
      - ./config/wazuh_indexer_ssl_certs/root-ca-manager.pem:/etc/ssl/root-ca.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.master.pem:/etc/ssl/filebeat.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.master-key.pem:/etc/ssl/filebeat.key
      - ./config/wazuh_cluster/wazuh_manager.conf:/wazuh-config-mount/etc/ossec.conf
EOF

    # Add worker services
    for ((i=1; i<=WORKER_COUNT; i++)); do
        cat <<EOF >> "$DOCKER_COMPOSE_FILE"
  wazuh${i}.worker:
    image: wazuh/wazuh-manager:4.9.1
    hostname: wazuh${i}.worker
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 655360
        hard: 655360
    environment:
      - INDEXER_URL=https://wazuh1.indexer:9200
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=SecretPassword
      - FILEBEAT_SSL_VERIFICATION_MODE=full
      - SSL_CERTIFICATE_AUTHORITIES=/etc/ssl/root-ca.pem
      - SSL_CERTIFICATE=/etc/ssl/filebeat.pem
      - SSL_KEY=/etc/ssl/filebeat.key
    volumes:
      - worker${i}-wazuh-api-configuration:/var/ossec/api/configuration
      - worker${i}-wazuh-etc:/var/ossec/etc
      - worker${i}-wazuh-logs:/var/ossec/logs
      - worker${i}-wazuh-queue:/var/ossec/queue
      - worker${i}-wazuh-var-multigroups:/var/ossec/var/multigroups
      - worker${i}-wazuh-integrations:/var/ossec/integrations
      - worker${i}-wazuh-active-response:/var/ossec/active-response/bin
      - worker${i}-wazuh-agentless:/var/ossec/agentless
      - worker${i}-wazuh-wodles:/var/ossec/wodles
      - worker${i}-filebeat-etc:/etc/filebeat
      - worker${i}-filebeat-var:/var/lib/filebeat
      - ./config/wazuh_indexer_ssl_certs/root-ca-manager.pem:/etc/ssl/root-ca.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh${i}.worker.pem:/etc/ssl/filebeat.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh${i}.worker-key.pem:/etc/ssl/filebeat.key
      - ./config/wazuh_cluster/wazuh${i}_worker.conf:/wazuh-config-mount/etc/ossec.conf
EOF
    done

    # Add indexer services
    for ((i=1; i<=INDEXER_COUNT; i++)); do
        if [[ "$i" -eq 1 ]]; then
            # Add ports for the first indexer only
            cat <<EOF >> "$DOCKER_COMPOSE_FILE"
  wazuh${i}.indexer:
    image: wazuh/wazuh-indexer:4.9.1
    hostname: wazuh${i}.indexer
    restart: always
    ports:
      - "9200:9200"
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
      - wazuh-indexer-data-${i}:/var/lib/wazuh-indexer
      - ./config/wazuh_indexer_ssl_certs/root-ca.pem:/usr/share/wazuh-indexer/certs/root-ca.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh${i}.indexer-key.pem:/usr/share/wazuh-indexer/certs/wazuh${i}.indexer.key
      - ./config/wazuh_indexer_ssl_certs/wazuh${i}.indexer.pem:/usr/share/wazuh-indexer/certs/wazuh${i}.indexer.pem
      - ./config/wazuh_indexer/wazuh${i}.indexer.yml:/usr/share/wazuh-indexer/opensearch.yml
      - ./config/wazuh_indexer_ssl_certs/admin.pem:/usr/share/wazuh-indexer/certs/admin.pem
      - ./config/wazuh_indexer_ssl_certs/admin-key.pem:/usr/share/wazuh-indexer/certs/admin-key.pem
      - ./config/wazuh_indexer/internal_users.yml:/usr/share/wazuh-indexer/opensearch-security/internal_users.yml
EOF
        else
            # No ports for other indexers
            cat <<EOF >> "$DOCKER_COMPOSE_FILE"
  wazuh${i}.indexer:
    image: wazuh/wazuh-indexer:4.9.1
    hostname: wazuh${i}.indexer
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
      - wazuh-indexer-data-${i}:/var/lib/wazuh-indexer
      - ./config/wazuh_indexer_ssl_certs/root-ca.pem:/usr/share/wazuh-indexer/certs/root-ca.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh${i}.indexer-key.pem:/usr/share/wazuh-indexer/certs/wazuh${i}.indexer.key
      - ./config/wazuh_indexer_ssl_certs/wazuh${i}.indexer.pem:/usr/share/wazuh-indexer/certs/wazuh${i}.indexer.pem
      - ./config/wazuh_indexer/wazuh${i}.indexer.yml:/usr/share/wazuh-indexer/opensearch.yml
      - ./config/wazuh_indexer_ssl_certs/admin.pem:/usr/share/wazuh-indexer/certs/admin.pem
      - ./config/wazuh_indexer_ssl_certs/admin-key.pem:/usr/share/wazuh-indexer/certs/admin-key.pem
      - ./config/wazuh_indexer/internal_users.yml:/usr/share/wazuh-indexer/opensearch-security/internal_users.yml
EOF
        fi
    done

    # Add dashboard and nginx service
    cat <<EOF >> "$DOCKER_COMPOSE_FILE"
  wazuh.dashboard:
    image: wazuh/wazuh-dashboard:4.9.1
    hostname: wazuh.dashboard
    restart: always
    ports:
      - 443:5601
    environment:
      - OPENSEARCH_HOSTS="https://wazuh1.indexer:9200"
      - WAZUH_API_URL="https://wazuh.master"
      - API_USERNAME=wazuh-wui
      - API_PASSWORD=MyS3cr37P450r.*-
      - DASHBOARD_USERNAME=kibanaserver
      - DASHBOARD_PASSWORD=kibanaserver
    volumes:
      - ./config/wazuh_indexer_ssl_certs/wazuh.dashboard.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard.pem
      - ./config/wazuh_indexer_ssl_certs/wazuh.dashboard-key.pem:/usr/share/wazuh-dashboard/certs/wazuh-dashboard-key.pem
      - ./config/wazuh_indexer_ssl_certs/root-ca.pem:/usr/share/wazuh-dashboard/certs/root-ca.pem
      - ./config/wazuh_dashboard/opensearch_dashboards.yml:/usr/share/wazuh-dashboard/config/opensearch_dashboards.yml
      - ./config/wazuh_dashboard/wazuh.yml:/usr/share/wazuh-dashboard/data/wazuh/config/wazuh.yml
      - wazuh-dashboard-config:/usr/share/wazuh-dashboard/data/wazuh/config
      - wazuh-dashboard-custom:/usr/share/wazuh-dashboard/plugins/wazuh/public/assets/custom
    depends_on:
$(for ((i=1; i<=INDEXER_COUNT; i++)); do echo "      - wazuh${i}.indexer"; done)
    links:
      - wazuh.master:wazuh.master
$(for ((i=1; i<=INDEXER_COUNT; i++)); do echo "      - wazuh${i}.indexer:wazuh${i}.indexer"; done)

  nginx:
    image: nginx:stable
    hostname: nginx
    restart: always
    ports:
      - "1514:1514"
    depends_on:
      - wazuh.master
$(for ((i=1; i<=WORKER_COUNT; i++)); do echo "      - wazuh${i}.worker"; done)
      - wazuh.dashboard
    links:
      - wazuh.master:wazuh.master
      - wazuh.dashboard:wazuh.dashboard
$(for ((i=1; i<=WORKER_COUNT; i++)); do echo "      - wazuh${i}.worker:wazuh${i}.worker"; done)
    volumes:
      - ./config/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
EOF
    # Volume definitions
    cat <<EOF >> "$DOCKER_COMPOSE_FILE"

volumes:
  master-wazuh-api-configuration:
  master-wazuh-etc:
  master-wazuh-logs:
  master-wazuh-queue:
  master-wazuh-var-multigroups:
  master-wazuh-integrations:
  master-wazuh-active-response:
  master-wazuh-agentless:
  master-wazuh-wodles:
  master-filebeat-etc:
  master-filebeat-var:
$(for ((i=1; i<=WORKER_COUNT; i++)); do
    echo "  worker${i}-wazuh-api-configuration:"
    echo "  worker${i}-wazuh-etc:"
    echo "  worker${i}-wazuh-logs:"
    echo "  worker${i}-wazuh-queue:"
    echo "  worker${i}-wazuh-var-multigroups:"
    echo "  worker${i}-wazuh-integrations:"
    echo "  worker${i}-wazuh-active-response:"
    echo "  worker${i}-wazuh-agentless:"
    echo "  worker${i}-wazuh-wodles:"
    echo "  worker${i}-filebeat-etc:"
    echo "  worker${i}-filebeat-var:"
done)
$(for ((i=1; i<=INDEXER_COUNT; i++)); do echo "  wazuh-indexer-data-${i}:"; done)
  wazuh-dashboard-config:
  wazuh-dashboard-custom:
EOF

    echo "docker-compose.yml created successfully for $NEW_DIR."
}

# Function to generate certs.yml dynamically
create_certs_yml() {
    CERTS_FILE="$NEW_DIR/config/certs.yml"
    echo "Creating certs.yml in $NEW_DIR/config..."

    cat <<EOF > "$CERTS_FILE"
nodes:
  # Wazuh indexer server nodes
  indexer:
$(for ((i=1; i<=INDEXER_COUNT; i++)); do echo "    - name: wazuh${i}.indexer"; echo "      ip: wazuh${i}.indexer"; done)

  # Wazuh server nodes
  server:
    - name: wazuh.master
      ip: wazuh.master
      node_type: master
$(for ((i=1; i<=WORKER_COUNT; i++)); do echo "    - name: wazuh${i}.worker"; echo "      ip: wazuh${i}.worker"; echo "      node_type: worker"; done)

  # Wazuh dashboard node
  dashboard:
    - name: wazuh.dashboard
      ip: wazuh.dashboard
EOF

    echo "certs.yml created with dynamic indexer and worker nodes."
}

# Main function
main() {
    get_user_input
    prepare_directories_and_files
    create_docker_compose
    create_certs_yml
    echo "Wazuh Cluster setup completed successfully in directory: $NEW_DIR"
}

main