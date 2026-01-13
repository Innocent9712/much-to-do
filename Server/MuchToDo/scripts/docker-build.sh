#!/bin/bash

# ============================================
# Docker Build Script for MuchToDo API
# ============================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
IMAGE_NAME="${IMAGE_NAME:-muchtodo-api}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Building MuchToDo API Docker Image${NC}"
echo -e "${GREEN}============================================${NC}"

# Change to project directory
cd "$PROJECT_DIR"

# Print build info
echo -e "${YELLOW}Project Directory:${NC} $PROJECT_DIR"
echo -e "${YELLOW}Image Name:${NC} $IMAGE_NAME"
echo -e "${YELLOW}Image Tag:${NC} $IMAGE_TAG"
echo -e "${YELLOW}Dockerfile:${NC} $DOCKERFILE"
echo ""

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}Error: Dockerfile not found at $PROJECT_DIR/$DOCKERFILE${NC}"
    exit 1
fi

# Build the Docker image
echo -e "${YELLOW}Building Docker image...${NC}"
docker build \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    -f "$DOCKERFILE" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VERSION="${IMAGE_TAG}" \
    .

# Verify the build
if [ $? -eq 0 ]; then
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Build Successful!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo -e "${YELLOW}Image:${NC} ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    echo -e "${YELLOW}Image Details:${NC}"
    docker images "${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    echo -e "${GREEN}To run the container:${NC}"
    echo "  docker run -p 8080:8080 ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    echo -e "${GREEN}Or use docker-compose:${NC}"
    echo "  ./scripts/docker-run.sh"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
