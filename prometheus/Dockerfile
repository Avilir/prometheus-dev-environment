# Custom Prometheus Dockerfile for development environment
FROM docker.io/prom/prometheus:v2.47.0

# Switch to root to install additional tools if needed
USER root

# Install additional debugging tools (optional)
RUN apk add --no-cache \
    curl \
    jq \
    vim \
    bash \
    tzdata

# Create directories for custom configs and rules
RUN mkdir -p /etc/prometheus/rules \
    && mkdir -p /etc/prometheus/file_sd \
    && chown -R nobody:nobody /etc/prometheus

# Optional: Copy custom entrypoint script if it exists
# Uncomment the following line when you have docker-entrypoint.sh
# COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

# Optional: Copy custom rules if they exist
# Uncomment the following line when you have rules directory
# COPY rules/*.yml /etc/prometheus/rules/

# Set timezone to match host (optional)
ENV TZ=UTC

# Switch back to nobody user for security
USER nobody

# Expose Prometheus port
EXPOSE 9090

# Volume for data persistence
VOLUME ["/prometheus"]

# Use the original entrypoint if no custom one exists
ENTRYPOINT ["/bin/prometheus"]

# Default command arguments
CMD ["--config.file=/etc/prometheus/prometheus.yml", \
    "--storage.tsdb.path=/prometheus", \
    "--web.console.libraries=/usr/share/prometheus/console_libraries", \
    "--web.console.templates=/usr/share/prometheus/consoles", \
    "--web.enable-lifecycle"]