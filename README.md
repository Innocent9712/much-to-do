# StartTech Application Suite

Welcome to the **StartTech Application Suite**! This repository contains the core application components for the StartTech platform: a high-performance React frontend and a robust Go API backend.

For the corresponding infrastructure code, see the [starttech-infra](/starttech-infra) repository.

---

## 📂 Repository Structure

```
starttech-application/
├── .github/
│   └── workflows/
│       ├── frontend-ci-cd.yml    # Frontend CI/CD S3 Deploy Pipeline
│       └── backend-ci-cd.yml     # Backend CI/CD ECR Deploy Pipeline
├── frontend/                     # React / Vite Client Application
├── backend/                      # Golang REST API Service
├── scripts/
│   ├── deploy-frontend.sh        # Static Build & S3 Upload Script
│   ├── deploy-backend.sh         # Docker Build & ECR Rolling Push Script
│   ├── health-check.sh           # Active ALB endpoint Health Checker
│   └── rollback.sh               # ASG Rollback Launch Template Reverter
└── README.md
```

---

## 📖 Essential Documentation
- **System Architecture**: Detailed network topology and service layouts are in [ARCHITECTURE.md](./ARCHITECTURE.md).
- **Incident Runbook**: Trouble-shooting playbooks, alert mitigations, and log analysis queries are in [RUNBOOK.md](./RUNBOOK.md).

---

## 🛠️ Local Development Setup

### 1. Prerequisite Environments
- **Go**: 1.24+ (Backend)
- **Node.js**: 22+ (Frontend)
- **Docker & Docker Compose**: For container-based local runners.

### 2. Local Backend Service Configuration
1. Navigate to the `backend` folder:
   ```bash
   cd backend
   ```
2. Copy the sample environment template:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` to supply your **MongoDB Atlas** URI connection string and **Redis** parameters:
   ```env
   PORT=8080
   MONGO_URI="mongodb+srv://<user>:<password>@cluster.mongodb.net/much_todo_db"
   DB_NAME=much_todo_db
   JWT_SECRET_KEY="your-strong-random-key"
   REDIS_ADDR="localhost:6379"
   REDIS_PASSWORD=""
   ```
4. Start the backend locally (generates swagger documentation and compiles the binary):
   ```bash
   make run
   # Or manually:
   # swag init -g ./cmd/api/main.go -o ./docs
   # go run ./cmd/api/main.go
   ```

### 3. Local Frontend Service Configuration
1. Navigate to the `frontend` folder:
   ```bash
   cd ../frontend
   ```
2. Copy the sample environment template:
   ```bash
   cp .env.example .env
   ```
3. Run the Vite React developer server locally:
   ```bash
   npm install
   npm run dev
   ```
4. Open your browser and navigate to `http://localhost:5173`.

---

## 🚀 CI/CD Deployment Pipelines

Deployments are automated through **GitHub Actions** workflows triggered on pushes/merges to the `master` branch.

### 1. Frontend Pipeline (S3 Native Static Hosting)
Defined in [frontend-ci-cd.yml](./.github/workflows/frontend-ci-cd.yml).
- **Build**: Audits dependencies (`npm audit`), runs lints, and compiles production React/Vite assets into `dist/`.
- **Deploy**: Authenticates to AWS via secure OpenID Connect (OIDC), syncs static build assets to the S3 bucket with optimal cache-control parameters, and invalidates the CloudFront CDN distribution cache.

### 2. Backend Pipeline (EC2 Container Deployment)
Defined in [backend-ci-cd.yml](./.github/workflows/backend-ci-cd.yml).
- **Test**: Audits packages, executes Go unit tests, and validates code quality.
- **Build**: Compiles the Go binary and packages it into a lightweight scratch-layer Alpine Docker image.
- **Scan**: Performs automated container security vulnerability scans using **Trivy**.
- **Publish & Deploy**: Pushes the secure container image to **Amazon ECR**, triggers a zero-downtime rolling update via **Auto Scaling Group Instance Refresh**, and verifies target group health.