#!/bin/bash
# Script to increase Podman VM memory

echo "🛑 Stopping Podman machine..."
podman machine stop

echo "⚙️  Increasing memory to 12GB..."
podman machine set --memory 12288

echo "🚀 Starting Podman machine..."
podman machine start

echo "✅ Done! Podman now has 12GB RAM"
podman machine info | grep -i memory
