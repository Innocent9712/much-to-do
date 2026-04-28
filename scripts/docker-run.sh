#!/bin/bash

echo "Starting docker-compose..."
docker compose up --build -d

echo "App running on http://localhost:8080"