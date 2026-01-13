#!/bin/bash

# ============================================
# Docker Compose Run Script for MuchToDo
# ============================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
PROFILE="${PROFILE:-}"
ACTION="${1:-up}"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  MuchToDo Docker Compose Runner${NC}"
echo -e "${GREEN}============================================${NC}"

# Change to project directory
cd "$PROJECT_DIR"

# Function to display help
show_help() {
    echo -e "${YELLOW}Usage:${NC} $0 [action] [options]"
    echo ""
    echo -e "${YELLOW}Actions:${NC}"
    echo "  up        - Start all services (default)"
    echo "  down      - Stop and remove all services"
    echo "  restart   - Restart all services"
    echo "  logs      - View logs"
    echo "  status    - Show service status"
    echo "  dev       - Start with development tools (mongo-express, redis-commander)"
    echo "  build     - Build and start services"
    echo "  clean     - Stop services and remove volumes"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 up         # Start production services"
    echo "  $0 dev        # Start with dev tools"
    echo "  $0 logs       # View logs"
    echo "  $0 down       # Stop services"
    echo "  $0 clean      # Stop and remove all data"
}

# Generate MongoDB keyfile if it doesn't exist
generate_keyfile() {
    if [ ! -f "$PROJECT_DIR/mongodb.key" ]; then
        echo -e "${YELLOW}Generating MongoDB keyfile...${NC}"
        openssl rand -base64 756 > "$PROJECT_DIR/mongodb.key"
        chmod 400 "$PROJECT_DIR/mongodb.key"
        echo -e "${GREEN}MongoDB keyfile generated.${NC}"
    fi
}

# Main logic
case "$ACTION" in
    up)
        echo -e "${YELLOW}Starting MuchToDo services...${NC}"
        generate_keyfile
        docker compose -f "$COMPOSE_FILE" up -d
        echo ""
        echo -e "${GREEN}Services started successfully!${NC}"
        echo -e "${BLUE}API:${NC}              http://localhost:8080"
        echo -e "${BLUE}Health Check:${NC}     http://localhost:8080/health"
        echo -e "${BLUE}Swagger Docs:${NC}     http://localhost:8080/swagger/index.html"
        ;;
    down)
        echo -e "${YELLOW}Stopping MuchToDo services...${NC}"
        docker compose -f "$COMPOSE_FILE" down
        echo -e "${GREEN}Services stopped.${NC}"
        ;;
    restart)
        echo -e "${YELLOW}Restarting MuchToDo services...${NC}"
        docker compose -f "$COMPOSE_FILE" restart
        echo -e "${GREEN}Services restarted.${NC}"
        ;;
    logs)
        echo -e "${YELLOW}Showing logs (Ctrl+C to exit)...${NC}"
        docker compose -f "$COMPOSE_FILE" logs -f
        ;;
    status)
        echo -e "${YELLOW}Service Status:${NC}"
        docker compose -f "$COMPOSE_FILE" ps
        ;;
    dev)
        echo -e "${YELLOW}Starting MuchToDo with development tools...${NC}"
        generate_keyfile
        docker compose -f "$COMPOSE_FILE" --profile dev up -d
        echo ""
        echo -e "${GREEN}Services started successfully!${NC}"
        echo -e "${BLUE}API:${NC}              http://localhost:8080"
        echo -e "${BLUE}Health Check:${NC}     http://localhost:8080/health"
        echo -e "${BLUE}Swagger Docs:${NC}     http://localhost:8080/swagger/index.html"
        echo -e "${BLUE}Mongo Express:${NC}    http://localhost:8081 (admin/admin123)"
        echo -e "${BLUE}Redis Commander:${NC}  http://localhost:8082"
        ;;
    build)
        echo -e "${YELLOW}Building and starting MuchToDo services...${NC}"
        generate_keyfile
        docker compose -f "$COMPOSE_FILE" up -d --build
        echo -e "${GREEN}Services built and started.${NC}"
        ;;
    clean)
        echo -e "${RED}WARNING: This will remove all data!${NC}"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Stopping services and removing volumes...${NC}"
            docker compose -f "$COMPOSE_FILE" --profile dev down -v
            echo -e "${GREEN}Cleanup complete.${NC}"
        else
            echo -e "${YELLOW}Cleanup cancelled.${NC}"
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown action: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac
