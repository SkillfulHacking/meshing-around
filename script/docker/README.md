# Docker Setup for Meshing Around Bot

This directory contains Docker configuration for running the meshing-around bot in containers.

## Quick Start

1. **Copy and configure your settings:**
   ```bash
   cp config.template config.ini
   # Edit config.ini with your specific settings (serial port, interface type, etc.)
   ```

2. **Update device mapping:**
   Edit `compose.yaml` and update the device path to match your hardware:
   ```yaml
   devices:
     - /dev/ttyUSB0:/dev/ttyUSB0  # Change this to your actual device
   ```

3. **Start the services:**
   ```bash
   docker compose up -d
   ```

## Services

### meshing-around
The main bot container running the mesh bot application.
- **Image**: Built from local Dockerfile
- **Restart**: unless-stopped
- **Health check**: Monitors the Python process
- **Volumes**: Persists data and logs

### ollama (AI/LLM Service)
Provides local AI/LLM capabilities for the bot.
- **Image**: ollama/ollama:0.5.1
- **Model**: Automatically downloads llama3.2:3b
- **Port**: 11434
- **Memory**: Limited to 4GB, reserved 2GB

### node-exporter (Optional)
System monitoring metrics exporter.
- **Profile**: `monitoring` (disabled by default)
- **Port**: 9100

## Configuration

### Environment Variables
- `TZ`: Timezone (default: America/Los_Angeles)
- `PYTHONUNBUFFERED`: Python output buffering (set to 1)

### Volumes
- `./config.ini:/app/config.ini:ro` - Bot configuration (read-only)
- `./data:/app/data` - Persistent data storage
- `./logs:/app/logs` - Log files
- `ollama_data:/root/.ollama` - AI model storage

## Management Commands

### Build and Start
```bash
# Build and start all services
docker compose up -d

# Build only the meshing-around service
docker compose build meshing-around

# Start with monitoring enabled
docker compose --profile monitoring up -d
```

### Monitoring
```bash
# View logs
docker compose logs -f meshing-around
docker compose logs -f ollama

# Check service status
docker compose ps

# View resource usage
docker stats
```

### Configuration Management
```bash
# Edit config in container
docker compose exec meshing-around nano /app/config.ini

# Restart after config changes
docker compose restart meshing-around
```

### Maintenance
```bash
# Stop all services
docker compose down

# Stop and remove volumes (WARNING: This deletes data!)
docker compose down -v

# Update services
docker compose pull
docker compose up -d
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Errors**: The Dockerfile includes trusted hosts for pip installation.

2. **Device Permissions**: Ensure the user running Docker has access to the serial device:
   ```bash
   sudo usermod -a -G dialout $USER
   # Logout and login again
   ```

3. **Ollama Memory Issues**: Adjust memory limits in compose.yaml if needed:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 4G  # Reduce if you have less RAM
   ```

4. **Port Conflicts**: Change exposed ports if they conflict with existing services.

### Health Checks
All services include health checks. View status with:
```bash
docker compose ps
```

### Debugging
Access container shells for debugging:
```bash
# Main bot container
docker compose exec meshing-around /bin/bash

# Ollama container
docker compose exec ollama /bin/bash
```

## Security Considerations

- Config file is mounted read-only to prevent accidental modification
- Containers run with minimal privileges
- Network isolation via custom bridge network
- Data volumes are properly managed

## Performance Tuning

### For Raspberry Pi or Low-Memory Systems:
1. Reduce Ollama memory limits
2. Consider using a smaller AI model (gemma2:2b instead of llama3.2:3b)
3. Disable monitoring profile if not needed

### For High-Performance Systems:
1. Increase Ollama memory allocation
2. Enable monitoring profile
3. Consider running multiple bot instances for redundancy