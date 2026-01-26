# StartTech MuchToDo - System Architecture

## Overview

This document describes the architecture of the StartTech MuchToDo application, a full-stack task management system deployed on AWS with automated CI/CD pipelines.

---

## High-Level Architecture

```
                                    ┌─────────────────┐
                                    │   Developers    │
                                    └────────┬────────┘
                                             │
                                             │ git push
                                             ▼
                                    ┌─────────────────┐
                                    │  GitHub Repo    │
                                    │  (Application)  │
                                    └────────┬────────┘
                                             │
                          ┌──────────────────┴──────────────────┐
                          │                                     │
                          ▼                                     ▼
                ┌──────────────────┐              ┌──────────────────┐
                │ Frontend Pipeline│              │ Backend Pipeline │
                │ GitHub Actions   │              │ GitHub Actions   │
                └─────────┬────────┘              └─────────┬────────┘
                          │                                  │
                          │                                  │
                          ▼                                  ▼
                    ┌──────────┐                      ┌──────────┐
                    │   ECR    │                      │   ECR    │
                    │ (Images) │                      │ (Images) │
                    └─────┬────┘                      └─────┬────┘
                          │                                  │
                          ▼                                  │
                    ┌──────────┐                            │
                    │    S3    │                            │
                    │ (Assets) │                            │
                    └─────┬────┘                            │
                          │                                  │
                          ▼                                  │
                  ┌───────────────┐                         │
                  │  CloudFront   │                         │
                  │     (CDN)     │                         │
                  └───────┬───────┘                         │
                          │                                  │
                          │                                  ▼
                          │                        ┌──────────────────┐
                          │                        │   CodeDeploy     │
                          │                        └─────────┬────────┘
                          │                                  │
                          │                                  ▼
        ┌─────────────────┴─────────────┐          ┌──────────────────┐
        │          Internet              │          │   Auto Scaling   │
        │                                │          │      Group       │
        │  ┌──────────┐    ┌──────────┐│          │  ┌────┐  ┌────┐  │
        │  │  Users   │────│ CloudFront│◄──────────┼──│EC2 │  │EC2 │  │
        │  └──────────┘    └──────────┘│          │  └─┬──┘  └─┬──┘  │
        └────────────────────────────────┘          └────┼──────┼─────┘
                                                         │      │
                          ┌──────────────────────────────┴──────┴────┐
                          │                                           │
                          ▼                                           ▼
                  ┌──────────────┐                           ┌──────────────┐
                  │ ElastiCache  │                           │   MongoDB    │
                  │   (Redis)    │                           │    Atlas     │
                  └──────────────┘                           └──────────────┘
```

---

## Component Details

### Frontend (Client)

**Technology Stack**:

- React 19 with TypeScript
- Vite (build tool)
- TanStack Router (routing)
- TanStack Query (data fetching)
- Tailwind CSS (styling)
- Radix UI (component library)

**Deployment**:

- Static files built and deployed to S3
- CloudFront CDN for global distribution
- Automated invalidation on deployment

**Infrastructure**:

- S3 bucket with static website hosting
- CloudFront distribution with:
  - Custom domain support
  - HTTPS/TLS termination
  - Caching optimizations
  - Origin Access Identity (OAI) for S3 access

### Backend (Server)

**Technology Stack**:

- Go 1.21
- Gin web framework
- JWT authentication
- MongoDB driver
- Redis client
- Swagger/OpenAPI documentation

**Deployment**:

- Docker containerized application
- ECR for image storage
- CodeDeploy for rolling updates
- EC2 instances with Auto Scaling

**Infrastructure**:

- Application Load Balancer (ALB)
- Auto Scaling Group (ASG) with:
  - Min: 2 instances
  - Desired: 2 instances
  - Max: 6 instances
- Target-based scaling policies:
  - CPU utilization > 70%
  - Request count per target > 1000
- Health checks via `/health` endpoint

### Database Layer

**MongoDB Atlas**:

- Managed MongoDB cluster
- Replica set for high availability
- Automated backups
- Point-in-time recovery
- Encrypted at rest and in transit

**Schema**:

```
Collections:
- users (authentication and profiles)
- todos (task management)
```

### Caching Layer

**AWS ElastiCache (Redis)**:

- Managed Redis cluster
- In-memory caching
- Session storage
- Cache-aside pattern
- Automatic failover

**Use Cases**:

- Session management
- API response caching
- Rate limiting
- Real-time data

---

## Network Architecture

### VPC Configuration

```
VPC (10.0.0.0/16)
│
├── Public Subnets (Internet-facing)
│   ├── 10.0.1.0/24 (AZ-a)
│   ├── 10.0.2.0/24 (AZ-b)
│   └── Application Load Balancer
│
└── Private Subnets (Internal)
    ├── 10.0.10.0/24 (AZ-a)
    ├── 10.0.11.0/24 (AZ-b)
    ├── EC2 Instances (Auto Scaling)
    └── ElastiCache Redis
```

### Security Groups

**ALB Security Group**:

- Inbound: 443 (HTTPS) from Internet (0.0.0.0/0)
- Inbound: 80 (HTTP) from Internet (0.0.0.0/0) → redirects to HTTPS
- Outbound: 8080 to EC2 Security Group

**EC2 Security Group**:

- Inbound: 8080 from ALB Security Group
- Inbound: 22 (SSH) from Bastion/VPN (optional, for troubleshooting)
- Outbound: 443 to Internet (for AWS APIs)
- Outbound: 6379 to Redis Security Group
- Outbound: 27017 to MongoDB Atlas (via NAT Gateway)

**Redis Security Group**:

- Inbound: 6379 from EC2 Security Group
- Outbound: None required

---

## CI/CD Pipeline Architecture

### Frontend Pipeline

```
Trigger (push to main/develop)
    ↓
┌───────────────────────┐
│  Checkout Code        │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Install Dependencies │
│  (npm ci)             │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Run Tests & Lint     │
│  (npm run lint/test)  │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Security Audit       │
│  (npm audit)          │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Build Production     │
│  (npm run build)      │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Configure AWS        │
│  (OIDC Auth)          │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Sync to S3           │
│  (aws s3 sync)        │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Invalidate CloudFront│
└───────────────────────┘
```

### Backend Pipeline

```
Trigger (push to main/develop)
    ↓
┌───────────────────────┐
│  Checkout Code        │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Setup Go             │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Run Tests            │
│  (go test)            │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Code Quality Checks  │
│  (gofmt, go vet)      │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Security Scan        │
│  (gosec)              │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Build Docker Image   │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Scan Image           │
│  (Trivy)              │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Push to ECR          │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Create Deployment    │
│  Package              │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Upload to S3         │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Trigger CodeDeploy   │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Wait for Deployment  │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│  Run Smoke Tests      │
│  (Health Check)       │
└───────────────────────┘
```

---

## Data Flow

### User Request Flow

```
1. User → CloudFront → S3 (Frontend Assets)
   └─> Browser renders React app

2. Browser → CloudFront → ALB → EC2 (API Request)
   └─> Go API processes request

3. EC2 → Redis (Cache Check)
   ├─> Cache Hit: Return cached data
   └─> Cache Miss: Query MongoDB

4. EC2 → MongoDB Atlas (Data Query)
   └─> Return data to EC2

5. EC2 → Redis (Cache Write)
   └─> Store result for future requests

6. EC2 → ALB → CloudFront → Browser
   └─> Return JSON response
```

### Authentication Flow

```
1. User submits login credentials
   ↓
2. Frontend → API: POST /api/auth/login
   ↓
3. API validates credentials against MongoDB
   ↓
4. API generates JWT token
   ↓
5. API stores session in Redis
   ↓
6. API returns JWT in HTTP-only cookie
   ↓
7. Subsequent requests include cookie
   ↓
8. Middleware validates JWT
   ↓
9. Middleware checks session in Redis
   ↓
10. Request proceeds if valid
```

---

## Scaling Strategy

### Horizontal Scaling

**Auto Scaling Triggers**:

- CPU Utilization > 70% → Scale out
- CPU Utilization < 30% → Scale in
- Request count per target > 1000 → Scale out

**Scaling Policies**:

- Scale out: Add 1 instance, cooldown 60s
- Scale in: Remove 1 instance, cooldown 300s

### Vertical Scaling

**Instance Types** (progression):

- Development: t3.small
- Staging: t3.medium
- Production: t3.large or c5.large

---

## Disaster Recovery

### Backup Strategy

**MongoDB Atlas**:

- Automated daily snapshots
- Retention: 7 days
- Point-in-time recovery available

**S3 Versioning**:

- Enabled on frontend buckets
- Allows rollback to previous versions

**ECR Images**:

- All images tagged with commit SHA
- Retained for 30 days
- Can redeploy any previous version

### Recovery Procedures

**Frontend**: Restore previous S3 version or redeploy from Git
**Backend**: Rollback CodeDeploy deployment or retag ECR image
**Database**: Restore MongoDB snapshot via Atlas console

---

## Security

### Authentication & Authorization

- JWT-based authentication
- HTTP-only cookies for token storage
- Role-based access control (RBAC)

### Network Security

- VPC isolation
- Security groups (principle of least privilege)
- Private subnets for application servers
- No public SSH access

### Data Security

- TLS/HTTPS everywhere
- MongoDB encryption at rest and in transit
- ElastiCache encryption in transit
- AWS Secrets Manager for sensitive config

### Application Security

- CORS configuration
- Input validation
- SQL/NoSQL injection prevention
- Rate limiting
- Security headers (CSP, HSTS, etc.)

---

## Monitoring & Observability

### Metrics

**CloudWatch Metrics**:

- ALB: Request count, latency, 4xx/5xx errors
- EC2: CPU, memory, disk, network
- Auto Scaling: Instance count, scaling activities
- ElastiCache: CPU, connections, evictions

**Application Metrics**:

- API endpoint latency
- Request/response rates
- Error rates by endpoint
- Authentication success/failure

### Logging

**Log Aggregation**:

- All logs sent to CloudWatch Logs
- Log groups per service
- Retention: 30 days

**Log Sources**:

- EC2 application logs (Docker container logs)
- ALB access logs
- CloudFront access logs (optional)
- VPC Flow Logs (optional)

### Alerts

**CloudWatch Alarms**:

- Unhealthy target count > 0
- CPU utilization > 80%
- API latency > 1000ms
- 5xx error rate > 1%
- ElastiCache evictions > 100/min

---

## Cost Optimization

### Strategies

1. **Auto Scaling**: Scale down during low traffic
2. **Reserved Instances**: Commit to base capacity
3. **S3 Lifecycle Policies**: Transition old objects to Glacier
4. **CloudFront Caching**: Reduce origin requests
5. **ElastiCache**: Reduce MongoDB queries

### Cost Breakdown (Estimated Monthly)

- EC2 (2 x t3.medium): ~$60
- ALB: ~$20
- ElastiCache (cache.t3.micro): ~$15
- S3 + CloudFront: ~$10
- MongoDB Atlas (M10): ~$57
- CodeDeploy: Free (EC2 deployments)
- ECR: ~$1 (per GB)

**Total**: ~$163/month (excluding data transfer)

---

## Future Enhancements

1. **Multi-Region Deployment**: Active-active across regions
2. **Blue-Green Deployments**: Zero-downtime deployments
3. **Canary Releases**: Gradual rollout to subset of users
4. **GraphQL API**: Alternative to REST
5. **Real-time Features**: WebSocket support for live updates
6. **Observability**: Distributed tracing (AWS X-Ray, OpenTelemetry)
7. **WAF**: Web Application Firewall for DDoS protection
8. **CDN Edge Functions**: Lambda@Edge for edge computing

---

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [MongoDB Atlas Best Practices](https://docs.atlas.mongodb.com/best-practices/)
- [Redis Best Practices](https://redis.io/docs/manual/patterns/)
- [Go Best Practices](https://golang.org/doc/effective_go)
- [React Best Practices](https://react.dev/learn/thinking-in-react)

---

**Last Updated**: 2026-01-25
**Version**: 1.0.0
