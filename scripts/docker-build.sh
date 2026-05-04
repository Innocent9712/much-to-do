#!/bin/bash
set -e

echo "Building MuchToDo Docker image..."

docker build -t muchtodo-backend:latest .

echo ""
echo " Docker image built successfully!"
docker images muchtodo-backend:latest