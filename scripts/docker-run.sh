#!/bin/bash
echo "Starting services with Docker Compose..."
docker compose up --build -d
echo "Services running! API at http://localhost:8080"
