#!/bin/bash
set -e

kind load docker-image muchtodo-backend:latest --name muchtodo-cluster

kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml
