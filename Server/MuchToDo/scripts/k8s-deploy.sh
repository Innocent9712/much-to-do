#!/bin/bash

# ============================================
# Kubernetes Deployment Script for MuchToDo
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
IMAGE_NAME="${IMAGE_NAME:-muchtodo-api}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
NAMESPACE="${NAMESPACE:-muchtodo}"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  MuchToDo Kubernetes Deployment${NC}"
echo -e "${GREEN}============================================${NC}"

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed${NC}"
        exit 1
    fi
    
    # Check kind
    if ! command -v kind &> /dev/null; then
        echo -e "${RED}Error: kind is not installed${NC}"
        echo "Install with: brew install kind (macOS) or see https://kind.sigs.k8s.io/docs/user/quick-start/"
        exit 1
    fi
    
    # Check docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: docker is not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All prerequisites met.${NC}"
}

# Function to create Kind cluster
create_cluster() {
    echo -e "${YELLOW}Checking for existing Kind cluster...${NC}"
    
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists.${NC}"
    else
        echo -e "${YELLOW}Creating Kind cluster '${CLUSTER_NAME}'...${NC}"
        
        # Create cluster with ingress support
        cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
        
        echo -e "${GREEN}Cluster created successfully.${NC}"
    fi
    
    # Set kubectl context
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
}

# Function to install NGINX Ingress Controller
install_ingress() {
    echo -e "${YELLOW}Installing NGINX Ingress Controller...${NC}"
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    echo -e "${YELLOW}Waiting for Ingress Controller to be ready...${NC}"
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s
    
    echo -e "${GREEN}Ingress Controller installed.${NC}"
}

# Function to build and load Docker image
build_and_load_image() {
    echo -e "${YELLOW}Building Docker image...${NC}"
    
    cd "$PROJECT_DIR"
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    
    echo -e "${YELLOW}Loading image into Kind cluster...${NC}"
    kind load docker-image "${IMAGE_NAME}:${IMAGE_TAG}" --name "${CLUSTER_NAME}"
    
    echo -e "${GREEN}Image loaded into cluster.${NC}"
}

# Function to deploy Kubernetes resources
deploy_resources() {
    echo -e "${YELLOW}Deploying Kubernetes resources...${NC}"
    
    # Create namespace
    echo -e "${BLUE}Creating namespace...${NC}"
    kubectl apply -f "$K8S_DIR/namespace.yaml"
    
    # Deploy MongoDB
    echo -e "${BLUE}Deploying MongoDB...${NC}"
    kubectl apply -f "$K8S_DIR/mongodb/mongodb-secret.yaml"
    kubectl apply -f "$K8S_DIR/mongodb/mongodb-configmap.yaml"
    kubectl apply -f "$K8S_DIR/mongodb/mongodb-pvc.yaml"
    kubectl apply -f "$K8S_DIR/mongodb/mongodb-deployment.yaml"
    kubectl apply -f "$K8S_DIR/mongodb/mongodb-service.yaml"
    
    # Wait for MongoDB to be ready
    echo -e "${YELLOW}Waiting for MongoDB to be ready...${NC}"
    kubectl wait --namespace "$NAMESPACE" \
        --for=condition=ready pod \
        --selector=app=mongodb \
        --timeout=120s
    
    # Deploy Backend
    echo -e "${BLUE}Deploying Backend API...${NC}"
    kubectl apply -f "$K8S_DIR/backend/backend-secret.yaml"
    kubectl apply -f "$K8S_DIR/backend/backend-configmap.yaml"
    kubectl apply -f "$K8S_DIR/backend/backend-deployment.yaml"
    kubectl apply -f "$K8S_DIR/backend/backend-service.yaml"
    
    # Wait for Backend to be ready
    echo -e "${YELLOW}Waiting for Backend to be ready...${NC}"
    kubectl wait --namespace "$NAMESPACE" \
        --for=condition=ready pod \
        --selector=app=backend \
        --timeout=120s
    
    # Deploy Ingress
    echo -e "${BLUE}Deploying Ingress...${NC}"
    kubectl apply -f "$K8S_DIR/ingress.yaml"
    
    echo -e "${GREEN}All resources deployed successfully!${NC}"
}

# Function to display status
show_status() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Deployment Status${NC}"
    echo -e "${GREEN}============================================${NC}"
    
    echo -e "${YELLOW}Pods:${NC}"
    kubectl get pods -n "$NAMESPACE"
    
    echo ""
    echo -e "${YELLOW}Services:${NC}"
    kubectl get services -n "$NAMESPACE"
    
    echo ""
    echo -e "${YELLOW}Ingress:${NC}"
    kubectl get ingress -n "$NAMESPACE"
    
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Access Information${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo -e "${BLUE}API Endpoint:${NC}     http://localhost/api"
    echo -e "${BLUE}Health Check:${NC}     http://localhost/health"
    echo -e "${BLUE}With Host Header:${NC} curl -H 'Host: muchtodo.local' http://localhost/"
    echo ""
    echo -e "${YELLOW}Tip:${NC} Add '127.0.0.1 muchtodo.local' to /etc/hosts for easier access"
}

# Main execution
main() {
    check_prerequisites
    create_cluster
    install_ingress
    build_and_load_image
    deploy_resources
    show_status
}

# Run main function
main "$@"
