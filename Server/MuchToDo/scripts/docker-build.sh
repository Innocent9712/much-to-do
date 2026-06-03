#!/bin/bash
set -e

echo "Building MuchTodo Docker image..."
docker build -t muchtodo-app:latest .
echo "Docker image built successfully."