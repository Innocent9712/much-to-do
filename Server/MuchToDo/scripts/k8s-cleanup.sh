#!/bin/bash

# ============================================
# Kubernetes Cleanup Script for MuchToDo
# ============================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
K8S_DIR="$PROJECT_DIR/kubernetes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CLUSTER_NAME="${CLUSTER_NAME:-muchtodo-cluster}"
NAMESPACE="${NAMESPACE:-muchtodo}"
ACTION="${1:-resources}"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  MuchToDo Kubernetes Cleanup${NC}"
echo -e "${GREEN}============================================${NC}"

# Function to display help
show_help() {
    echo -e "${YELLOW}Usage:${NC} $0 [action]"
    echo ""
    echo -e "${YELLOW}Actions:${NC}"
    echo "  resources  - Delete all Kubernetes resources but keep cluster (default)"
    echo "  namespace  - Delete the namespace (removes all resources in it)"
    echo "  cluster    - Delete the entire Kind cluster"
    echo "  all        - Delete cluster and clean up everything"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 resources   # Remove app resources"
    echo "  $0 namespace   # Remove namespace"
    echo "  $0 cluster     # Delete Kind cluster"
    echo "  $0 all         # Full cleanup"
}

# Function to delete resources
delete_resources() {
    echo -e "${YELLOW}Deleting Kubernetes resources...${NC}"
    
    # Check if namespace exists
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        # Delete Ingress
        echo -e "${BLUE}Deleting Ingress...${NC}"
        kubectl delete -f "$K8S_DIR/ingress.yaml" --ignore-not-found=true
        
        # Delete Backend resources
        echo -e "${BLUE}Deleting Backend resources...${NC}"
        kubectl delete -f "$K8S_DIR/backend/backend-service.yaml" --ignore-not-found=true
        kubectl delete -f "$K8S_DIR/backend/backend-deployment.yaml" --ignore-not-found=true
        kubectl delete -f "$K8S_DIR/backend/backend-configmap.yaml" --ignore-not-found=true
        kubectl delete -f "$K8S_DIR/backend/backend-secret.yaml" --ignore-not-found=true
        
        # Delete MongoDB resources
        echo -e "${BLUE}Deleting MongoDB resources...${NC}"
        kubectl delete -f "$K8S_DIR/mongodb/mongodb-service.yaml" --ignore-not-found=true
        kubectl delete -f "$K8S_DIR/mongodb/mongodb-deployment.yaml" --ignore-not-found=true
        kubectl delete -f "$K8S_DIR/mongodb/mongodb-pvc.yaml" --ignore-not-found=true
        kubectl delete -f "$K8S_DIR/mongodb/mongodb-configmap.yaml" --ignore-not-found=true
        kubectl delete -f "$K8S_DIR/mongodb/mongodb-secret.yaml" --ignore-not-found=true
        
        echo -e "${GREEN}Resources deleted successfully.${NC}"
    else
        echo -e "${YELLOW}Namespace '$NAMESPACE' does not exist. Nothing to delete.${NC}"
    fi
}

# Function to delete namespace
delete_namespace() {
    echo -e "${YELLOW}Deleting namespace '$NAMESPACE'...${NC}"
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        kubectl delete namespace "$NAMESPACE"
        echo -e "${GREEN}Namespace deleted successfully.${NC}"
    else
        echo -e "${YELLOW}Namespace '$NAMESPACE' does not exist.${NC}"
    fi
}

# Function to delete Kind cluster
delete_cluster() {
    echo -e "${YELLOW}Deleting Kind cluster '$CLUSTER_NAME'...${NC}"
    
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        kind delete cluster --name "$CLUSTER_NAME"
        echo -e "${GREEN}Cluster deleted successfully.${NC}"
    else
        echo -e "${YELLOW}Cluster '$CLUSTER_NAME' does not exist.${NC}"
    fi
}

# Main logic
case "$ACTION" in
    resources)
        delete_resources
        ;;
    namespace)
        delete_namespace
        ;;
    cluster)
        echo -e "${RED}WARNING: This will delete the entire Kind cluster!${NC}"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_cluster
        else
            echo -e "${YELLOW}Cluster deletion cancelled.${NC}"
        fi
        ;;
    all)
        echo -e "${RED}WARNING: This will delete the entire Kind cluster and all resources!${NC}"
        read -p "Are you sure? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            delete_cluster
            # Clean up any remaining docker images
            echo -e "${YELLOW}Cleaning up Docker images...${NC}"
            docker rmi muchtodo-api:latest 2>/dev/null || true
            echo -e "${GREEN}Full cleanup complete.${NC}"
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

echo ""
echo -e "${GREEN}Cleanup complete!${NC}"
