#!/bin/bash
set -e

ENVIRONMENT=${1:-production}
ASG_NAME=${2:-$ASG_NAME}

if [ -z "$ASG_NAME" ]; then
  echo "Usage: $0 <environment> <asg-name>"
  exit 1
fi

echo "Rolling back $ASG_NAME..."

# Cancel any active instance refresh
ACTIVE_REFRESH=$(aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name $ASG_NAME \
  --query 'InstanceRefreshes[?Status==`InProgress`].InstanceRefreshId' \
  --output text)

if [ -n "$ACTIVE_REFRESH" ]; then
  echo "Cancelling active refresh: $ACTIVE_REFRESH"
  aws autoscaling cancel-instance-refresh \
    --auto-scaling-group-name $ASG_NAME
fi

# Get previous launch template version
LT_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --query 'AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId' \
  --output text)

PREV_VERSION=$(aws ec2 describe-launch-template-versions \
  --launch-template-id $LT_ID \
  --query 'LaunchTemplateVersions[1].VersionNumber' \
  --output text)

echo "Reverting to launch template version: $PREV_VERSION"

aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name $ASG_NAME \
  --launch-template "LaunchTemplateId=$LT_ID,Version=$PREV_VERSION"

# Trigger instance refresh with old version
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --strategy Rolling \
  --preferences MinHealthyPercentage=50,InstanceWarmup=300

echo "Rollback initiated. Monitor with:"
echo "aws autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME"