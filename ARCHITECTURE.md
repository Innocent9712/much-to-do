# System Architecture Documentation

This document describes the high-level system architecture, deployment strategy, and networking design for the **StartTech** full-stack web application.

---


## Architecture Overview

The StartTech application is a production-grade full-stack platform consisting of a React client, a Go API backend, a Redis caching tier, and a MongoDB persistent storage tier. The entire infrastructure is managed as code using **Terraform** and deployed on **Amazon Web Services (AWS)**.

```mermaid
graph TD
    User([User Client])
    CF[Amazon CloudFront CDN]
    S3[Amazon S3 Bucket (Frontend)]
    ALB[Application Load Balancer]
    ASG[Auto Scaling Group (EC2 Backend)]
    EC[Amazon ElastiCache Redis]
    DB[(MongoDB Atlas)]

    User -->|HTTPS static assets| CF
    CF -->|Origin Fetch| S3
    User -->|HTTPS API Requests /api/*| ALB
    ALB -->|HTTP 8080| ASG
    ASG -->|Cache preloading/sessions| EC
    ASG -->|Data Persistence| DB
```

---

## Component Architecture

### 1. Frontend Tier (React & S3 & CloudFront)
- **Technology Stack**: React 19, Vite, TypeScript, Tailwind CSS, TanStack Router & Query.
- **Hosting Model**: Native serverless static web hosting. Static assets are stored in a secure **Amazon S3** bucket.
- **Content Delivery Network**: **Amazon CloudFront** sits in front of the S3 bucket to provide global low-latency delivery, HTTPS termination, and compression.
- **Caching Strategy**: Custom cache-control headers are applied at build-time:
  - Static assets (JS, CSS, images) use aggressive immutable caching (`max-age=31536000,immutable`).
  - The entry file `index.html` uses `no-cache, no-store, must-revalidate` to ensure immediate updates upon redeployment.
- **SPA Fallbacks**: CloudFront is configured with custom error responses (404 and 403) redirecting to `/index.html` to support client-side TanStack Router paths seamlessly.

### 2. Application API Tier (Golang on EC2 ASG)
- **Technology Stack**: Golang 1.24, Gin Web Framework, Viper configuration loader.
- **Runtime Environment**: Dockerized containers running on Amazon Linux 2023 EC2 instances.
- **High Availability & Scalability**:
  - The instances run inside a multi-AZ **Auto Scaling Group (ASG)** spanning three Availability Zones.
  - Scale-out and scale-in policies are governed by target tracking metrics (e.g., Average CPU Utilization).
- **Load Balancing**: An internet-facing **Application Load Balancer (ALB)** terminates SSL/TLS, performs health checks at `/health`, and distributes incoming requests across healthy target EC2 instances.
- **Zero-Downtime Updates**: Deployments use a rolling update strategy via **ASG Instance Refreshes** with instance warmups, ensuring that traffic is only routed to active, healthy containers.

### 3. Caching & Session Tier (Amazon ElastiCache Redis)
- **Technology Stack**: AWS ElastiCache cluster running Redis.
- **Purpose**: Fast in-memory caching of heavy query results, user sessions, and rapid username lookup validation.
- **Optimization**: The backend preloads active usernames into Redis at startup to perform instant O(1) checks during signup.

### 4. Database Tier (MongoDB Atlas)
- **Technology Stack**: Cloud-managed MongoDB Atlas.
- **Purpose**: JSON document-based persistent storage.
- **Security**: Access is restricted using secure connection strings and credential management.

---

## Network & Security Architecture

```
                                  VPC (10.0.0.0/16)
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                         │
│   Public Subnets (Multi-AZ)                                                             │
│   ┌─────────────────────────────┐         ┌─────────────────────────────────────────┐   │
│   │  Internet Gateway           │  ────>  │  Application Load Balancer (ALB)        │   │
│   └─────────────────────────────┘         │  Security Group: Ingress 80/443         │   │
│                                           └─────────────────────────────────────────┘   │
│                                                                │                        │
│                                                                ▼ (HTTP 8080)            │
│   Private Subnets (Multi-AZ)                                                            │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│   │  EC2 Backend Instances (Auto Scaling Group)                                     │   │
│   │  Security Group: Ingress 8080 (only from ALB Security Group)                    │   │
│   └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                │                               │                        │
│                                ▼                               ▼                        │
│   Isolated Private Subnets (Multi-AZ)                                                   │
│   ┌─────────────────────────────────────────┐     ┌─────────────────────────────────┐   │
│   │  Amazon ElastiCache Redis               │     │  NAT Gateways / Route Tables    │   │
│   │  Security Group: Ingress 6379 (from EC2)│     │  Outbound egress to Atlas/ECR   │   │
│   └─────────────────────────────────────────┘     └─────────────────────────────────┘   │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### 1. Network Isolation
- **Public Subnets**: Host the ALB, NAT Gateways, and public routes.
- **Private Subnets**: Host the EC2 backend instances. They have no direct ingress route from the public internet.
- **Database/Cache Isolation**: ElastiCache Redis runs in isolated subnet groups accessible only from backend EC2 security groups.

### 2. Access Control (Least Privilege)
- **Security Groups**: Custom strict stateful firewalls for ALB, EC2, and Redis. The EC2 backend instances *only* allow HTTP traffic originating from the ALB.
- **IAM Instance Profiles**: EC2 instances are assigned minimal IAM policies allowing them to write application logs to **CloudWatch Logs**, publish custom metrics, and pull container images from **Amazon ECR**.
- **OIDC Integration**: GitHub Actions workflows deploy to AWS using secure OpenID Connect (OIDC) roles, eliminating static, long-lived AWS Access Keys.
