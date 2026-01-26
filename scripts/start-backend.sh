#!/bin/bash
set -e

echo "Starting backend application..."

cd /opt/muchtodo

# Start the Docker container
docker run -d \
  --name muchtodo-api \
  --restart unless-stopped \
  -p 8080:8080 \
  -e PORT=8080 \
  -e MONGODB_URI=${MONGODB_URI} \
  -e REDIS_URL=${REDIS_URL} \
  -e JWT_SECRET=${JWT_SECRET} \
  -e JWT_EXPIRATION=${JWT_EXPIRATION} \
  -e ENVIRONMENT=${ENVIRONMENT} \
  --log-driver=awslogs \
  --log-opt awslogs-region=${AWS_REGION} \
  --log-opt awslogs-group=/aws/ec2/muchtodo-api \
  --log-opt awslogs-stream=${ENVIRONMENT}-$(hostname) \
  ${ECR_REGISTRY}/${ECR_REPOSITORY}:${ENVIRONMENT}

echo "Waiting for application to start..."
sleep 10

echo "Backend application started successfully."
