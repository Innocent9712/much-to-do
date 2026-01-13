# MuchToDo API - Container Assessment

A containerized Golang backend application with MongoDB database, designed for local development with Docker Compose and Kubernetes deployment using Kind.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Phase 1: Docker Setup](#phase-1-docker-setup)
  - [Building the Docker Image](#building-the-docker-image)
  - [Running with Docker Compose](#running-with-docker-compose)
- [Phase 2: Kubernetes Deployment](#phase-2-kubernetes-deployment)
  - [Deploying to Kind Cluster](#deploying-to-kind-cluster)
  - [Accessing the Application](#accessing-the-application)
  - [Cleaning Up](#cleaning-up)
- [Configuration](#configuration)
- [API Endpoints](#api-endpoints)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Make sure you have the following tools installed:

- **Docker** (v20.10+): [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (v2.0+): Included with Docker Desktop
- **kubectl** (v1.28+): [Install kubectl](https://kubernetes.io/docs/tasks/tools/)
- **Kind** (v0.20+): [Install Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

Verify installations:

```bash
docker --version
docker compose version
kubectl version --client
kind version
```

## Project Structure

```
MuchToDo/
├── cmd/api/main.go              # Application entry point
├── internal/                    # Application source code
├── Dockerfile                   # Multi-stage Docker build
├── docker-compose.yml           # Local development setup
├── .dockerignore                # Docker build exclusions
├── kubernetes/                  # Kubernetes manifests
│   ├── namespace.yaml
│   ├── mongodb/
│   │   ├── mongodb-secret.yaml
│   │   ├── mongodb-configmap.yaml
│   │   ├── mongodb-pvc.yaml
│   │   ├── mongodb-deployment.yaml
│   │   └── mongodb-service.yaml
│   ├── backend/
│   │   ├── backend-secret.yaml
│   │   ├── backend-configmap.yaml
│   │   ├── backend-deployment.yaml
│   │   └── backend-service.yaml
│   └── ingress.yaml
├── scripts/
│   ├── docker-build.sh          # Build Docker image
│   ├── docker-run.sh            # Run with Docker Compose
│   ├── k8s-deploy.sh            # Deploy to Kubernetes
│   └── k8s-cleanup.sh           # Clean up Kubernetes resources
└── README.md
```

## Phase 1: Docker Setup

### Building the Docker Image

Build the optimized Docker image using the multi-stage Dockerfile:

```bash
# Using the build script
chmod +x scripts/docker-build.sh
./scripts/docker-build.sh

# Or manually
docker build -t muchtodo-api:latest .
```

The Dockerfile features:
- Multi-stage build for smaller image size
- Alpine base image for security and minimal footprint
- Non-root user for enhanced security
- Built-in health check
- Optimized layer caching

### Running with Docker Compose

#### Quick Start

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Start services (MongoDB, Redis, Backend)
./scripts/docker-run.sh up

# Or start with development tools (Mongo Express, Redis Commander)
./scripts/docker-run.sh dev
```

#### Available Commands

```bash
./scripts/docker-run.sh up        # Start production services
./scripts/docker-run.sh dev       # Start with dev tools
./scripts/docker-run.sh down      # Stop services
./scripts/docker-run.sh logs      # View logs
./scripts/docker-run.sh status    # Show service status
./scripts/docker-run.sh build     # Rebuild and start
./scripts/docker-run.sh clean     # Stop and remove all data
```

#### Service Endpoints (Docker Compose)

| Service | URL | Description |
|---------|-----|-------------|
| API | http://localhost:8080 | Backend API |
| Health Check | http://localhost:8080/health | Health endpoint |
| Swagger Docs | http://localhost:8080/swagger/index.html | API documentation |
| Mongo Express | http://localhost:8081 | MongoDB UI (dev profile) |
| Redis Commander | http://localhost:8082 | Redis UI (dev profile) |

#### Environment Variables

Create a `.env` file to customize the configuration:

```env
# Application
PORT=8080
JWT_SECRET_KEY=your-super-secret-key
JWT_EXPIRATION_HOURS=72

# Database
MONGO_USER=root
MONGO_PASSWORD=example
DB_NAME=much_todo_db

# Cache
ENABLE_CACHE=true
REDIS_PASSWORD=

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# Dev Tools
ME_CONFIG_BASICAUTH_USERNAME=admin
ME_CONFIG_BASICAUTH_PASSWORD=admin123
```

## Phase 2: Kubernetes Deployment

### Deploying to Kind Cluster

Deploy the entire stack to a local Kubernetes cluster:

```bash
# Make scripts executable (if not already done)
chmod +x scripts/*.sh

# Deploy everything (creates cluster, installs ingress, deploys app)
./scripts/k8s-deploy.sh
```

This script automatically:
1. Checks prerequisites (kubectl, kind, docker)
2. Creates a Kind cluster with ingress support
3. Installs NGINX Ingress Controller
4. Builds and loads the Docker image
5. Deploys all Kubernetes resources
6. Shows deployment status and access information

### Manual Deployment Steps

If you prefer manual deployment:

```bash
# 1. Create Kind cluster
kind create cluster --name muchtodo-cluster

# 2. Build and load image
docker build -t muchtodo-api:latest .
kind load docker-image muchtodo-api:latest --name muchtodo-cluster

# 3. Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# 4. Deploy resources
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

# 5. Check status
kubectl get all -n muchtodo
```

### Accessing the Application

After deployment, access the application:

```bash
# Via localhost (port 80 mapped to ingress)
curl http://localhost/health
curl http://localhost/api

# Via host header
curl -H "Host: muchtodo.local" http://localhost/

# Add to /etc/hosts for easier access
echo "127.0.0.1 muchtodo.local" | sudo tee -a /etc/hosts
curl http://muchtodo.local/health
```

### Useful kubectl Commands

```bash
# View all resources
kubectl get all -n muchtodo

# View pods
kubectl get pods -n muchtodo

# View logs
kubectl logs -f deployment/backend -n muchtodo

# Describe pod (for debugging)
kubectl describe pod -l app=backend -n muchtodo

# Execute into pod
kubectl exec -it deployment/backend -n muchtodo -- /bin/sh

# Port forward (alternative access method)
kubectl port-forward svc/backend-service 8080:8080 -n muchtodo
```

### Cleaning Up

```bash
# Remove app resources only
./scripts/k8s-cleanup.sh resources

# Remove the namespace
./scripts/k8s-cleanup.sh namespace

# Delete the entire cluster
./scripts/k8s-cleanup.sh cluster

# Full cleanup (cluster + docker images)
./scripts/k8s-cleanup.sh all
```

## Configuration

### Kubernetes Secrets

**Important**: The provided secrets use base64-encoded example values. For production:

1. Use a secrets management solution (Sealed Secrets, External Secrets, HashiCorp Vault)
2. Never commit real credentials to version control
3. Rotate secrets regularly

To generate new base64 values:

```bash
echo -n 'your-secret-value' | base64
```

### Resource Limits

The Kubernetes deployments include resource limits:

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| MongoDB | 250m | 500m | 256Mi | 512Mi |
| Backend | 100m | 500m | 64Mi | 256Mi |

Adjust these values in the deployment manifests based on your requirements.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Welcome message |
| GET | `/ping` | Simple ping/pong |
| GET | `/health` | Health check |
| GET | `/swagger/*` | API documentation |
| POST | `/api/auth/register` | User registration |
| POST | `/api/auth/login` | User login |
| GET | `/api/todos` | List todos |
| POST | `/api/todos` | Create todo |
| GET | `/api/todos/:id` | Get todo |
| PUT | `/api/todos/:id` | Update todo |
| DELETE | `/api/todos/:id` | Delete todo |

## Troubleshooting

### Docker Compose Issues

**MongoDB fails to start:**
```bash
# Generate the keyfile if missing
openssl rand -base64 756 > mongodb.key
chmod 400 mongodb.key
```

**Container keeps restarting:**
```bash
# Check logs
docker compose logs -f backend
docker compose logs -f mongodb
```

### Kubernetes Issues

**Pods not starting:**
```bash
# Check pod status
kubectl describe pod -l app=backend -n muchtodo

# Check events
kubectl get events -n muchtodo --sort-by='.lastTimestamp'
```

**Image not found:**
```bash
# Ensure image is loaded into Kind
kind load docker-image muchtodo-api:latest --name muchtodo-cluster

# Verify
docker exec -it muchtodo-cluster-control-plane crictl images | grep muchtodo
```

**Ingress not working:**
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl describe ingress muchtodo-ingress -n muchtodo
```

**Database connection issues:**
```bash
# Check MongoDB is running
kubectl get pods -l app=mongodb -n muchtodo

# Check MongoDB logs
kubectl logs -l app=mongodb -n muchtodo

# Test connectivity from backend pod
kubectl exec -it deployment/backend -n muchtodo -- wget -qO- mongodb-service:27017
```

### Common Fixes

1. **Restart deployments:**
   ```bash
   kubectl rollout restart deployment/backend -n muchtodo
   ```

2. **Delete and recreate:**
   ```bash
   kubectl delete -f kubernetes/backend/ && kubectl apply -f kubernetes/backend/
   ```

3. **Check resource availability:**
   ```bash
   kubectl top nodes
   kubectl top pods -n muchtodo
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Apache 2.0 License - See LICENSE file for details.
