#!/bin/bash
set -e

echo "=== Deleting existing Kind Cluster if it exists ==="
kind delete cluster --name muchtodo 2>/dev/null || true

echo "=== Creating Kind Cluster ==="
kind create cluster --name muchtodo --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        apiVersion: kubeadm.k8s.io/v1beta3
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

echo "=== Loading Docker image into Kind ==="
kind load docker-image muchtodo-backend:latest --name muchtodo

echo "=== Installing NGINX Ingress Controller ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "=== Waiting for Ingress Controller (this may take a few minutes) ==="
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=600s

echo "=== Deploying application ==="
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

echo "=== Waiting for MongoDB ==="
kubectl wait --namespace muchtodo \
  --for=condition=ready pod \
  --selector=app=mongodb \
  --timeout=600s

echo "=== Waiting for Backend ==="
kubectl wait --namespace muchtodo \
  --for=condition=ready pod \
  --selector=app=backend \
  --timeout=300s

echo ""
echo "✅ Deployment Complete!"
echo "Add to /etc/hosts: 127.0.0.1 muchtodo.local"
echo "Access at http://muchtodo.local"