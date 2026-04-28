# 🚀 MuchTodo DevOps Project

## 📌 Overview

This project demonstrates the containerization and deployment of the **MuchTodo** backend application using:

* **Golang** (Backend API)
* **MongoDB** (Database)
* **Docker & Docker Compose** (Local containerization)
* **Kubernetes (Kind)** (Container orchestration)

The goal is to modernize deployment using DevOps best practices.

---

## 🏗️ Project Structure

```bash
.
├── Dockerfile
├── docker-compose.yml
├── README.md
├── Evidence/
│   ├── Evidence.md
│   └── screenshots/
│       ├── App_accessibility_1.png
│       ├── App_accessibility_2.png
│       ├── Application-responding.png
│       ├── docker-build.png
│       ├── docker-build-2.png
│       ├── docker-build-3.png
│       ├── docker-compose.png
│       ├── ingress.png
│       ├── kind_cluster.png
│       ├── kubernete_deployment.png
│       ├── pods.png
│       └── services.png
├── Server/
│   └── MuchToDo/
│       ├── Makefile
│       ├── cmd/api/main.go
│       ├── docs/
│       ├── go.mod
│       ├── go.sum
│       ├── internal/
│       │   ├── auth/
│       │   ├── cache/
│       │   ├── config/
│       │   ├── database/
│       │   ├── handlers/
│       │   ├── logger/
│       │   ├── middleware/
│       │   ├── models/
│       │   └── routes/
├── kubernetes/
│   ├── namespace.yaml
│   ├── ingress.yaml
│   ├── kind-config.yaml
│   ├── backend/
│   │   ├── backend-configmap.yaml
│   │   ├── backend-deployment.yaml
│   │   ├── backend-secret.yaml
│   │   └── backend-service.yaml
│   ├── mongodb/
│   │   ├── mongodb-configmap.yaml
│   │   ├── mongodb-deployment.yaml
│   │   ├── mongodb-pvc.yaml
│   │   ├── mongodb-secret.yaml
│   │   └── mongodb-service.yaml
├── scripts/
│   ├── docker-build.sh
│   ├── docker-run.sh
│   ├── k8s-deploy.sh
│   └── k8s-cleanup.sh
```

---

## 🐳 Docker Setup

### 🔨 Build Image

```bash
./scripts/docker-build.sh
```

### ▶️ Run with Docker Compose

```bash
./scripts/docker-run.sh
```

### 🌐 Access Application

```bash
http://localhost:8080
```

---

## ☸️ Kubernetes Setup (Kind)

### 1️⃣ Create Cluster

```bash
kind create cluster --name kind
```

### 2️⃣ Load Image into Kind

```bash
kind load docker-image much-to-do-backend:latest
```

### 3️⃣ Deploy Application

```bash
./scripts/k8s-deploy.sh
```

---

## 🔍 Verify Deployment

```bash
kubectl get pods -n muchtodo
kubectl get svc -n muchtodo
kubectl get ingress -n muchtodo
```

---

## 🌐 Access Application (Kubernetes)

### Option 1: Port Forward

```bash
kubectl port-forward svc/backend 8080:80 -n muchtodo
```

Then open:

```
http://localhost:8080
```

---

### Option 2: NodePort

```bash
kubectl get svc -n muchtodo
```

Access:

```
http://localhost:<NodePort>
```

---

### Option 3: Ingress (if configured)

Update `/etc/hosts`:

```
127.0.0.1 muchtodo.local
```

Then open:

```
http://muchtodo.local
```

---

## 🧹 Cleanup

### Remove Kubernetes Resources

```bash
./scripts/k8s-cleanup.sh
```

### Delete Kind Cluster

```bash
kind delete cluster --name kind
```

---

## 📸 Evidence

All required deployment proof screenshots are available in:

```
Evidence/screenshots/
```

### Includes:

* ✅ Docker build success
* ✅ Docker compose running
* ✅ Application responding
* ✅ Kind cluster creation
* ✅ Kubernetes deployments
* ✅ Pods and services
* ✅ Ingress setup
* ✅ Application accessibility

---

## 🧠 Key Learnings

* Containerizing applications using Docker
* Multi-container orchestration with Docker Compose
* Kubernetes resource management (Deployment, Service, Ingress)
* Debugging real-world DevOps issues (ImagePullBackOff, networking, etc.)
* Running Kubernetes locally using Kind

---

## 🚀 Future Improvements

* CI/CD pipeline with GitHub Actions
* Deploy to cloud (AWS EKS / Azure AKS)
* Add monitoring (Prometheus + Grafana)
* Use Helm for templating

---

## 👨‍💻 Author

**Silias Odion**
DevOps / Cloud Engineer 🚀

---
