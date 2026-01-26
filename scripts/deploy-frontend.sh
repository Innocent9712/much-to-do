#!/bin/bash
set -e

# Frontend deployment script
# Usage: ./deploy-frontend.sh <environment> <s3-bucket> <cloudfront-id>

ENVIRONMENT=${1:-staging}
S3_BUCKET=${2}
CLOUDFRONT_ID=${3}

if [ -z "$S3_BUCKET" ] || [ -z "$CLOUDFRONT_ID" ]; then
    echo "Usage: ./deploy-frontend.sh <environment> <s3-bucket> <cloudfront-id>"
    exit 1
fi

echo "🚀 Deploying frontend to $ENVIRONMENT..."

cd Client

# Install dependencies
echo "📦 Installing dependencies..."
npm ci

# Build the application
echo "🔨 Building application..."
if [ "$ENVIRONMENT" == "production" ]; then
    VITE_API_BASE_URL=${API_BASE_URL_PROD} npm run build
else
    VITE_API_BASE_URL=${API_BASE_URL_STAGING} npm run build
fi

# Sync to S3
echo "☁️  Syncing to S3..."
aws s3 sync dist/ s3://${S3_BUCKET} --delete \
    --cache-control "public, max-age=31536000, immutable" \
    --exclude "index.html" \
    --exclude "*.map"

aws s3 cp dist/index.html s3://${S3_BUCKET}/index.html \
    --cache-control "public, max-age=0, must-revalidate" \
    --content-type "text/html"

# Invalidate CloudFront cache
echo "🔄 Invalidating CloudFront cache..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id ${CLOUDFRONT_ID} \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo "✅ Frontend deployed successfully!"
echo "Environment: $ENVIRONMENT"
echo "S3 Bucket: $S3_BUCKET"
echo "CloudFront Distribution: $CLOUDFRONT_ID"
echo "Invalidation ID: $INVALIDATION_ID"
