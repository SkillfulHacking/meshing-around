FROM python:3.13-slim
ENV PYTHONUNBUFFERED=1

# Install system dependencies including ca-certificates for SSL
RUN apt-get update && apt-get install -y \
    gettext \
    tzdata \
    locales \
    nano \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set the locale default to en_US.UTF-8
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG="en_US.UTF-8"
ENV TZ="America/Los_Angeles"

# Update ca-certificates and upgrade pip
RUN update-ca-certificates && pip install --upgrade pip

WORKDIR /app

# Copy requirements first for better Docker layer caching
COPY requirements.txt /app/requirements.txt

# Install core dependencies first with SSL bypass for CI/build environments  
RUN pip install --no-cache-dir \
    --timeout 300 \
    --retries 3 \
    --trusted-host pypi.org \
    --trusted-host pypi.python.org \
    --trusted-host files.pythonhosted.org \
    meshtastic pubsub requests || \
    (echo "Fallback to basic pip install" && pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org meshtastic pubsub requests)

# Install additional dependencies
RUN pip install --no-cache-dir \
    --timeout 300 \
    --retries 2 \
    --trusted-host pypi.org \
    --trusted-host pypi.python.org \
    --trusted-host files.pythonhosted.org \
    pyephem maidenhead beautifulsoup4 \
    dadjokes geopy schedule wikipedia \
    googlesearch-python || echo "Some optional packages failed to install"

# Copy the rest of the application
COPY . /app

# Copy config template to config.ini if it doesn't exist
COPY config.template /app/config.ini

# Make entrypoint script executable
RUN chmod +x /app/script/docker/entrypoint.sh

# Create necessary directories
RUN mkdir -p /app/logs /app/data

# Expose any needed ports (if applicable)
# EXPOSE 8080

# Health check to ensure the application is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ps aux | grep -q "python.*mesh_bot.py" || exit 1

ENTRYPOINT ["/bin/bash", "/app/script/docker/entrypoint.sh"]
