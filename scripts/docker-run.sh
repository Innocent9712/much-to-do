#!/bin/bash
set -e

# Generate MongoDB keyfile if it doesn't exist
if [ ! -f "mongodb.key" ]; then
  echo " Generating MongoDB keyfile..."
  openssl rand -base64 756 > mongodb.key
  chmod 400 mongodb.key
  echo " mongodb.key generated."
fi

echo " Starting MuchToDo with docker-compose..."
docker compose up -d

echo ""
echo " Services started!"
echo ""
echo " Service status:"
docker compose ps

echo ""
echo "Backend API:        http://localhost:8080"
echo " Health check:       http://localhost:8080/health"
echo " Swagger docs:       http://localhost:8080/swagger/index.html"
echo " Mongo Express:      http://localhost:8081"
echo " Redis Commander:    http://localhost:8082"
echo ""
echo " To view logs: docker compose logs -f"
echo " To stop:      docker compose down"