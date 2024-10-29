# Stage 1: Base setup
FROM ubuntu:22.04 AS base

# Update and install necessary tools
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    curl \
    python3 \
    python3-venv \
    python3-pip \
    npm \
    git \
    wget \
    && apt-get clean

# Install Node.js and NPM via NVM
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash \
    && . /root/.nvm/nvm.sh \
    && nvm install stable \
    && nvm use stable \
    && [ ! -e /usr/bin/node ] && ln -s /root/.nvm/versions/node/$(nvm current)/bin/node /usr/bin/node || true \
    && [ ! -e /usr/bin/npm ] && ln -s /root/.nvm/versions/node/$(nvm current)/bin/npm /usr/bin/npm || true

# Stage 2: Install Go
FROM base AS golang

RUN wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz \
    && rm go1.22.0.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

# Stage 3: Install Caldera and dependencies
FROM golang AS caldera

# Clone Caldera repository
RUN git clone https://github.com/mitre/caldera.git --recursive /app/caldera

# Set working directory
WORKDIR /app/caldera

# Ensure the plugins directory exists
RUN mkdir -p /app/caldera/plugins

# Create Python virtual environment and install requirements
RUN python3 -m venv /app/caldera/venv \
    && . /app/caldera/venv/bin/activate \
    && pip install --no-cache-dir -r requirements.txt

# Prepare Magma plugin
WORKDIR /app/caldera/plugins/magma

# Set NODE_ENV to development for proper dependency resolution
ENV NODE_ENV=development

# Create package.json and install dependencies with specific versions
RUN npm init -y \
    && npm install vue@3.2.37 @vitejs/plugin-vue@2.3.1 @vue/compiler-sfc@3.2.37 fs-extra --legacy-peer-deps

# Clear cache to ensure no previous issues persist
RUN rm -rf /root/.cache && npm cache clean --force

# Build Magma plugin
RUN npm run build || (echo "Error: Check vue and vite installation"; exit 1)

# Modify the API base URL in default.yml, defaulting to localhost if not set
ENV API_BASE_URL=http://localhost:8888
RUN sed -i "s|app.frontend.api_base_url:.*|app.frontend.api_base_url: ${API_BASE_URL}|" /app/caldera/conf/default.yml

# Expose the port used by Caldera
EXPOSE 8888

# Reset working directory to /app/caldera for server.py to locate plugins
WORKDIR /app/caldera

# Command to run Caldera server
CMD ["bash", "-c", "source /app/caldera/venv/bin/activate && python3 /app/caldera/server.py --insecure --build"]