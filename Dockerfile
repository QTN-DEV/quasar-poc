FROM ubuntu:latest

ENV WAZUH_MANAGER=13.214.175.48
ENV WAZUH_AGENT_NAME=quasar-poc

RUN apt-get update && apt-get install -y wget sudo lsb-release adduser

RUN wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb && \
    WAZUH_MANAGER=$WAZUH_MANAGER WAZUH_AGENT_NAME=$WAZUH_AGENT_NAME dpkg -i ./wazuh-agent_4.9.0-1_amd64.deb && \
    rm ./wazuh-agent_4.9.0-1_amd64.deb

CMD ["/bin/bash", "-c", "service wazuh-agent start && tail -f /var/ossec/logs/ossec.log"]