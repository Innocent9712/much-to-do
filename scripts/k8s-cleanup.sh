#!/bin/bash

echo "Deleting resources..."
kubectl delete -f kubernetes/

echo "Cleanup complete."