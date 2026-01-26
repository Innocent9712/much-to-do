#!/bin/bash
set -e

echo "Stopping backend application..."

# Check if container is running
if [ "$(docker ps -q -f name=muchtodo-api)" ]; then
    echo "Stopping existing container..."
    docker stop muchtodo-api || true
    docker rm muchtodo-api || true
else
    echo "No running container found."
fi

echo "Backend application stopped successfully."
