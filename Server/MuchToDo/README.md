# MuchTodo Containerization and Kubernetes Deployment

## Project Overview

This project containerizes the MuchTodo backend application using Docker and deploys it to a local Kubernetes cluster using Kind.

The backend is a Golang API that runs on port `8080` and connects to MongoDB. The setup includes Docker, Docker Compose, Kubernetes manifests, helper scripts, and deployment evidence.

## Requirements Covered

- Backend API runs on port `8080`
- MongoDB is used as the database
- Environment variables are used for configuration
- Health check endpoint is available at `/health`
- Ping endpoint is available at `/ping`
- Dockerfile uses a multi-stage build
- Backend runs as a non-root user
- Docker Compose runs backend and MongoDB locally
- Kubernetes deploys MongoDB with persistent storage
- Kubernetes deploys backend with 2 replicas
- Kubernetes services expose MongoDB and the backend
- Ingress manifest is included
- Evidence screenshots are stored in the `evidence/` folder

## Project Structure

```text
.
├── cmd/
│   └── api/
├── docs/
├── evidence/
├── internal/
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
├── scripts/
│   ├── docker-build.sh
│   ├── docker-run.sh
│   ├── k8s-deploy.sh
│   └── k8s-cleanup.sh
├── .dockerignore
├── docker-compose.yml
├── Dockerfile
├── go.mod
├── go.sum
├── Makefile
├── mongodb.key
└── README.md