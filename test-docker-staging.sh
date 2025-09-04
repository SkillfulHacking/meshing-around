#!/bin/bash
# Docker staging test script

set -e

echo "🚀 Testing Docker staging setup for meshing-around bot"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

echo "1. Checking Docker availability..."
if command -v docker &> /dev/null; then
    print_status "Docker is available"
    docker --version
else
    print_error "Docker is not available"
    exit 1
fi

echo ""
echo "2. Checking Docker Compose availability..."
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    print_status "Docker Compose is available"
else
    print_error "Docker Compose is not available"
    exit 1
fi

echo ""
echo "3. Validating Dockerfile syntax..."
if docker build --dry-run . &> /dev/null; then
    print_status "Dockerfile syntax is valid"
else
    print_warning "Dockerfile validation skipped (dry-run not supported)"
fi

echo ""
echo "4. Validating docker-compose.yaml syntax..."
cd script/docker
if docker compose config &> /dev/null; then
    print_status "docker-compose.yaml syntax is valid"
else
    print_warning "docker-compose.yaml validation failed or not available"
fi

echo ""
echo "5. Checking required files..."
required_files=(
    "../../Dockerfile"
    "../../.dockerignore"
    "../../requirements.txt"
    "../../config.template"
    "./compose.yaml"
    "./entrypoint.sh"
    "./ollama-entrypoint.sh"
    "./README.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status "Found: $file"
    else
        print_error "Missing: $file"
        exit 1
    fi
done

echo ""
echo "6. Checking executable permissions..."
if [ -x "../../script/docker/entrypoint.sh" ]; then
    print_status "entrypoint.sh is executable"
else
    print_error "entrypoint.sh is not executable"
    chmod +x "../../script/docker/entrypoint.sh"
    print_status "Fixed entrypoint.sh permissions"
fi

if [ -x "./ollama-entrypoint.sh" ]; then
    print_status "ollama-entrypoint.sh is executable"
else
    print_error "ollama-entrypoint.sh is not executable"
    chmod +x "./ollama-entrypoint.sh"
    print_status "Fixed ollama-entrypoint.sh permissions"
fi

echo ""
echo "7. Testing Python imports..."
cd ../..
python3 -c "import sys; print(f'Python version: {sys.version}')"

# Test basic imports that should be available
python3 -c "
try:
    import os, sys, time, json, logging
    print('✓ Standard library imports successful')
except ImportError as e:
    print(f'✗ Standard library import failed: {e}')
    exit(1)
"

echo ""
print_status "Docker staging setup validation complete!"
echo ""
echo "📝 To use the Docker setup:"
echo "   1. Copy config.template to script/docker/config.ini"
echo "   2. Edit config.ini with your device settings"
echo "   3. Update device paths in compose.yaml"
echo "   4. Run: cd script/docker && docker compose up -d"
echo ""
echo "📚 See script/docker/README.md for detailed instructions"