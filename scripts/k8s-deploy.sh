#!/bin/bash

echo "Creating namespace..."
kubectl apply -f kubernetes/namespace.yaml

echo "Deploying MongoDB..."
kubectl apply -f kubernetes/mongodb/

echo "Deploying Backend..."
kubectl apply -f kubernetes/backend/

echo "Deploying Ingress..."
kubectl apply -f kubernetes/ingress.yaml

echo "Deployment complete!"