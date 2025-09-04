FROM python:3.13-slim AS builder
ENV PYTHONUNBUFFERED=1

# Install system dependencies including ca-certificates for SSL
RUN apt-get update && apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Update ca-certificates and upgrade pip
RUN update-ca-certificates && pip install --upgrade pip

# Create a virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir \
    --trusted-host pypi.org \
    --trusted-host pypi.python.org \
    --trusted-host files.pythonhosted.org \
    -r /tmp/requirements.txt

# Production stage
FROM python:3.13-slim AS production
ENV PYTHONUNBUFFERED=1

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    gettext \
    tzdata \
    locales \
    nano \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set the locale default to en_US.UTF-8
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG="en_US.UTF-8"
ENV TZ="America/Los_Angeles"

# Copy the virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# Copy the application
COPY . /app

# Copy config template to config.ini if it doesn't exist
COPY config.template /app/config.ini

# Make entrypoint script executable
RUN chmod +x /app/script/docker/entrypoint.sh

# Create necessary directories
RUN mkdir -p /app/logs /app/data

# Create non-root user for security
RUN groupadd -r meshbot && useradd -r -g meshbot meshbot
RUN chown -R meshbot:meshbot /app
USER meshbot

# Health check to ensure the application is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ps aux | grep -q "python.*mesh_bot.py" || exit 1

ENTRYPOINT ["/bin/bash", "/app/script/docker/entrypoint.sh"]
