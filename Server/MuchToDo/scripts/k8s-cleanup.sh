#!/bin/bash
set -e

echo "Deleting MuchTodo Kubernetes resources..."
kubectl delete namespace muchtodo --ignore-not-found=true

echo "Cleanup completed."