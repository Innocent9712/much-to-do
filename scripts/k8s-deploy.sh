#!/bin/bash
set -e

echo "Creating Kind cluster..."
kind create cluster --name muchtodo --config kind-config.yaml

echo "Loading image into Kind..."
kind load docker-image muchtodo-backend:latest --name muchtodo

echo "Applying manifests..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

echo "Waiting for pods to be ready..."
kubectl rollout status deployment/mongodb -n muchtodo
kubectl rollout status deployment/backend -n muchtodo

echo "Done! Run: kubectl get pods -n muchtodo"
