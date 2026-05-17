#!/bin/bash
set -e

echo "Starting MuchTodo with Docker Compose..."

docker-compose down --remove-orphans
docker network rm muchtodo_default 2>/dev/null || true

docker-compose up --build -d

echo "Waiting for services to be ready..."
sleep 5

echo "Services status:"
docker-compose ps

echo ""
echo "App available at:     http://localhost:8080"
echo "Health check:         http://localhost:8080/health"
echo "Mongo Express:        http://localhost:8081"
echo "Redis Commander:      http://localhost:8082"
echo ""
echo "To watch logs run:    docker-compose logs -f"