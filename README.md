# StartTech MuchToDo Application

A full-stack task management application with automated CI/CD deployment to AWS.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [CI/CD Setup](#cicd-setup)
- [Deployment](#deployment)
- [Documentation](#documentation)

---

## 🎯 Overview

MuchToDo is a modern task management application built with React and Go, deployed on AWS with automated CI/CD pipelines. The application features user authentication, real-time updates, and scalable architecture designed for production workloads.

## ✨ Features

- **User Authentication**: JWT-based authentication with secure HTTP-only cookies
- **Task Management**: Create, read, update, and delete tasks
- **Real-time Caching**: Redis-based caching for improved performance
- **Responsive UI**: Modern React interface with Tailwind CSS
- **API Documentation**: Interactive Swagger/OpenAPI documentation
- **Auto-scaling**: Horizontal scaling based on load
- **High Availability**: Multi-AZ deployment with load balancing

---

## 🛠 Tech Stack

### Frontend

- **Framework**: React 19 with TypeScript
- **Build Tool**: Vite 7
- **Routing**: TanStack Router
- **State Management**: TanStack Query
- **Styling**: Tailwind CSS 4
- **UI Components**: Radix UI
- **HTTP Client**: Axios

### Backend

- **Language**: Go 1.21
- **Web Framework**: Gin
- **Database**: MongoDB (MongoDB Atlas)
- **Cache**: Redis (AWS ElastiCache)
- **Authentication**: JWT
- **API Docs**: Swagger/Swag

### Infrastructure

- **Cloud Provider**: AWS
- **Frontend Hosting**: S3 + CloudFront
- **Backend Compute**: EC2 with Auto Scaling
- **Load Balancer**: Application Load Balancer (ALB)
- **Container Registry**: Amazon ECR
- **Deployment**: AWS CodeDeploy
- **CI/CD**: GitHub Actions
- **IaC**: Terraform (separate repository)

---

## 🏗 Architecture

```
Users → CloudFront → S3 (Frontend)
Users → CloudFront → ALB → EC2 Auto Scaling Group (Backend)
                              ↓
                     ElastiCache Redis + MongoDB Atlas
```

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 🚀 Getting Started

### Prerequisites

- Node.js 20+
- Go 1.21+
- Docker & Docker Compose
- MongoDB
- Redis
- AWS CLI (for deployment)

### Local Development

#### 1. Clone the Repository

```bash
git clone https://github.com/Kindee18/StartTech-Kindson-1148.git
cd StartTech-Kindson-1148
```

#### 2. Start Infrastructure (Docker Compose)

```bash
cd Server/MuchToDo
docker-compose up -d
```

This starts:

- MongoDB (port 27017)
- Mongo Express (port 8081)
- Redis (port 6379)
- Redis Commander (port 8082)

#### 3. Run Backend

```bash
cd Server/MuchToDo

# Copy environment file
cp .env.example .env

# Install dependencies
go mod download

# Run server
make run
# Or: go run cmd/api/main.go
```

Backend will be available at `http://localhost:8080`

#### 4. Run Frontend

```bash
cd Client

# Copy environment file
cp .env.example .env

# Install dependencies
npm install

# Start development server
npm run dev
```

Frontend will be available at `http://localhost:5173`

### Testing

**Backend Tests**:

```bash
cd Server/MuchToDo
make unit-test
make integration-test
```

**Frontend Tests**:

```bash
cd Client
npm run test
npm run lint
```

### API Documentation

Once the backend is running, access Swagger documentation at:

```
http://localhost:8080/swagger/index.html
```

---

## 🔄 CI/CD Setup

### Prerequisites

1. **AWS Infrastructure**: Deploy infrastructure first using the `starttech-infra` repository
2. **GitHub Repository**: Fork this repository
3. **AWS IAM OIDC Provider**: Set up GitHub Actions OIDC (see [RUNBOOK.md](RUNBOOK.md#oidc-setup))

### Required GitHub Secrets

Configure these secrets in your GitHub repository settings:

#### AWS Configuration

```
AWS_ROLE_ARN                  # IAM role ARN for GitHub OIDC
AWS_REGION                    # e.g., us-east-1
```

#### Frontend Secrets

```
S3_BUCKET_STAGING             # S3 bucket for staging frontend
S3_BUCKET_PROD                # S3 bucket for production frontend
CLOUDFRONT_ID_STAGING         # CloudFront distribution ID for staging
CLOUDFRONT_ID_PROD            # CloudFront distribution ID for production
API_BASE_URL_STAGING          # Staging API URL (https://api-staging.example.com)
API_BASE_URL_PROD             # Production API URL (https://api.example.com)
```

#### Backend Secrets

```
ECR_REPOSITORY_BACKEND        # ECR repository name for backend images
CODEDEPLOY_APP                # CodeDeploy application name
CODEDEPLOY_GROUP_STAGING      # CodeDeploy deployment group for staging
CODEDEPLOY_GROUP_PROD         # CodeDeploy deployment group for production
CODEDEPLOY_S3_BUCKET          # S3 bucket for CodeDeploy artifacts
```

### Pipeline Overview

#### Frontend Pipeline (`.github/workflows/frontend-ci-cd.yml`)

**Triggers**: Push to `main` or `develop` branches
**Steps**:

1. Test & Lint
2. Build production bundle
3. Deploy to S3
4. Invalidate CloudFront cache

#### Backend Pipeline (`.github/workflows/backend-ci-cd.yml`)

**Triggers**: Push to `main` or `develop` branches
**Steps**:

1. Run tests
2. Build Docker image
3. Scan for vulnerabilities
4. Push to ECR
5. Deploy via CodeDeploy
6. Run smoke tests

---

## 🚢 Deployment

### Automated Deployment

**Staging**:

```bash
git checkout develop
git add .
git commit -m "Your changes"
git push origin develop
```

**Production**:

```bash
git checkout main
git merge develop
git push origin main
```

Pipelines will automatically deploy to the respective environments.

### Manual Deployment

**Frontend**:

```bash
chmod +x scripts/deploy-frontend.sh
./scripts/deploy-frontend.sh production <s3-bucket> <cloudfront-id>
```

**Backend**:

```bash
chmod +x scripts/deploy-backend.sh
./scripts/deploy-backend.sh production <s3-key>
```

### Health Checks

```bash
# Frontend
curl https://app.muchtodo.com/health

# Backend
chmod +x scripts/health-check.sh
./scripts/health-check.sh https://api.muchtodo.com
```

### Rollback

```bash
# Frontend rollback
chmod +x scripts/rollback.sh
./scripts/rollback.sh frontend production

# Backend rollback
./scripts/rollback.sh backend production <deployment-id>
```

---

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)**: System architecture and design decisions
- **[RUNBOOK.md](RUNBOOK.md)**: Operations guide, troubleshooting, and procedures
- **API Documentation**: Available at `/swagger/index.html` on the backend

---

## 🔒 Security

- Never commit secrets or credentials to Git
- Use AWS Secrets Manager or SSM Parameter Store for sensitive configuration
- Enable MFA on AWS accounts
- Rotate credentials regularly
- Review IAM policies for least privilege
- Keep dependencies updated

---

## 📁 Project Structure

```
StartTech-Kindson-1148/
├── .github/
│   └── workflows/               # GitHub Actions CI/CD pipelines
│       ├── frontend-ci-cd.yml
│       └── backend-ci-cd.yml
├── Client/                      # React frontend
│   ├── src/
│   ├── public/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
├── Server/MuchToDo/            # Go backend
│   ├── cmd/
│   ├── internal/
│   ├── docs/                   # Swagger docs
│   ├── Dockerfile
│   ├── docker-compose.yaml
│   └── go.mod
├── scripts/                     # Deployment and utility scripts
│   ├── deploy-frontend.sh
│   ├── deploy-backend.sh
│   ├── health-check.sh
│   └── rollback.sh
├── appspec.yml                 # CodeDeploy configuration
├── ARCHITECTURE.md             # Architecture documentation
├── RUNBOOK.md                  # Operations runbook
└── README.md                   # This file
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License.

---

## 👥 Team

**StartTech DevOps Team**

- DevOps Lead: devops@starttech.com
- Backend Team: backend@starttech.com
- Frontend Team: frontend@starttech.com

---

## 🔗 Related Repositories

- **Infrastructure Repository**: `starttech-infra` (Terraform configurations)

---

## 📞 Support

For issues and questions:

- Create an issue in this repository
- Contact: oncall@starttech.com
- AWS Support: https://console.aws.amazon.com/support/

---

**Last Updated**: 2026-01-25
**Version**: 1.0.0
