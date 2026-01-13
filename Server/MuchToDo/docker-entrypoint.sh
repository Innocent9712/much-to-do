#!/bin/sh
set -e

# Create .env file from environment variables for viper to read
cat > /app/.env << EOF
PORT=${PORT:-8080}
MONGO_URI=${MONGO_URI}
DB_NAME=${DB_NAME:-much_todo_db}
JWT_SECRET_KEY=${JWT_SECRET_KEY:-default-jwt-secret}
JWT_EXPIRATION_HOURS=${JWT_EXPIRATION_HOURS:-72}
ENABLE_CACHE=${ENABLE_CACHE:-false}
REDIS_ADDR=${REDIS_ADDR:-}
REDIS_PASSWORD=${REDIS_PASSWORD:-}
LOG_LEVEL=${LOG_LEVEL:-info}
LOG_FORMAT=${LOG_FORMAT:-json}
EOF

# Execute the main application
exec ./muchtodo "$@"
