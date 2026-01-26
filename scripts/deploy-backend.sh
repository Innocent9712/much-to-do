#!/bin/bash
set -e

# Backend deployment script via CodeDeploy
# Usage: ./deploy-backend.sh <environment> <revision-location>

ENVIRONMENT=${1:-staging}
S3_BUCKET=${CODEDEPLOY_S3_BUCKET}
S3_KEY=${2}
CODEDEPLOY_APP=${CODEDEPLOY_APP:-muchtodo-app}

if [ "$ENVIRONMENT" == "production" ]; then
    DEPLOYMENT_GROUP=${CODEDEPLOY_GROUP_PROD}
else
    DEPLOYMENT_GROUP=${CODEDEPLOY_GROUP_STAGING}
fi

if [ -z "$S3_KEY" ]; then
    echo "Usage: ./deploy-backend.sh <environment> <s3-key>"
    exit 1
fi

echo "🚀 Deploying backend to $ENVIRONMENT..."

# Create deployment
echo "📦 Creating CodeDeploy deployment..."
DEPLOYMENT_ID=$(aws deploy create-deployment \
    --application-name ${CODEDEPLOY_APP} \
    --deployment-group-name ${DEPLOYMENT_GROUP} \
    --s3-location bucket=${S3_BUCKET},key=${S3_KEY},bundleType=zip \
    --description "Manual deployment to ${ENVIRONMENT}" \
    --query 'deploymentId' \
    --output text)

echo "Deployment ID: ${DEPLOYMENT_ID}"
echo "Waiting for deployment to complete..."

# Wait for deployment
aws deploy wait deployment-successful --deployment-id ${DEPLOYMENT_ID}

echo "✅ Backend deployed successfully!"
echo "Environment: $ENVIRONMENT"
echo "Deployment ID: $DEPLOYMENT_ID"
