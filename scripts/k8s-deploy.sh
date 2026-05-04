#!/bin/bash
set -e

echo "  Deploying MuchToDo to Kubernetes (Kind)..."

# 1. Create Kind cluster if it doesn't exist
if ! kind get clusters | grep -q "muchtodo"; then
  echo " Creating Kind cluster..."
  kind create cluster --name muchtodo
else
  echo " Kind cluster 'muchtodo' already exists."
fi

# Switch kubectl context to the Kind cluster
kubectl cluster-info --context kind-muchtodo

# 2. Build Docker image
echo " Building Docker image..."
docker build -t muchtodo-backend:latest .

# 3. Load image into Kind cluster
echo "Loading image into Kind cluster..."
kind load docker-image muchtodo-backend:latest --name muchtodo

# 4. Apply manifests in order
echo "Applying Kubernetes manifests..."
kubectl apply -f kubernetes/namespace.yaml

# MongoDB
kubectl apply -f kubernetes/mongodb/mongodb-secret.yaml
kubectl apply -f kubernetes/mongodb/mongodb-configmap.yaml
kubectl apply -f kubernetes/mongodb/mongodb-pvc.yaml
kubectl apply -f kubernetes/mongodb/mongodb-deployment.yaml
kubectl apply -f kubernetes/mongodb/mongodb-service.yaml

# Wait for MongoDB to be ready before deploying backend
echo "Waiting for MongoDB to be ready..."
kubectl rollout status deployment/mongodb-deployment -n muchtodo --timeout=120s

# Backend
kubectl apply -f kubernetes/backend/backend-secret.yaml
kubectl apply -f kubernetes/backend/backend-configmap.yaml
kubectl apply -f kubernetes/backend/backend-deployment.yaml
kubectl apply -f kubernetes/backend/backend-service.yaml

# Ingress
kubectl apply -f kubernetes/ingress.yaml

# Wait for backend to be ready
echo " Waiting for backend to be ready..."
kubectl rollout status deployment/backend-deployment -n muchtodo --timeout=120s

echo ""
echo "Deployment complete!"
echo ""
echo "Pods:"
kubectl get pods -n muchtodo

echo ""
echo " Services:"
kubectl get services -n muchtodo

echo ""
echo " Ingress:"
kubectl get ingress -n muchtodo

echo ""
echo "Access via NodePort:   http://localhost:30080/health"
echo "   Or port-forward:       kubectl port-forward svc/backend-service 8080:8080 -n muchtodo"