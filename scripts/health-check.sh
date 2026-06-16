#!/bin/bash
set -e

ALB_URL=${1:-$ALB_DNS_NAME}
MAX_RETRIES=${2:-10}
RETRY_DELAY=${3:-10}

if [ -z "$ALB_URL" ]; then
  echo "Usage: $0 <alb-url> [max-retries] [retry-delay]"
  exit 1
fi

echo "Health checking: $ALB_URL"
echo "Max retries: $MAX_RETRIES"

for i in $(seq 1 $MAX_RETRIES); do
  RESPONSE=$(curl -sf http://$ALB_URL/health || echo "FAIL")
  
  if [ "$RESPONSE" != "FAIL" ]; then
    echo "✓ Health check passed (attempt $i)"
    echo "Response: $RESPONSE"
    exit 0
  fi
  
  echo "✗ Attempt $i failed, waiting ${RETRY_DELAY}s..."
  sleep $RETRY_DELAY
done

echo "Health check failed after $MAX_RETRIES attempts"
exit 1