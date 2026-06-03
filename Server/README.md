# MuchTodo Containerization and Kubernetes Deployment

## Overview

This project containerizes the MuchTodo Golang backend application and deploys it to a local Kubernetes cluster using Kind.

The application:

* Runs on port 8080
* Uses MongoDB as its database
* Supports environment variable configuration
* Provides a health endpoint at `/health`

---

## Prerequisites

Install the following tools:

* Docker Desktop
* Go
* kubectl
* Kind
* Git

---

## Docker Setup

### Build Docker Image

```bash
docker build -t muchtodo-app .
```

### Run with Docker Compose

```bash
docker-compose up -d
```

### Verify Containers

```bash
docker ps
```

### Verify Application

```bash
curl http://localhost:8080/health
```

---

## Kubernetes Deployment

### Create Kind Cluster

```bash
kind create cluster --name muchtodo-cluster
```

### Deploy Resources

```bash
kubectl apply -f kubernetes/namespace.yaml

kubectl apply -f kubernetes/mongodb/

kubectl apply -f kubernetes/backend/

kubectl apply -f kubernetes/ingress.yaml
```

### Verify Pods

```bash
kubectl get pods -n muchtodo
```

### Verify Services

```bash
kubectl get svc -n muchtodo
```

### Verify Ingress

```bash
kubectl get ingress -n muchtodo
```

---

## Project Structure

```text
MuchToDo/
├── Dockerfile
├── docker-compose.yaml
├── .dockerignore
├── kubernetes/
│   ├── namespace.yaml
│   ├── mongodb/
│   ├── backend/
│   └── ingress.yaml
├── scripts/
│   ├── docker-build.sh
│   ├── docker-run.sh
│   ├── k8s-deploy.sh
│   └── k8s-cleanup.sh
├── evidence/
└── README.md
```

---

## Cleanup

Delete Kubernetes resources:

```bash
kubectl delete namespace muchtodo
```

Delete Kind cluster:

```bash
kind delete cluster --name muchtodo-cluster
```

---

## Evidence

The `evidence` folder contains screenshots showing:

1. Docker image build completion
2. Docker Compose running successfully
3. Application health endpoint response
4. Kind cluster creation
5. Kubernetes pods running
6. Kubernetes services
7. Kubernetes ingress configuration
8. Application accessibility through Kubernetes

```

