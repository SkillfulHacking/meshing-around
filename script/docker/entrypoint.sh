#!/bin/bash
# entrypoint script for the meshing-around docker container

set -e

echo "Starting meshing-around bot container..."
echo "Timestamp: $(date)"

# Check if config.ini exists, if not copy from template
if [ ! -f /app/config.ini ]; then
    echo "Config file not found, copying from template..."
    cp /app/config.template /app/config.ini
fi

# Create directories if they don't exist
mkdir -p /app/logs /app/data

# Check if the config file has the proper interface configured
if grep -q "type = serial" /app/config.ini && grep -q "# port = '/dev/ttyUSB0'" /app/config.ini; then
    echo "WARNING: Default serial interface configuration detected."
    echo "Please update config.ini with your actual device settings."
fi

echo "Starting mesh bot..."
echo "Python version: $(python --version)"
echo "Working directory: $(pwd)"

# Optional: Substitute environment variables in the config file
# envsubst < /app/config.ini > /app/config.tmp && mv /app/config.tmp /app/config.ini

# Run the bot with error handling
exec python /app/mesh_bot.py