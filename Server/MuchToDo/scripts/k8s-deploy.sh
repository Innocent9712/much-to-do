#!/bin/bash
set -e

echo "Loading Docker image into Kind..."
kind load docker-image muchtodo-app:latest --name muchtodo-cluster

echo "Deploying MuchTodo to Kubernetes..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

echo "Deployment status:"
kubectl get pods -n muchtodo
kubectl get services -n muchtodo
kubectl get ingress -n muchtodo