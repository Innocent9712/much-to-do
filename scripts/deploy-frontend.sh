#!/bin/bash
# deploy-frontend.sh - Automated frontend deployment script

set -e

# Load configurations
S3_BUCKET=${1:-$FRONTEND_S3_BUCKET}
DISTRIBUTION_ID=${2:-$CLOUDFRONT_DISTRIBUTION_ID}
API_URL=${3:-$VITE_API_BASE_URL}

if [ -z "$S3_BUCKET" ] || [ -z "$DISTRIBUTION_ID" ]; then
  echo "Error: Missing required S3 Bucket Name or CloudFront Distribution ID."
  echo "Usage: ./deploy-frontend.sh <s3-bucket-name> <cloudfront-distribution-id> [api-base-url]"
  exit 1
fi

echo "=================================================="
echo " Starting Frontend Deployment to S3 "
echo " S3 Bucket   : s3://$S3_BUCKET"
echo " CloudFront  : $DISTRIBUTION_ID"
echo " Backend API : $API_URL"
echo "=================================================="

# Move to frontend directory
cd "$(dirname "$0")/../frontend"

# Build React app with API Url
echo "Building React static assets..."
VITE_API_BASE_URL="$API_URL" npm run build

# Deploy assets to S3
echo "Uploading files to S3 bucket..."
aws s3 sync dist/ "s3://$S3_BUCKET" --delete --cache-control "max-age=31536000,public"

# Ensure index.html is never cached locally
echo "Updating metadata for index.html..."
aws s3 cp dist/index.html "s3://$S3_BUCKET/index.html" --cache-control "no-cache,no-store,must-revalidate"

# Invalidate CDN cache
echo "Creating CloudFront cache invalidation..."
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  --query "Invalidation.Id" --output text)

echo "CloudFront Invalidation created: $INVALIDATION_ID"
echo "Frontend Deployment Completed Successfully!"
