#!/bin/bash
set -e

kubectl delete -f kubernetes/ingress.yaml --ignore-not-found=true
kubectl delete -f kubernetes/backend/ --ignore-not-found=true
kubectl delete -f kubernetes/mongodb/ --ignore-not-found=true
kubectl delete -f kubernetes/namespace.yaml --ignore-not-found=true
