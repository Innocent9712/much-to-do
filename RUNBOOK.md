# Operations and Troubleshooting Runbook

This runbook contains operational guides, incident playbooks, and troubleshooting procedures for the **StartTech** full-stack production application.

---

## 🚨 Incident Playbooks

### Playbook 1: High CPU Utilization on EC2 Backend Instances
**Symptom**: CloudWatch alarm `HighCPUUtilization` triggers (CPU exceeds 80% for 5 consecutive minutes).
1. **Analyze Metrics**:
   - Access the CloudWatch Dashboard to check the Auto Scaling Group CPU metrics and target group healthy host count.
2. **Review Application Logs**:
   - Run a CloudWatch Logs Insights query to find heavy requests:
     ```text
     fields @timestamp, @message
     | filter @message like /error/ or @message like /panic/
     | sort @timestamp desc
     | limit 100
     ```
3. **Action**:
   - If the load is due to organic traffic, let the Auto Scaling Target Tracking policy scale out the instances.
   - If a single instance is misbehaving, terminate it manually to force ASG to provision a fresh, healthy instance:
     ```bash
     aws ec2 terminate-instances --instance-ids <instance-id>
     ```

### Playbook 2: Application Load Balancer returning HTTP 502/504 Bad Gateway
**Symptom**: Users receive 502 or 504 errors on API endpoints.
1. **Check Target Health**:
   - Check the health status of target group instances:
     ```bash
     aws elbv2 describe-target-health --target-group-arn <target-group-arn>
     ```
2. **Investigate EC2 Instance Processes**:
   - SSH into a private instance via a bastion host and check if the backend Docker container is running:
     ```bash
     docker ps -a
     ```
   - Check container resource constraints and system logs:
     ```bash
     docker logs starttech-backend
     ```
3. **Resolution**:
   - If the container crashed, restart it:
     ```bash
     docker restart starttech-backend
     ```
   - If it is locked due to memory leaks, trigger a manual rolling refresh:
     ```bash
     export ECR_REPOSITORY="839026370596.dkr.ecr.us-east-1.amazonaws.com/starttech-production-backend"
     export ASG_NAME="starttech-production-asg"
     sudo -E bash ./scripts/deploy-backend.sh
     ```

### Playbook 3: MongoDB Atlas / Redis Connection Failures
**Symptom**: Application logs show `could not connect to MongoDB` or `Redis connection refused
**Symptom**: Application logs show `could not connect to MongoDB` or `Redis connection refused`
1. **Verify Database Credentials**:
   - Check that `MONGO_URI` or `REDIS_ADDR` environment variables mapped to the EC2 instances are accurate.
2. **Test Network Path**:
   - From an EC2 backend instance, test connectivity to Redis (port 6379) and MongoDB Atlas (port 27017):
     ```bash
     nc -zv <redis-endpoint> 6379
     nc -zv <atlas-shard-host> 27017
     ```
3. **Resolution**:
   - If network tests fail, verify the Security Group rules for ElastiCache and ensure that MongoDB Atlas Network Access lists allow the NAT Gateway IPs of your VPC.

---

## 🛠️ Operational Procedures

### Procedure 1: Emergency Application Rollbacks

#### Rolling Back Backend Deployments
If a backend deployment introduces bugs, execute the rollback script immediately. The script automatically cancels any in-progress instance refresh, locates the previous stable AWS Launch Template version, and triggers a rolling replacement:
```bash
export ASG_NAME="starttech-production-asg"
./scripts/rollback.sh
```

#### Rolling Back Frontend Deployments
To roll back a faulty frontend build:
1. Identify the previous stable GitHub workflow run.
2. Re-run that workflow's `deploy` job, OR download the stable artifact and sync manually:
   ```bash
   aws s3 sync stable-dist/ s3://starttech-production-frontend --delete
   aws cloudfront create-invalidation --distribution-id <cf-id> --paths "/*"
   ```

### Procedure 2: Vulnerability Remediation & Patching

#### Patching Operating Systems (EC2 AL2023)
The backend uses standard Amazon Linux 2023. When security updates are released:
1. Update the Launch Template with the latest AL2023 AMI.
2. Run an instance refresh on the ASG to rotate old instances with fresh, patched ones:
   ```bash
   aws autoscaling start-instance-refresh \
     --auto-scaling-group-name starttech-production-asg \
     --strategy Rolling
   ```

#### Remediating Go & Node Vulnerabilities
- For **Backend** (Trivy scans):
  - Run `go get -u ./...` and `go mod tidy` in the `backend` folder to update packages to secure versions.
- For **Frontend** (NPM Audit):
  - Run `npm audit fix` in the `frontend` folder to automatically apply minor patches to Node modules.

### Procedure 3: Manual Application Deployments
If automated CI/CD pipelines in GitHub Actions are unavailable, you can perform manual deployments directly from your management terminal using environment variables to specify parameters.

#### Manually Deploying the Backend
Build and push the Go backend Docker container to ECR, then trigger a rolling update of the Auto Scaling Group:
```bash
export ECR_REPOSITORY="839026370596.dkr.ecr.us-east-1.amazonaws.com/starttech-production-backend"
export ASG_NAME="starttech-production-asg"

sudo -E bash ./scripts/deploy-backend.sh
```

#### Manually Deploying the Frontend
Compile the React/Vite production assets and deploy them directly to the S3 bucket, then invalidate the CloudFront CDN cache:
```bash
export FRONTEND_S3_BUCKET="starttech-production-frontend-839026370596"
export ALB_DNS_NAME="starttech-production-alb-427884223.us-east-1.elb.amazonaws.com"

sudo -E bash ./scripts/deploy-frontend.sh
```

---

## 📊 Centralized Log Analysis Queries
Use **CloudWatch Logs Insights** for structured analysis of backend application logs.

### Query 1: Top 20 Slowest Requests
```text
filter @message like /duration/
| parse @message "* duration=*" as request, duration
| sort duration desc
| limit 20
```

### Query 2: Error Rate Over Time
```text
filter @message like /error/ or @message like /panic/
| stats count() by bin(1h)
| sort @timestamp desc
```
