# StartTech MuchToDo Application - Operations Runbook

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [CI/CD Pipeline](#cicd-pipeline)
4. [Deployment Procedures](#deployment-procedures)
5. [Monitoring & Logging](#monitoring--logging)
6. [Troubleshooting](#troubleshooting)
7. [Rollback Procedures](#rollback-procedures)
8. [Emergency Contacts](#emergency-contacts)

---

## System Overview

### Components

- **Frontend**: React SPA hosted on S3 with CloudFront CDN
- **Backend**: Go API running on EC2 instances with Auto Scaling
- **Database**: MongoDB Atlas cluster
- **Cache**: AWS ElastiCache Redis
- **Load Balancer**: Application Load Balancer (ALB)
- **Deployment**: AWS CodeDeploy

### Environments

- **Staging**: `develop` branch → staging resources
- **Production**: `main` branch → production resources

---

## Architecture

```
CloudFront (CDN)
    ↓
S3 (Frontend Static Files)

Internet → ALB → EC2 Auto Scaling Group (Backend API)
                      ↓
                  ElastiCache Redis
                      ↓
                  MongoDB Atlas
```

### Infrastructure

- **VPC**: Isolated network environment
- **Subnets**: Public (ALB) and Private (EC2 instances)
- **Security Groups**: Restrict traffic between components
- **IAM Roles**: EC2 instance profiles for AWS service access

---

## CI/CD Pipeline

### Frontend Pipeline (`.github/workflows/frontend-ci-cd.yml`)

**Triggers**: Push to `main` or `develop` branches (paths: `Client/**`)

**Stages**:

1. **Test & Lint**
   - Install dependencies
   - Run ESLint
   - Execute unit tests
   - Security audit (`npm audit`)

2. **Build & Deploy**
   - Build production bundle
   - Sync to S3
   - Invalidate CloudFront cache
   - Send deployment notifications

**Environment Variables** (set per branch):

- `S3_BUCKET_STAGING` / `S3_BUCKET_PROD`
- `CLOUDFRONT_ID_STAGING` / `CLOUDFRONT_ID_PROD`
- `API_BASE_URL_STAGING` / `API_BASE_URL_PROD`

### Backend Pipeline (`.github/workflows/backend-ci-cd.yml`)

**Triggers**: Push to `main` or `develop` branches (paths: `Server/**`)

**Stages**:

1. **Test & Lint**
   - Run Go tests with race detector
   - Code formatting check (`gofmt`)
   - Static analysis (`go vet`)
   - Security scan (`gosec`)

2. **Build**
   - Build Docker image
   - Scan for vulnerabilities (Trivy)
   - Push to ECR
   - Tag: `latest`, `<environment>`, `<commit-sha>`

3. **Deploy**
   - Create deployment package (appspec.yml + scripts)
   - Upload to S3
   - Trigger CodeDeploy
   - Wait for deployment success
   - Run smoke tests

**Environment Variables** (set per branch):

- `ECR_REPOSITORY_BACKEND`
- `CODEDEPLOY_APP`
- `CODEDEPLOY_GROUP_STAGING` / `CODEDEPLOY_GROUP_PROD`
- `CODEDEPLOY_S3_BUCKET`
- `API_BASE_URL_STAGING` / `API_BASE_URL_PROD`

---

## Deployment Procedures

### Prerequisites

**GitHub Secrets** (Required):

```
AWS_ROLE_ARN                  # IAM role for GitHub OIDC
AWS_REGION                    # e.g., us-east-1

# Frontend
S3_BUCKET_STAGING
S3_BUCKET_PROD
CLOUDFRONT_ID_STAGING
CLOUDFRONT_ID_PROD
API_BASE_URL_STAGING
API_BASE_URL_PROD

# Backend
ECR_REPOSITORY_BACKEND
CODEDEPLOY_APP
CODEDEPLOY_GROUP_STAGING
CODEDEPLOY_GROUP_PROD
CODEDEPLOY_S3_BUCKET
```

### Automated Deployment

1. **Staging Deployment**

   ```bash
   git checkout develop
   git pull origin develop
   # Make changes
   git add .
   git commit -m "Your changes"
   git push origin develop
   ```

   Pipeline automatically deploys to staging.

2. **Production Deployment**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```
   Pipeline automatically deploys to production.

### Manual Deployment

**Frontend**:

```bash
./scripts/deploy-frontend.sh <environment> <s3-bucket> <cloudfront-id>

# Example - Staging
./scripts/deploy-frontend.sh staging my-frontend-staging-bucket E1234ABCDEF

# Example - Production
./scripts/deploy-frontend.sh production my-frontend-prod-bucket E5678GHIJKL
```

**Backend**:

```bash
./scripts/deploy-backend.sh <environment> <s3-key>

# Example
./scripts/deploy-backend.sh staging staging/backend-abc123-1234567890.zip
```

---

## Monitoring & Logging

### Health Checks

**Frontend**:

```bash
curl https://app.muchtodo.com/health
# Expected: 200 OK, "healthy"
```

**Backend**:

```bash
./scripts/health-check.sh https://api.muchtodo.com
# Or manually:
curl https://api.muchtodo.com/health
# Expected: 200 OK
```

### CloudWatch Logs

**Backend API Logs**:

- **Log Group**: `/aws/ec2/muchtodo-api`
- **Log Streams**: `<environment>-<hostname>`

**View Logs**:

```bash
aws logs tail /aws/ec2/muchtodo-api --follow --format short
```

**Query Logs** (CloudWatch Logs Insights):

```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

### CloudWatch Alarms

Monitor these metrics:

- **ALB Target Health**: Unhealthy targets
- **EC2 CPU Utilization**: > 80%
- **API Latency**: > 1000ms
- **4xx/5xx Error Rates**: > 5%

### Application Metrics

**API Documentation**: `https://api.muchtodo.com/swagger/index.html`

---

## Troubleshooting

### Common Issues

#### 1. Frontend Not Loading

**Symptoms**: Blank page, 404 errors

**Diagnosis**:

```bash
# Check S3 bucket
aws s3 ls s3://<bucket-name>/

# Check CloudFront distribution
aws cloudfront get-distribution --id <distribution-id>
```

**Solutions**:

- Verify S3 bucket has correct files
- Check CloudFront distribution status (must be "Deployed")
- Invalidate CloudFront cache: `aws cloudfront create-invalidation --distribution-id <id> --paths "/*"`

#### 2. Backend API Not Responding

**Symptoms**: 502/503 errors, timeouts

**Diagnosis**:

```bash
# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=muchtodo-api-*" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]'

# Check target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check container logs
ssh ec2-user@<instance-ip>
docker logs muchtodo-api --tail 100
```

**Solutions**:

- Check EC2 instance health in Auto Scaling Group
- Verify security groups allow ALB → EC2 traffic (port 8080)
- Check application logs for errors
- Restart container: `docker restart muchtodo-api`

#### 3. CodeDeploy Deployment Failed

**Symptoms**: Deployment stuck or failed

**Diagnosis**:

```bash
# Get deployment details
aws deploy get-deployment --deployment-id <deployment-id>

# View deployment logs
aws deploy list-deployment-instances --deployment-id <deployment-id>
```

**Solutions**:

- Check CodeDeploy agent on EC2: `sudo service codedeploy-agent status`
- Review lifecycle event logs: `/var/log/aws/codedeploy-agent/`
- Verify IAM role has necessary permissions
- Check appspec.yml syntax

#### 4. Database Connection Issues

**Symptoms**: API returns 500 errors, "connection refused"

**Diagnosis**:

```bash
# Test MongoDB connection from EC2
docker exec -it muchtodo-api sh
# Inside container:
nc -zv <mongodb-host> 27017
```

**Solutions**:

- Verify MongoDB Atlas IP whitelist includes EC2 NAT Gateway IPs
- Check MongoDB connection string in environment variables
- Verify MongoDB Atlas cluster is running

#### 5. Redis Cache Issues

**Symptoms**: Slow API responses, cache misses

**Diagnosis**:

```bash
# Test Redis connection
docker exec -it muchtodo-api sh
nc -zv <redis-endpoint> 6379
```

**Solutions**:

- Check ElastiCache cluster status
- Verify security group allows EC2 → ElastiCache traffic (port 6379)
- Check Redis endpoint in environment variables

---

## Rollback Procedures

### Frontend Rollback

**Option 1: Using Script**

```bash
./scripts/rollback.sh frontend production
```

**Option 2: Manual S3 Versioning**

```bash
# List versions
aws s3api list-object-versions --bucket <bucket-name> --prefix index.html

# Restore previous version
aws s3api copy-object \
  --copy-source <bucket-name>/index.html?versionId=<version-id> \
  --bucket <bucket-name> \
  --key index.html

# Invalidate cache
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

**Prerequisite**: Enable S3 versioning

```bash
aws s3api put-bucket-versioning \
  --bucket <bucket-name> \
  --versioning-configuration Status=Enabled
```

### Backend Rollback

**Option 1: Using Script**

```bash
./scripts/rollback.sh backend production <deployment-id>
# If deployment-id is omitted, script finds last successful deployment
```

**Option 2: Manual CodeDeploy**

```bash
# Find last successful deployment
aws deploy list-deployments \
  --application-name <app-name> \
  --deployment-group-name <group-name> \
  --include-only-statuses Succeeded \
  --max-items 2

# Get deployment revision
aws deploy get-deployment --deployment-id <previous-deployment-id>

# Create rollback deployment
aws deploy create-deployment \
  --application-name <app-name> \
  --deployment-group-name <group-name> \
  --revision <previous-revision-json> \
  --description "Rollback to <deployment-id>"
```

**Option 3: ECR Image Rollback**

```bash
# List ECR images
aws ecr describe-images --repository-name <repo-name> --query 'sort_by(imageDetails,& imagePushedAt)[-5:]'

# Retag previous image as latest
aws ecr batch-get-image --repository-name <repo-name> --image-ids imageTag=<previous-tag> \
  --query 'images[0].imageManifest' --output text | \
  aws ecr put-image --repository-name <repo-name> --image-tag latest --image-manifest file:///dev/stdin

# Trigger new deployment or restart instances
```

### Emergency Stop

**Stop Ongoing Deployment**:

```bash
aws deploy stop-deployment \
  --deployment-id <deployment-id> \
  --auto-rollback-enabled
```

---

## Emergency Contacts

### Team Contacts

- **DevOps Lead**: devops@starttech.com
- **Backend Team**: backend@starttech.com
- **Frontend Team**: frontend@starttech.com
- **On-Call**: oncall@starttech.com

### Escalation

1. **L1**: DevOps Engineer (15 min response)
2. **L2**: Senior DevOps / Team Lead (30 min response)
3. **L3**: CTO / Engineering Director (1 hour response)

### External Services

- **AWS Support**: https://console.aws.amazon.com/support/
- **MongoDB Atlas Support**: https://cloud.mongodb.com/support
- **GitHub Support**: https://support.github.com/

---

## Best Practices

### Pre-Deployment Checklist

- [ ] All tests passing locally
- [ ] Code reviewed and approved
- [ ] Feature flags configured (if applicable)
- [ ] Database migrations tested
- [ ] Backup verification (MongoDB, Redis)
- [ ] Monitoring dashboards checked
- [ ] Rollback plan documented

### Post-Deployment Checklist

- [ ] Health checks passing
- [ ] CloudWatch alarms normal
- [ ] Application metrics normal
- [ ] Error rates within threshold
- [ ] User acceptance testing passed
- [ ] Documentation updated

### Security

- [ ] Never commit secrets to Git
- [ ] Use AWS Secrets Manager or SSM Parameter Store
- [ ] Rotate credentials regularly
- [ ] Enable MFA for AWS console access
- [ ] Review IAM policies for least privilege
- [ ] Monitor CloudTrail logs

---

## Additional Resources

- **Infrastructure Repository**: https://github.com/<org>/starttech-infra
- **Architecture Diagram**: See ARCHITECTURE.md
- **API Documentation**: https://api.muchtodo.com/swagger/index.html
- **Terraform Docs**: See starttech-infra/terraform/README.md

---

**Last Updated**: 2026-01-25
**Version**: 1.0.0
