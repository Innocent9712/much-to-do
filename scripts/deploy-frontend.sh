#!/bin/bash
set -e

ENVIRONMENT=${1:-production}
BUCKET_NAME=${2:-$FRONTEND_S3_BUCKET}
DISTRIBUTION_ID=${3:-$CLOUDFRONT_DISTRIBUTION_ID}

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: S3 bucket name required. Pass as arg or set FRONTEND_S3_BUCKET env var."
  exit 1
fi

if [ -z "$ALB_DNS_NAME" ] && [ -z "$VITE_API_BASE_URL" ]; then
  echo "Error: ALB_DNS_NAME or VITE_API_BASE_URL must be set."
  exit 1
fi

# Prefer explicit VITE_API_BASE_URL; fall back to constructing from ALB DNS
VITE_API_BASE_URL="${VITE_API_BASE_URL:-http://$ALB_DNS_NAME}"

echo "Deploying frontend to S3..."
echo "Environment:   $ENVIRONMENT"
echo "Bucket:        $BUCKET_NAME"
echo "API Base URL:  $VITE_API_BASE_URL"

cd "$(dirname "$0")/../frontend"

# Build with the injected API URL
echo "Building..."
npm install
VITE_API_BASE_URL="$VITE_API_BASE_URL" npm run build

# Deploy to S3 with cache headers
echo "Syncing to S3..."
aws s3 sync dist/ s3://$BUCKET_NAME \
  --delete \
  --cache-control "max-age=31536000,immutable" \
  --exclude "index.html"

aws s3 cp dist/index.html s3://$BUCKET_NAME/index.html \
  --cache-control "no-cache, no-store, must-revalidate"

# Invalidate CloudFront
if [ -n "$DISTRIBUTION_ID" ]; then
  echo "Invalidating CloudFront cache..."
  aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/index.html" "/*"
fi

echo "Frontend deployment complete!"
echo "Live at: https://$CLOUDFRONT_DOMAIN"