#!/bin/bash
set -e

echo " Cleaning up MuchToDo Kubernetes resources..."

kubectl delete -f kubernetes/ingress.yaml --ignore-not-found
kubectl delete -f kubernetes/backend/ --ignore-not-found
kubectl delete -f kubernetes/mongodb/ --ignore-not-found
kubectl delete -f kubernetes/namespace.yaml --ignore-not-found

echo ""
echo " All Kubernetes resources deleted."
echo ""
read -p " Also delete the Kind cluster? (y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  kind delete cluster --name muchtodo
  echo " Kind cluster deleted."
fi