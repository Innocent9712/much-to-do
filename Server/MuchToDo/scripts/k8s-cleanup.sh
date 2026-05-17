#!/bin/bash
set -e

echo "Deleting Kind cluster..."
kind delete cluster --name muchtodo
echo "✅ Cleanup complete!"