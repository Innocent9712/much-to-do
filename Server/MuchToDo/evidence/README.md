# Deployment Evidence

This folder contains evidence of the MuchToDo application deployment using Docker Compose and Kubernetes.

## Evidence Files

### Docker Build and Compose
| File | Description |
|------|-------------|
| `01-docker-build.txt` | Docker multi-stage build process completion |
| `02-docker-compose-up.txt` | Docker Compose services starting up |
| `03-docker-compose-status.txt` | Docker Compose running status (all healthy) |
| `04-docker-api-response.txt` | API responding via Docker Compose |

### Kubernetes Deployment (Kind)
| File | Description |
|------|-------------|
| `05-kind-cluster-create.txt` | Kind cluster creation output |
| `05-k8s-cluster-info.txt` | Kubernetes cluster info |
| `06-kind-load-image.txt` | Loading Docker image into Kind |
| `07-k8s-ingress-install.txt` | NGINX Ingress Controller installation |
| `08-k8s-deploy-all.txt` | All Kubernetes resources deployment |
| `09-k8s-wait-pods.txt` | Waiting for pods to be ready |
| `10-k8s-resources-status.txt` | All Kubernetes resources status |
| `11-k8s-app-test.txt` | Application test via Ingress |
| `12-k8s-port-forward-test.txt` | Port-forward test output |
| `13-k8s-nodeport-test.txt` | NodePort service test |
| `14-k8s-final-status.txt` | Final Kubernetes status with all resources |

## Summary

### Docker Compose Results
- ✅ Backend API built successfully with multi-stage Dockerfile
- ✅ MongoDB, Redis, and Backend all running and healthy
- ✅ API responding at http://localhost:8080
- ✅ Health check returning: `{"cache":"ok","database":"ok"}`

### Kubernetes Results
- ✅ Kind cluster created with ingress support
- ✅ NGINX Ingress Controller installed
- ✅ Namespace `muchtodo` created
- ✅ MongoDB deployment with 1 replica running
- ✅ Backend deployment with 2 replicas running
- ✅ ClusterIP services for internal communication
- ✅ NodePort service exposing app on port 30080
- ✅ Ingress routing traffic to backend service
- ✅ Application accessible via:
  - Ingress: http://localhost/
  - NodePort: http://localhost:30080/
  - Host header: `curl -H "Host: muchtodo.local" http://localhost/`

## Date
Generated: January 13, 2026
