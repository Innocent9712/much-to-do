# MuchToDo — Container & Kubernetes Deployment Guide

A containerized deployment of the MuchToDo Golang backend API using Docker and Kubernetes (Kind).

---

## Table of Contents

- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Environment Configuration](#environment-configuration)
- [Phase 1: Docker Setup](#phase-1-docker-setup)
- [Phase 2: Kubernetes Deployment](#phase-2-kubernetes-deployment)
- [Accessing the Application](#accessing-the-application)
- [Verifying the Deployment](#verifying-the-deployment)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

---

## Project Structure

```
Server/MuchToDo/
├── cmd/api/main.go
├── internal/
├── Dockerfile
├── docker-compose.yml
├── .env
├── .dockerignore
├── kind-config.yaml
├── kubernetes/
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
└── scripts/
    ├── docker-build.sh
    ├── docker-run.sh
    ├── k8s-deploy.sh
    └── k8s-cleanup.sh
```

---

## Prerequisites

Ensure the following tools are installed and running before proceeding.

### 1. Docker
```bash
docker --version
docker ps  # verify Docker daemon is running
```
Install from: https://docs.docker.com/get-docker/

### 2. Kind (Kubernetes IN Docker)
```bash
# Linux
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# macOS
brew install kind

# Verify
kind --version
```

### 3. kubectl
```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/kubectl

# macOS
brew install kubectl

# Verify
kubectl version --client
```

### System Requirements
| Resource | Minimum |
|---|---|
| CPU | 4 cores |
| RAM | 8 GB |
| Disk | 20 GB free |

---

## Environment Configuration

The application uses a `.env` file for configuration via Viper. There are two versions of this file depending on the environment.

### For Docker Compose (local development)

Create `.env` in the project root:

```env
MONGO_URI=mongodb://root:example@mongodb:27017/much_todo_db?authSource=admin&replicaSet=rs0&directConnection=true
PORT=8080
DB_NAME=much_todo_db
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=example
MONGO_HOST=mongodb
MONGO_PORT=27017
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_ADDR=redis:6379
REDIS_PASSWORD=
APP_PORT=8080
ME_CONFIG_BASICAUTH_USERNAME=admin
ME_CONFIG_BASICAUTH_PASSWORD=admin123
JWT_SECRET_KEY=your-secret-key-here
JWT_EXPIRATION_HOURS=72
ENABLE_CACHE=false
LOG_LEVEL=info
LOG_FORMAT=json
```

### For Kubernetes (Kind)

Before building the image for Kubernetes, update `MONGO_URI` to use the Kubernetes service name:

```env
MONGO_URI=mongodb://root:example@mongodb-service:27017/much_todo_db?authSource=admin
PORT=8080
DB_NAME=much_todo_db
JWT_SECRET_KEY=your-secret-key-here
JWT_EXPIRATION_HOURS=72
ENABLE_CACHE=false
REDIS_ADDR=redis:6379
REDIS_PASSWORD=
LOG_LEVEL=info
LOG_FORMAT=json
```

> **Important:** The hostname difference — Docker Compose uses `mongodb` (container name), Kubernetes uses `mongodb-service` (service name).

---

## Phase 1: Docker Setup

### Running with Docker Compose

Docker Compose runs the full stack locally including MongoDB, Redis, Mongo Express, and Redis Commander.

#### Step 1: Make scripts executable
```bash
chmod +x scripts/*.sh
```

#### Step 2: Build the Docker image
```bash
./scripts/docker-build.sh
# OR manually:
docker build -t muchtodo-backend:latest .
```

#### Step 3: Start all services
```bash
./scripts/docker-run.sh
# OR manually:
docker-compose down --remove-orphans
docker network rm muchtodo_default 2>/dev/null || true
docker-compose up --build -d
```

#### Step 4: Verify services are running
```bash
docker-compose ps
```

Expected output:
```
Name                  Command               State           Ports
muchtodo-backend      ./muchtodo           Up      0.0.0.0:8080->8080/tcp
mongodb               docker-entrypoint.sh Up      0.0.0.0:27017->27017/tcp
mongo-express         tini -- /docker-ent  Up      0.0.0.0:8081->8081/tcp
redis                 docker-entrypoint.sh Up      0.0.0.0:6379->6379/tcp
redis-commander       /usr/bin/dumb-init   Up      0.0.0.0:8082->8081/tcp
```

#### Available Services (Docker Compose)

| Service | URL | Description |
|---|---|---|
| Backend API | http://localhost:8080 | Main application |
| Health Check | http://localhost:8080/health | API health status |
| Mongo Express | http://localhost:8081 | MongoDB UI (admin/admin123) |
| Redis Commander | http://localhost:8082 | Redis UI |

#### Viewing Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f mongodb
```

#### Stopping Docker Compose
```bash
docker-compose down        # stop containers
docker-compose down -v     # stop containers and delete volumes
```

---

## Phase 2: Kubernetes Deployment

### Deploying to Kind (Local Kubernetes)

#### Step 1: Ensure port 80 is free
```bash
sudo lsof -i :80

# If something is using port 80, stop it:
sudo systemctl stop nginx    # if nginx
sudo systemctl stop apache2  # if apache
```

#### Step 2: Update `.env` for Kubernetes
```bash
# Save Docker Compose version
cp .env .env.docker

# Create Kubernetes version
cat > .env << 'EOF'
MONGO_URI=mongodb://root:example@mongodb-service:27017/much_todo_db?authSource=admin
PORT=8080
DB_NAME=much_todo_db
JWT_SECRET_KEY=your-secret-key-here
JWT_EXPIRATION_HOURS=72
ENABLE_CACHE=false
REDIS_ADDR=redis:6379
REDIS_PASSWORD=
LOG_LEVEL=info
LOG_FORMAT=json
EOF
```

#### Step 3: Build the Docker image
```bash
docker build -t muchtodo-backend:latest .
```

#### Step 4: Run the deployment script
```bash
./scripts/k8s-deploy.sh
```

This script will automatically:
- Delete any existing `muchtodo` Kind cluster
- Create a new cluster with the correct port mappings
- Load the Docker image into Kind
- Install the NGINX Ingress Controller
- Deploy all Kubernetes manifests
- Wait for all pods to be ready

#### Step 5: Restore Docker Compose `.env`
```bash
cp .env.docker .env
```

#### Step 6: Add hosts entry
```bash
echo "127.0.0.1 muchtodo.local" | sudo tee -a /etc/hosts
```

---

## Accessing the Application

### Docker Compose
| Endpoint | URL |
|---|---|
| Health Check | http://localhost:8080/health |
| API Base | http://localhost:8080 |

### Kubernetes (Kind)
| Endpoint | URL |
|---|---|
| Health Check | http://muchtodo.local/health |
| API Base | http://muchtodo.local |

---

## Verifying the Deployment

### Docker Compose
```bash
# Check all containers are running
docker-compose ps

# Test the API
curl http://localhost:8080/health
```

### Kubernetes
```bash
# Check all resources
kubectl get all -n muchtodo

# Check pods specifically
kubectl get pods -n muchtodo

# Expected output:
# NAME                       READY   STATUS    RESTARTS   AGE
# backend-xxx-xxx            1/1     Running   0          5m
# backend-xxx-yyy            1/1     Running   0          5m
# mongodb-xxx-xxx            1/1     Running   0          5m

# Check deployments
kubectl get deployments -n muchtodo

# Expected output:
# NAME      READY   UP-TO-DATE   AVAILABLE   AGE
# backend   2/2     2            2           5m
# mongodb   1/1     1            1           5m

# Check services and endpoints
kubectl get endpoints -n muchtodo

# Check ingress
kubectl get ingress -n muchtodo

# Test the API
curl http://muchtodo.local/health
```

---

## Troubleshooting

### kubectl loses cluster connection
```bash
kind export kubeconfig --name muchtodo
kubectl config use-context kind-muchtodo
kubectl get nodes  # verify connection restored
```

### Backend in CrashLoopBackOff
```bash
# Check logs from crashed container
kubectl logs -n muchtodo -l app=backend --previous

# Check what .env the container sees
kubectl exec -n muchtodo -it \
  $(kubectl get pod -n muchtodo -l app=backend -o jsonpath='{.items[0].metadata.name}') \
  -- cat /app/.env
```

### Backend cannot connect to MongoDB
```bash
# Verify endpoints exist
kubectl get endpoints -n muchtodo
# mongodb-service must show an IP, not <none>

# Verify the secret URI is correct
kubectl get secret backend-secret -n muchtodo \
  -o jsonpath='{.data.mongo-uri}' | base64 -d

# Check MongoDB logs
kubectl logs -n muchtodo -l app=mongodb | tail -30
```

### ImagePullBackOff error
```bash
# Image was not loaded into Kind — reload it
kind load docker-image muchtodo-backend:latest --name muchtodo

# Restart the deployment
kubectl rollout restart deployment/backend -n muchtodo
```

### Ingress controller not ready
```bash
# Check ingress pod status
kubectl get pods -n ingress-nginx

# Describe the pod for more details
kubectl describe pod -n ingress-nginx \
  -l app.kubernetes.io/component=controller

# Wait manually with longer timeout
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=600s
```

### Port 80 already in use
```bash
sudo lsof -i :80          # find what's using it
sudo systemctl stop nginx  # stop nginx if that's the cause
```

### Docker network error on startup
```bash
docker-compose down --remove-orphans
docker network rm muchtodo_default 2>/dev/null || true
docker-compose up --build -d
```

---

## Cleanup

### Stop Docker Compose
```bash
# Stop containers only
docker-compose down

# Stop containers and remove volumes (deletes all data)
docker-compose down -v
```

### Destroy Kubernetes Cluster
```bash
./scripts/k8s-cleanup.sh
# OR manually:
kind delete cluster --name muchtodo

# Verify it's gone
kind get clusters
```

### Remove hosts entry
```bash
sudo sed -i '/muchtodo.local/d' /etc/hosts
```

---

## Kubernetes Credentials Reference

All credentials are stored in Kubernetes Secrets as base64-encoded values. To regenerate them:

```bash
echo -n 'root' | base64                    # mongo-root-username
echo -n 'example' | base64                 # mongo-root-password
echo -n 'much_todo_db' | base64            # mongo-database
echo -n 'mongodb://root:example@mongodb-service:27017/much_todo_db?authSource=admin' | base64  # mongo-uri
```

> **Note:** Never commit real credentials to version control. Replace the example values with strong passwords in production.
