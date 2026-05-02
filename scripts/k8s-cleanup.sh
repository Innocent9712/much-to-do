#!/bin/bash
echo "Deleting Kind cluster..."
kind delete cluster --name muchtodo
echo "Cleanup complete!"
