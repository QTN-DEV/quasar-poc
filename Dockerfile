# Stage 1: Builder Stage for Python Wheels
FROM bitnami/minideb@sha256:bce8004f7da6547bc568e92895e1b3a3835e6dba48283fbbf9b3f66c1d166c6d as builder
COPY requirements.txt /tmp
RUN install_packages python3-pip python3-setuptools python3-dev gcc && \
    python3 -m pip wheel -w /tmp/wheel -r /tmp/requirements.txt && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Stage 2: Final Image
FROM bitnami/minideb@sha256:bce8004f7da6547bc568e92895e1b3a3835e6dba48283fbbf9b3f66c1d166c6d
LABEL maintainer="support@opennix.org"
LABEL description="Wazuh Docker Agent"
ARG AGENT_VERSION="4.7.2-1"

# Environment variables for Wazuh agent and VirusTotal integration
ENV JOIN_MANAGER_MASTER_HOST="" \
    JOIN_MANAGER_WORKER_HOST="" \
    VIRUS_TOTAL_KEY="" \
    JOIN_MANAGER_PROTOCOL="https" \
    JOIN_MANAGER_USER="" \
    JOIN_MANAGER_PASSWORD="" \
    JOIN_MANAGER_API_PORT="55000" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install essential packages and Wazuh agent
RUN install_packages procps curl apt-transport-https gnupg2 inotify-tools \
    python3-docker python3-pip openjdk-11-jdk && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list && \
    echo "deb https://deb.debian.org/debian-security/ bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
    install_packages wazuh-agent=${AGENT_VERSION} && \
    apt-get clean autoclean && apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ /tmp/* /var/tmp/* /var/log/*

# Copy Python scripts and templates
COPY *.py *.jinja2 /var/ossec/
WORKDIR /var/ossec/

# Copy Python wheels from the builder stage and install
COPY --from=builder /tmp/wheel /tmp/wheel
RUN pip3 install --no-index /tmp/wheel/*.whl && \
    chmod +x /var/ossec/deregister_agent.py /var/ossec/register_agent.py && \
    chown -R wazuh:wazuh /var/ossec/

# Expose the necessary port and set the entry point
EXPOSE 5000
ENTRYPOINT ["./register_agent.py"]
