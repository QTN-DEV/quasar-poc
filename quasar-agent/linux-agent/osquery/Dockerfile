# Use Ubuntu as the base image
FROM ubuntu:22.04

# Install prerequisites
RUN apt-get update && apt-get install -y gnupg software-properties-common curl

# Define OSQUERY_KEY as a build argument
ARG OSQUERY_KEY

# Add Osquery GPG key and repository
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$OSQUERY_KEY" \
    && add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main' \
    && apt-get update

# Install Osquery
RUN apt-get install -y osquery

# Copy custom Osquery configuration into the container
COPY osquery.conf /etc/osquery/osquery.conf

# Copy entrypoint script and set permissions
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Run entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]