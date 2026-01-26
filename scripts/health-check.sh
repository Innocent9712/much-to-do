#!/bin/bash
set -e

# Health check script
# Usage: ./health-check.sh <api-url>

API_URL=${1:-http://localhost:8080}
MAX_RETRIES=10
RETRY_COUNT=0

echo "🏥 Running health check against $API_URL..."

until [ $RETRY_COUNT -ge $MAX_RETRIES ]
do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" ${API_URL}/health || echo "000")
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo "✅ Health check passed!"
    echo "API is responding correctly"
    
    # Additional endpoint checks
    echo ""
    echo "Testing additional endpoints..."
    
    # Test API docs endpoint
    DOCS_CODE=$(curl -s -o /dev/null -w "%{http_code}" ${API_URL}/swagger/index.html || echo "000")
    if [ "$DOCS_CODE" == "200" ]; then
      echo "✅ API documentation is accessible"
    else
      echo "⚠️  API documentation returned: $DOCS_CODE"
    fi
    
    exit 0
  fi
  
  RETRY_COUNT=$((RETRY_COUNT+1))
  echo "Health check failed (attempt $RETRY_COUNT/$MAX_RETRIES). HTTP Code: $HTTP_CODE"
  
  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "Retrying in 5 seconds..."
    sleep 5
  fi
done

echo "❌ Health check failed after $MAX_RETRIES attempts"
echo "API is not responding at $API_URL"
exit 1
