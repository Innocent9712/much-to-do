#!/bin/bash
set -e

ENVIRONMENT=${1:-production}
ECR_REPO=${2:-$ECR_REPOSITORY}
ASG_NAME=${3:-$ASG_NAME}

if [ -z "$ECR_REPO" ] || [ -z "$ASG_NAME" ]; then
  echo "Error: ECR_REPOSITORY and ASG_NAME required"
  exit 1
fi

echo "Deploying backend..."
echo "Environment: $ENVIRONMENT"
echo "ECR: $ECR_REPO"

cd "$(dirname "$0")/../backend"

# Build and push
IMAGE_TAG=$(git rev-parse --short HEAD)
echo "Building image: $IMAGE_TAG"

aws ecr get-login-password | docker login --username AWS --password-stdin $(echo $ECR_REPO | cut -d'/' -f1)

docker build -t $ECR_REPO:latest -t $ECR_REPO:$IMAGE_TAG .
docker push $ECR_REPO:latest
docker push $ECR_REPO:$IMAGE_TAG

# Trigger rolling update
echo "Triggering instance refresh..."
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --strategy Rolling \
  --preferences MinHealthyPercentage=50,InstanceWarmup=300

echo "Backend deployment initiated!"
echo "Monitor progress: aws autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME"