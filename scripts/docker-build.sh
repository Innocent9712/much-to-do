#!/bin/bash

echo "Building Docker image..."
docker build -t much-to-do-backend:latest .

echo "Done."