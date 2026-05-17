#!/bin/bash
set -e

echo "Building MuchTodo Docker image..."
docker build -t muchtodo-backend:latest .
echo "Build complete!"