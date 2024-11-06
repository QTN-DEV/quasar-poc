FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y wget sudo lsb-release curl make gcc autoconf libtool libssl-dev pkg-config jq

# Download and install YARA
RUN curl -LO https://github.com/VirusTotal/yara/archive/v4.2.3.tar.gz \
    && tar -xvzf v4.2.3.tar.gz -C /usr/local/bin/ && rm -f v4.2.3.tar.gz \
    && cd /usr/local/bin/yara-4.2.3/ \
    && ./bootstrap.sh && ./configure && make && make install && make check

# Verify YARA Command
RUN echo "/usr/local/lib" >> /etc/ld.so.conf \
    && ldconfig

# Download YARA detection rules
RUN mkdir -p /tmp/yara/rules && \
    curl 'https://valhalla.nextron-systems.com/api/v1/get' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data 'demo=demo&apikey=YOUR_API_KEY&format=text' \
    -o /tmp/yara/rules/yara_rules.yar

# Download Wazuh agent
RUN wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.1-1_amd64.deb

# Copy entrypoint script and yara.sh for active response
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY yara.sh /var/ossec/active-response/bin/yara.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /var/ossec/active-response/bin/yara.sh \
    && chmod 750 /var/ossec/active-response/bin/yara.sh

# Expose necessary volumes
VOLUME ["/var/ossec/logs", "/tmp/yara"]

# Use custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]