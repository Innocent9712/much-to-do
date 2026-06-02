# StartTech Much ToDo - Application Repository

This repository contains the full-stack source code for StartTech's primary app, "Much ToDo". It features a Vite-based React frontend and a RESTful backend API written in Go, powered by MongoDB and Redis.

## Repository Layout

```text
starttech-application/
├── .github/
│   └── workflows/
│       ├── frontend-ci-cd.yml       # React CI/CD (Tests, S3 Sync, CloudFront cache invalidation)
│       └── backend-ci-cd.yml        # Go CI/CD (Lints, Go tests, Docker ECR push, ASG instance refresh)
├── frontend/                        # React static SPA
│   ├── src/                         # React components, contexts, hooks, assets
│   ├── package.json                 # Dependency list
│   └── vite.config.js               # Bundler configuration
├── backend/                         # Golang API backend
│   ├── cmd/api/main.go              # Server entry point
│   ├── internal/                    # Core backend logic (routes, handlers, models, database)
│   ├── Dockerfile                   # Multistage backend container build
│   └── go.mod                       # Go modules list
├── scripts/                         # Deployment & validation helper scripts
│   ├── deploy-frontend.sh           # Syncs assets to S3 and invalidates CDN
│   ├── deploy-backend.sh            # Pushes SSM variables and triggers ASG rolling refresh
│   ├── health-check.sh              # Live smoke testing utility
│   └── rollback.sh                  # Operational recovery rollback utility
└── README.md
```

---

## Local Development Guide

To run the application locally on your workstation, follow these steps:

### Option A: Using Docker Compose (Recommended)
We provide a local Docker Compose setup that runs the API, React Client, MongoDB, and Redis out-of-the-box.
1. Run compose from the repository root:
   ```bash
   docker-compose up --build
   ```
2. Open [http://localhost:5173](http://localhost:5173) in your browser.

### Option B: Running Manually

#### 1. Setup Database and Cache
Launch local instances of Redis and MongoDB:
```bash
docker run -d -p 6379:6379 redis:alpine
docker run -d -p 27017:27017 -e MONGO_INITDB_ROOT_USERNAME=root -e MONGO_INITDB_ROOT_PASSWORD=Password!234 mongo:8.0
```

#### 2. Run Go Backend API
Navigate to the `backend` directory, create a `.env` file, and start the app:
```bash
cd backend
# Create a .env file with configuration:
# MONGO_URI=mongodb://root:Password!234@localhost:27017/much_todo_db?authSource=admin
# REDIS_ADDR=localhost:6379
# JWT_SECRET_KEY=dev-jwt-secret-key-32-chars-long-1234
# PORT=8080

go run cmd/api/main.go
```

#### 3. Run React Frontend
In a new terminal window, navigate to `frontend`, install packages, and start the dev server:
```bash
cd frontend
npm install
# Ensure environment variables are loaded (Vite uses VITE_API_BASE_URL)
echo "VITE_API_BASE_URL=http://localhost:8080" > .env
npm run dev
```

---

## Testing & CI/CD Pipelines

Our CI/CD pipelines run on GitHub Actions to ensure code quality and seamless deployments:

### Frontend CI/CD (`.github/workflows/frontend-ci-cd.yml`)
- Runs on push/PR to `frontend/**`.
- **Lint**: Audits code conventions (`npm run lint`).
- **Scan**: Audits npm package vulnerabilities (`npm audit`).
- **Test**: Executes unit test suites (`npm run test`).
- **Deploy**: (On merge to `main`) Builds distribution files, uploads them to the hosting S3 bucket, and triggers a CloudFront invalidation path `/*`.

### Backend CI/CD (`.github/workflows/backend-ci-cd.yml`)
- Runs on push/PR to `backend/**`.
- **Verify**: Verifies code styling using `gofmt` and runs `go vet`.
- **Scan**: Executes security vulnerability audit with `govulncheck`.
- **Test**: Launches unit and integration tests (uses **testcontainers-go** to spawn short-lived Redis and Mongo containers for isolation testing).
- **Build**: Compiles Go binary and builds static Docker image. Runs a security scan on the container image using **Trivy**.
- **Deploy**: (On merge to `main`) Pushes image to Amazon ECR, updates SSM Parameter Store tag, and requests an Instance Refresh (Rolling Update) on the ASG. Runs a smoke test using `scripts/health-check.sh` to confirm API availability.
