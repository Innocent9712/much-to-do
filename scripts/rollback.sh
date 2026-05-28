#!/bin/bash
# rollback.sh - Automated rollback script for application deployments

set -e

COMPONENT=${1:-"backend"}
TARGET_VERSION=$2
REGION=${3:-${AWS_REGION:-"us-east-1"}}

echo "=================================================="
echo " Starting Rollback Procedure "
echo " Component: $COMPONENT"
echo " Region   : $REGION"
echo "=================================================="

rollback_backend() {
  # Get ASG Name
  ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'techcorp-backend')].AutoScalingGroupName" --output text --region "$REGION" || echo "")
  if [ -z "$ASG_NAME" ]; then
    echo "Error: Could not locate backend Auto Scaling Group in region $REGION."
    exit 1
  fi

  # Determine version to roll back to
  if [ -z "$TARGET_VERSION" ]; then
    echo "No version specified. Fetching previous version from SSM Parameter Store history..."
    # Get the second to last parameter version (the previous release)
    TARGET_VERSION=$(aws ssm get-parameter-history \
      --name "/starttech/backend/image_tag" \
      --query "Parameters[-2].Value" \
      --output text \
      --region "$REGION" 2>/dev/null || echo "")
      
    if [ -z "$TARGET_VERSION" ] || [ "$TARGET_VERSION" = "None" ]; then
      echo "Error: Could not retrieve parameter history. Please specify a target version tag manually."
      exit 1
    fi
  fi

  echo "Rolling back Backend in ASG ($ASG_NAME) to version tag: $TARGET_VERSION"

  # Update SSM Parameter Store
  aws ssm put-parameter \
    --name "/starttech/backend/image_tag" \
    --value "$TARGET_VERSION" \
    --type "String" \
    --overwrite \
    --region "$REGION"

  # Trigger instance refresh to roll back instances
  REFRESH_ID=$(aws autoscaling start-instance-refresh \
    --auto-scaling-group-name "$ASG_NAME" \
    --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 180}' \
    --query "InstanceRefreshId" \
    --output text \
    --region "$REGION")

  echo "Backend Rollback Instance Refresh triggered!"
  echo "Refresh ID: $REFRESH_ID"
}

rollback_frontend() {
  echo "Frontend rollback usually requires running the CI/CD pipeline on a previous stable git commit."
  echo "Alternatively, if you backed up S3 assets, restore them from your backup bucket."
  echo "Usage: git checkout <stable-commit-sha> && git push origin main"
}

case "$COMPONENT" in
  backend)
    rollback_backend
    ;;
  frontend)
    rollback_frontend
    ;;
  *)
    echo "Error: Unknown component '$COMPONENT'. Must be 'backend' or 'frontend'."
    echo "Usage: ./rollback.sh [backend|frontend] [target-version-tag] [region]"
    exit 1
    ;;
esac

echo "Rollback instruction submitted successfully!"
