#!/bin/bash
# health-check.sh - Smoke test script for verifying Frontend and Backend endpoints

BASE_URL=${1:-"http://localhost:8080"}
MAX_RETRIES=${2:-12}
DELAY=${3:-15}

echo "=================================================="
echo " Starting Smoke Tests & Health Checks "
echo " Target URL: $BASE_URL"
echo " Retries   : $MAX_RETRIES (every ${DELAY}s)"
echo "=================================================="

# Helper function to check endpoint
check_endpoint() {
  local endpoint=$1
  local expected_status=$2
  local url="${BASE_URL}${endpoint}"
  
  echo -n "Checking $url ... "
  response=$(curl -s -w "%{http_code}" -o /tmp/resp.txt "$url")
  status_code=${response: -3}
  
  if [ "$status_code" -eq "$expected_status" ]; then
    echo "SUCCESS (HTTP $status_code)"
    cat /tmp/resp.txt
    echo ""
    return 0
  else
    echo "FAILED (HTTP $status_code)"
    return 1
  fi
}

# Main retry loop
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
  echo "--- Attempt $attempt of $MAX_RETRIES ---"
  
  # Check backend endpoints
  backend_ok=true
  
  # Check /health
  if ! check_endpoint "/health" 200; then
    backend_ok=false
  fi
  
  # If all backend checks pass, exit successfully
  if [ "$backend_ok" = true ]; then
    echo "=================================================="
    echo " Health Check Passed! Application is healthy. "
    echo "=================================================="
    exit 0
  fi
  
  echo "Application not fully ready yet. Sleeping for ${DELAY}s..."
  sleep $DELAY
  attempt=$((attempt + 1))
done

echo "=================================================="
echo " ERROR: Health Check Timed Out after $MAX_RETRIES attempts! "
echo "=================================================="
exit 1
