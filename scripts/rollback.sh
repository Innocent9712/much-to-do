#!/bin/bash
set -e

# Rollback script
# Usage: ./rollback.sh <component> <environment> [deployment-id]

COMPONENT=${1}  # frontend or backend
ENVIRONMENT=${2:-staging}
DEPLOYMENT_ID=${3}

if [ -z "$COMPONENT" ]; then
    echo "Usage: ./rollback.sh <frontend|backend> <environment> [deployment-id]"
    exit 1
fi

case "$COMPONENT" in
    frontend)
        echo "🔄 Rolling back frontend..."
        
        S3_BUCKET=$([[ "$ENVIRONMENT" == "production" ]] && echo "$S3_BUCKET_PROD" || echo "$S3_BUCKET_STAGING")
        CLOUDFRONT_ID=$([[ "$ENVIRONMENT" == "production" ]] && echo "$CLOUDFRONT_ID_PROD" || echo "$CLOUDFRONT_ID_STAGING")
        
        if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_ID" ]; then
            echo "❌ Missing S3_BUCKET or CLOUDFRONT_ID environment variables"
            exit 1
        fi
        
        # S3 versioning should be enabled to rollback
        echo "📦 Checking S3 versioning..."
        VERSIONING=$(aws s3api get-bucket-versioning --bucket ${S3_BUCKET} --query 'Status' --output text)
        
        if [ "$VERSIONING" != "Enabled" ]; then
            echo "⚠️  S3 versioning is not enabled. Cannot rollback."
            echo "Enable versioning: aws s3api put-bucket-versioning --bucket ${S3_BUCKET} --versioning-configuration Status=Enabled"
            exit 1
        fi
        
        echo "To rollback, restore previous version from S3 console or use:"
        echo "aws s3api list-object-versions --bucket ${S3_BUCKET} --prefix index.html"
        echo "Then restore: aws s3api copy-object --bucket ${S3_BUCKET} --copy-source ${S3_BUCKET}/index.html?versionId=<VERSION_ID> --key index.html"
        ;;
        
    backend)
        echo "🔄 Rolling back backend..."
        
        CODEDEPLOY_APP=${CODEDEPLOY_APP:-muchtodo-app}
        DEPLOYMENT_GROUP=$([[ "$ENVIRONMENT" == "production" ]] && echo "$CODEDEPLOY_GROUP_PROD" || echo "$CODEDEPLOY_GROUP_STAGING")
        
        if [ -z "$DEPLOYMENT_GROUP" ]; then
            echo "❌ Missing CODEDEPLOY_GROUP environment variable"
            exit 1
        fi
        
        if [ -z "$DEPLOYMENT_ID" ]; then
            # Get the last successful deployment
            echo "📋 Finding last successful deployment..."
            DEPLOYMENT_ID=$(aws deploy list-deployments \
                --application-name ${CODEDEPLOY_APP} \
                --deployment-group-name ${DEPLOYMENT_GROUP} \
                --include-only-statuses Succeeded \
                --max-items 2 \
                --query 'deployments[1]' \
                --output text)
        fi
        
        if [ -z "$DEPLOYMENT_ID" ] || [ "$DEPLOYMENT_ID" == "None" ]; then
            echo "❌ No previous successful deployment found"
            exit 1
        fi
        
        echo "Rolling back to deployment: $DEPLOYMENT_ID"
        
        # Stop current deployment if in progress
        CURRENT_DEPLOYMENT=$(aws deploy list-deployments \
            --application-name ${CODEDEPLOY_APP} \
            --deployment-group-name ${DEPLOYMENT_GROUP} \
            --include-only-statuses Created InProgress Queued Ready \
            --max-items 1 \
            --query 'deployments[0]' \
            --output text)
        
        if [ ! -z "$CURRENT_DEPLOYMENT" ] && [ "$CURRENT_DEPLOYMENT" != "None" ]; then
            echo "Stopping current deployment: $CURRENT_DEPLOYMENT"
            aws deploy stop-deployment --deployment-id ${CURRENT_DEPLOYMENT} --auto-rollback-enabled
        fi
        
        # Create new deployment with previous revision
        echo "Creating rollback deployment..."
        REVISION=$(aws deploy get-deployment \
            --deployment-id ${DEPLOYMENT_ID} \
            --query 'deploymentInfo.revision' \
            --output json)
        
        NEW_DEPLOYMENT_ID=$(aws deploy create-deployment \
            --application-name ${CODEDEPLOY_APP} \
            --deployment-group-name ${DEPLOYMENT_GROUP} \
            --revision "${REVISION}" \
            --description "Rollback to deployment ${DEPLOYMENT_ID}" \
            --query 'deploymentId' \
            --output text)
        
        echo "✅ Rollback deployment created: ${NEW_DEPLOYMENT_ID}"
        echo "Monitor at: https://console.aws.amazon.com/codesuite/codedeploy/deployments/${NEW_DEPLOYMENT_ID}"
        ;;
        
    *)
        echo "❌ Invalid component: $COMPONENT"
        echo "Usage: ./rollback.sh <frontend|backend> <environment> [deployment-id]"
        exit 1
        ;;
esac

echo "✅ Rollback initiated for $COMPONENT ($ENVIRONMENT)"
