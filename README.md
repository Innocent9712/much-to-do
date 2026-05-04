# MuchToDo — Container Assessment

Containerized deployment of the MuchToDo Golang API using Docker and Kubernetes (Kind).

## Project Structure

```
container-assessment/
├── Server/MuchToDo/         # Application source code
├── Dockerfile               # Multi-stage optimized Dockerfile
├── docker-compose.yml       # Local development setup
├── .dockerignore
├── mongodb.key              # Generated at runtime (see docker-run.sh)
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
├── evidence/                # Screenshots of deployment
└── README.md
```

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
- `openssl` (for generating MongoDB keyfile)

---

## Phase 1: Docker Setup

### Step 1 — Generate MongoDB keyfile
MongoDB's replica set requires a keyfile for internal authentication:
```bash
openssl rand -base64 756 > mongodb.key
chmod 400 mongodb.key
```

### Step 2 — Build the Docker image
```bash
chmod +x scripts/docker-build.sh
./scripts/docker-build.sh
```

### Step 3 — Run with Docker Compose
```bash
chmod +x scripts/docker-run.sh
./scripts/docker-run.sh
```

Services started:
| Service | URL |
|---|---|
| Backend API | http://localhost:8080 |
| Health check | http://localhost:8080/health |
| Swagger docs | http://localhost:8080/swagger/index.html |
| Mongo Express | http://localhost:8081 |
| Redis Commander | http://localhost:8082 |

### Verify
```bash
curl http://localhost:8080/health
curl http://localhost:8080/ping
```

### Stop
```bash
docker compose down
```

---

## Phase 2: Kubernetes Deployment

### Deploy to Kind
```bash
chmod +x scripts/k8s-deploy.sh
./scripts/k8s-deploy.sh
```

This will:
1. Create a Kind cluster named `muchtodo`
2. Build and load the Docker image into Kind
3. Apply all Kubernetes manifests in order
4. Wait for MongoDB, then deploy the backend (2 replicas)

### Access the application
```bash
# Via NodePort (direct)
curl http://localhost:30080/health

# Or via port-forward
kubectl port-forward svc/backend-service 8080:8080 -n muchtodo
curl http://localhost:8080/health
```

### Check cluster status
```bash
kubectl get pods -n muchtodo
kubectl get services -n muchtodo
kubectl get ingress -n muchtodo
kubectl describe deployment backend-deployment -n muchtodo
```

### View logs
```bash
kubectl logs -l app=backend -n muchtodo
kubectl logs -l app=mongodb -n muchtodo
```

### Cleanup
```bash
chmod +x scripts/k8s-cleanup.sh
./scripts/k8s-cleanup.sh
```

---

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `PORT` | Server port | `8080` |
| `MONGO_URI` | MongoDB connection string | required |
| `DB_NAME` | Database name | `much_todo_db` |
| `JWT_SECRET_KEY` | JWT signing secret | required |
| `JWT_EXPIRATION_HOURS` | Token expiry in hours | `72` |
| `ENABLE_CACHE` | Enable Redis caching | `false` |
| `REDIS_ADDR` | Redis address | `redis:6379` |
| `LOG_LEVEL` | DEBUG / INFO / WARN / ERROR | `INFO` |
| `LOG_FORMAT` | json / text | `json` |

---

## API Endpoints

| Method | Path | Description | Auth |
|---|---|---|---|
| GET | `/health` | Health check | No |
| GET | `/ping` | Ping | No |
| POST | `/users/register` | Register user | No |
| POST | `/users/login` | Login | No |
| GET | `/todos` | List todos | Yes |
| POST | `/todos` | Create todo | Yes |
| PUT | `/todos/:id` | Update todo | Yes |
| DELETE | `/todos/:id` | Delete todo | Yes |
