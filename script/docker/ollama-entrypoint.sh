#!/bin/bash

set -e

echo "Starting Ollama service..."
echo "Timestamp: $(date)"

# Start Ollama in the background
/bin/ollama serve &
# Record Process ID
pid=$!

# Wait for Ollama to be ready
echo "Waiting for Ollama to start..."
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama is ready!"
        break
    fi
    echo "Waiting for Ollama... ($i/30)"
    sleep 2
done

# Pull the default model if it doesn't exist
echo "🔄 Checking for llama3.2:3b model..."
if ! ollama list | grep -q "llama3.2:3b"; then
    echo "🔴 Retrieving llama3.2:3b model..."
    ollama pull llama3.2:3b
    echo "🟢 Model downloaded!"
else
    echo "🟢 Model already available!"
fi

# Optional: Pull additional useful models
# echo "🔄 Retrieving additional models..."
# ollama pull gemma2:2b

echo "🟢 Ollama setup complete!"

# Wait for Ollama process to finish
wait $pid
