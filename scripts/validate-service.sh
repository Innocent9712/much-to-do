#!/bin/bash
set -e

echo "Validating service..."

# Wait for the service to be ready
MAX_RETRIES=30
RETRY_COUNT=0

until [ $RETRY_COUNT -ge $MAX_RETRIES ]
do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Service validation passed!"
    echo "Health check returned: $HTTP_CODE"
    exit 0
  fi
  
  RETRY_COUNT=$((RETRY_COUNT+1))
  echo "Waiting for service to be ready (attempt $RETRY_COUNT/$MAX_RETRIES)..."
  sleep 2
done

echo "❌ Service validation failed after $MAX_RETRIES attempts"
echo "Checking container logs..."
docker logs muchtodo-api --tail 50

exit 1
