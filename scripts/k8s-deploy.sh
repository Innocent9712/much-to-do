#!/bin/bash
set -e

echo "════════════════════════════════════════"
echo "  🚀 Deploying MuchToDo to Kubernetes"
echo "════════════════════════════════════════"
echo ""

CLUSTER_NAME="muchtodo-cluster"

# Step 1: Create or use existing Kind cluster
echo "📦 Step 1: Checking Kind cluster..."
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "   ✅ Cluster already exists"
else
    echo "   Creating new cluster..."
    cat <<EEOF | kind create cluster --name ${CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
EEOF
    echo "   ✅ Cluster created"
fi

# Step 2: Load Docker image
echo ""
echo "📥 Step 2: Loading Docker image into cluster..."
kind load docker-image much-to-do:latest --name ${CLUSTER_NAME}
echo "   ✅ Image loaded"

# Step 3: Create namespace
echo ""
echo "🎯 Step 3: Creating namespace..."
kubectl apply -f kubernetes/namespace.yaml
echo "   ✅ Namespace created"

# Step 4: Deploy MongoDB
echo ""
echo "💾 Step 4: Deploying MongoDB..."
kubectl apply -f kubernetes/mongodb/mongodb-secret.yaml
kubectl apply -f kubernetes/mongodb/mongodb-configmap.yaml
kubectl apply -f kubernetes/mongodb/mongodb-pvc.yaml
kubectl apply -f kubernetes/mongodb/mongodb-deployment.yaml
kubectl apply -f kubernetes/mongodb/mongodb-service.yaml
echo "   ✅ MongoDB deployed"

# Step 5: Wait for MongoDB
echo ""
echo "⏳ Step 5: Waiting for MongoDB to be ready..."
kubectl wait --namespace muchtodo \
  --for=condition=ready pod \
  --selector=app=mongodb \
  --timeout=120s
echo "   ✅ MongoDB is ready"

# Step 6: Deploy Backend
echo ""
echo "🚀 Step 6: Deploying Backend application..."
kubectl apply -f kubernetes/backend/backend-secret.yaml
kubectl apply -f kubernetes/backend/backend-configmap.yaml
kubectl apply -f kubernetes/backend/backend-deployment.yaml
kubectl apply -f kubernetes/backend/backend-service.yaml
echo "   ✅ Backend deployed"

# Step 7: Wait for Backend
echo ""
echo "⏳ Step 7: Waiting for Backend to be ready..."
kubectl wait --namespace muchtodo \
  --for=condition=ready pod \
  --selector=app=backend \
  --timeout=120s
echo "   ✅ Backend is ready"

# Show final status
echo ""
echo "════════════════════════════════════════"
echo "  ✅ DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════"
echo ""
echo "📍 Access your app: http://localhost:30080/health"
echo ""
echo "📊 Current Status:"
kubectl get all -n muchtodo
echo ""
echo "💡 Useful commands:"
echo "   - View pods: kubectl get pods -n muchtodo"
echo "   - View logs: kubectl logs -f deployment/backend -n muchtodo"
echo "   - Delete all: kubectl delete namespace muchtodo"
