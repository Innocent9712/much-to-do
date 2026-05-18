This project containerizes and deploys the MuchToDo Golang backend application using Docker, Docker Compose, Kubernetes, and Kind.

The application uses MongoDB for persistence and demonstrates local container orchestration and Kubernetes deployment best practices.

Technologies Used:
- Golang
- Docker
- Docker Compose
- Kubernetes
- Kind
- MongoDB
- Redis
- kubectl

Architecture Overview:
- Backend API runs on port 8080
- MongoDB provides persistent storage
- Docker Compose manages local development services
- Kubernetes manages deployment orchestration
- Kind provides local Kubernetes cluster
- ConfigMaps and Secrets manage configuration

Project Structure:
container-assessment/
├── Dockerfile
├── docker-compose.yaml
├── .dockerignore
├── kubernetes/
├── scripts/
├── evidence/
└── README.md

Build Image: docker build -t muchtodo-backend:local .

Run Compose: docker compose up -d

Verify Services: docker ps
                curl http://localhost:8080/health 

Kubernetes Setup...

Create Kind Cluster: kind create cluster --name muchtodo-cluster

Load Local Image: kind load docker-image muchtodo-backend:local --name muchtodo-cluster

Deploy Resources: 
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/mongodb/
kubectl apply -f kubernetes/backend/
kubectl apply -f kubernetes/ingress.yaml

Verify Deployment:
kubectl get pods -n muchtodo
kubectl get svc -n muchtodo
kubectl get ingress -n muchtodo

Port Forwarding (Kind NodePort on my Windows was restrictive):

kubectl port-forward svc/backend-service 8080:8080 -n muchtodo

Litmus Test: curl http://localhost:8080/health

Key Kubernetes Features Implemented:

- Namespace isolation
- ConfigMaps
- Secrets
- Persistent Volume Claim
- Readiness probe
- Liveness probe
- NodePort Service
- Ingress Resource
- Multi-replica backend deployment

Challenges Encountered:
- Resolved Git branch mismatch after forking
- Fixed MongoDB keyfile permission issues on Windows
- Troubleshot Docker daemon connectivity problems
- Resolved Kubernetes CrashLoopBackOff debugging
- Fixed Go version mismatch during Docker build
- Worked around Kind NodePort accessibility limitations using port-forwarding

Evidence:
Screenshots are available in the evidence/ folder showing:
- Docker build success
- Docker Compose deployment
- Kubernetes deployment
- Pod status
- Service exposure
- Health endpoint verification


