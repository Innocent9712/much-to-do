#!/bin/bash
# deploy-backend.sh - Automated backend deployment script (ASG Rolling Update)

set -e

ASG_NAME=${1:-$AUTO_SCALING_GROUP_NAME}
IMAGE_TAG=${2:-$GITHUB_SHA}
REGION=${3:-${AWS_REGION:-"us-east-1"}}

if [ -z "$ASG_NAME" ] || [ -z "$IMAGE_TAG" ]; then
  echo "Error: Missing required Auto Scaling Group name or Image Tag."
  echo "Usage: ./deploy-backend.sh <asg-name> <image-tag> [aws-region]"
  exit 1
fi

echo "=================================================="
echo " Starting Backend ASG Rolling Update "
echo " ASG Name   : $ASG_NAME"
echo " Image Tag  : $IMAGE_TAG"
echo " AWS Region : $REGION"
echo "=================================================="

# Update SSM Parameter Store with the new image tag
echo "Updating image tag in SSM Parameter Store..."
aws ssm put-parameter \
  --name "/starttech/backend/image_tag" \
  --value "$IMAGE_TAG" \
  --type "String" \
  --overwrite \
  --region "$REGION"

# Trigger rolling update on ASG
echo "Initiating ASG Instance Refresh..."
REFRESH_ID=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 300}' \
  --query "InstanceRefreshId" \
  --output text \
  --region "$REGION")

echo "ASG Instance Refresh successfully triggered!"
echo "Refresh ID: $REFRESH_ID"
echo "You can monitor status with: aws autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME --region $REGION"
