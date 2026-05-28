# StartTech Much ToDo - Operations & Support Runbook

This runbook is a reference for on-call engineers, DevOps staff, and system administrators managing the StartTech Full-Stack environment.

---

## 1. Troubleshooting Application Logs

### CloudWatch Logs Analysis
All API logs are sent to the AWS CloudWatch Log Group: `/aws/ec2/starttech-backend-prod`.
Logs are formatted in structured JSON.

To search logs using the **AWS Console**:
1. Open CloudWatch -> Logs Insights.
2. Select the Log Group `/aws/ec2/starttech-backend-prod`.
3. To view the latest errors, run:
   ```text
   fields @timestamp, @message, msg, error
   | filter level = 'ERROR'
   | sort @timestamp desc
   | limit 50
   ```

---

## 2. Remote Access to EC2 Instances

For security, backend nodes and databases reside in private subnets. They cannot be reached directly over the public internet.

### Option A: Using the Bastion Host (SSH Gateway)
1. Add your SSH Private Key to your SSH agent locally:
   ```bash
   ssh-add /path/to/starttech-keypair.pem
   ```
2. Connect to the private MongoDB EC2 or Backend nodes using the Bastion Host public IP as a jump host:
   ```bash
   ssh -A -J ec2-user@<BASTION_PUBLIC_IP> ec2-user@<MONGO_PRIVATE_IP>
   ```

### Option B: Using AWS Systems Manager (SSM) Session Manager
If SSM Agent is running and the instance IAM role permits it:
```bash
aws ssm start-session --target <INSTANCE_ID>
```

---

## 3. Dynamic Scaling Operations

The Auto Scaling Group (ASG) scales dynamically based on CPU utilization, but can be resized manually if traffic spikes are expected (e.g., scheduled marketing campaigns).

### Manually Adjusting ASG Capacity
To change the active instance count, adjust the desired capacity of the ASG:
```bash
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name techcorp-backend-asg-prod \
  --min-size 2 \
  --max-size 5 \
  --desired-capacity 3 \
  --region us-east-1
```

---

## 4. Database Backup & Restore (MongoDB)

Our MongoDB instance runs in a docker container on an EC2 instance in a private subnet.

### 4.1 Running a Manual Backup (Dump)
1. SSH into the MongoDB EC2 instance via the Bastion Host.
2. Execute a backup using `mongodump` inside the docker container:
   ```bash
   docker exec -it mongodb mongodump \
     --username root \
     --password "Password!234" \
     --authenticationDatabase admin \
     --db much_todo_db \
     --out /data/db/backups/dump-$(date +%F)
   ```
3. Backups are stored on the EC2 host mount at `/var/lib/mongodb/backups/`.

### 4.2 Restoring from a Backup
To restore a dump file back into the database:
```bash
docker exec -it mongodb mongorestore \
  --username root \
  --password "Password!234" \
  --authenticationDatabase admin \
  --db much_todo_db \
  /data/db/backups/dump-<DATE>/much_todo_db
```

---

## 5. Rollback Procedure

If a deployment fails the automated health checks, or if bugs are discovered post-release:

1. Locate the last stable Docker image tag (commit hash) from GitHub history or the SSM Parameter history.
2. Run the rollback script from the root of the `starttech-application` repository:
   ```bash
   # Usage: ./scripts/rollback.sh <component> <target-tag>
   ./scripts/rollback.sh backend abc123def456
   ```
3. The script will rewrite the current SSM parameter `/starttech/backend/image_tag` to the specified tag and trigger a rolling ASG Instance Refresh.
4. Verify deployment health:
   ```bash
   ./scripts/health-check.sh "http://<ALB_DNS_NAME>"
   ```
5. If the rollback was triggered by a bad merge, make sure to revert the merge commit in Git.
