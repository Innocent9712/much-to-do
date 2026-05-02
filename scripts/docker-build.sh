#!/bin/bash
echo "Building Docker image..."
docker build -t muchtodo-backend:latest .
echo "Build complete!"
