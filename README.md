# 🚀 AWS WordPress — Production Blue/Green Deployment

> A fully production-grade WordPress deployment on AWS with Blue/Green CI/CD, Docker, EFS shared storage, RDS MySQL, CloudFront DR, and full Infrastructure-as-Code via Terraform.

[![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-ap--south--1-FF9900?logo=amazonaws)](https://aws.amazon.com/)
[![Docker](https://img.shields.io/badge/Docker-ECR-2496ED?logo=docker)](https://aws.amazon.com/ecr/)
[![WordPress](https://img.shields.io/badge/WordPress-Latest-21759B?logo=wordpress)](https://wordpress.org/)

---

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [AWS Services Used](#aws-services-used)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup](#step-by-step-setup)
  - [1. AWS Certificate Manager](#1-aws-certificate-manager)
  - [2. Route 53 & Domain Setup](#2-route-53--domain-setup)
  - [3. Setup Tools on EC2](#3-setup-tools-on-ec2)
  - [4. Create S3 State Bucket](#4-create-s3-state-bucket)
  - [5. Clone Repository via SSH](#5-clone-repository-via-ssh)
  - [6. Get GitHub Connection ARN](#6-get-github-connection-arn)
  - [7. Configure terraform.tfvars](#7-configure-terraformtfvars)
  - [8. Run Terraform](#8-run-terraform)
  - [9. Build & Push Docker Image to ECR](#9-build--push-docker-image-to-ecr)
  - [10. Install CodeDeploy Agent on EC2](#10-install-codedeploy-agent-on-ec2)
  - [11. Trigger the CI/CD Pipeline](#11-trigger-the-cicd-pipeline)
- [CI/CD Pipeline Flow](#cicd-pipeline-flow)
- [Blue/Green Deployment Strategy](#bluegreen-deployment-strategy)
- [Testing & Validation](#testing--validation)
- [Disaster Recovery](#disaster-recovery)
- [Security Design](#security-design)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
Internet / Users
      │
      ├──────────────────────────────┐
      ▼                              ▼
Route 53 (ganeshc.shop)        CloudFront (dr.ganeshc.shop)
   + ACM SSL                        │ (DR via S3)
      │                             │
      ▼                             │
Application Load Balancer ◄─────────┘
  (HTTPS :443, ap-south-1)
      │
  ┌───┴───┐
  ▼       ▼
Blue TG  Green TG   ← CodeDeploy switches traffic
  │         │
EC2 (Blue) EC2 (Green)   ← Auto Scaling Group
  │   │        │
  │   └────────┘
  ├── RDS MySQL (prod-wordpress-db)
  ├── EFS (shared wp-content)
  ├── ECR (Docker image)
  └── Secrets Manager (DB credentials)

CI/CD Pipeline:
  GitHub → CodeBuild → ECR → CodeDeploy → ASG
                  ↑
           S3 (Terraform state + artifacts)
```

---

## Project Structure

```
AWS-PROJECT/
│
├── .gitignore                          # Blocks tfvars from GitHub
├── README.md                           # This file
│
├── terraform/
│   ├── main.tf                         # Provider + S3 backend
│   ├── variables.tf                    # All input variables
│   ├── terraform.tfvars                # ⚠️ Secrets — never push this
│   ├── vpc.tf                          # VPC, subnets, IGW, NAT Gateway
│   ├── sg.tf                           # 4 Security Groups
│   ├── rds.tf                          # MySQL RDS instance
│   ├── secrets.tf                      # Secrets Manager
│   ├── efs.tf                          # EFS shared storage
│   ├── ecr.tf                          # Docker image registry
│   ├── iam.tf                          # EC2 + CodeBuild + Pipeline + Deploy roles
│   ├── alb.tf                          # ALB + Blue/Green target groups
│   ├── asg.tf                          # Launch Template + ASG + CloudWatch
│   ├── codepipeline.tf                 # Full CI/CD pipeline
│   ├── s3.tf                           # Backups + CloudFront DR
│   └── outputs.tf                      # Output values
│
├── docker/
│   └── Dockerfile                      # WordPress Docker image
│
├── cicd/
│   ├── buildspec.yml                   # Terraform + Docker + ECR push
│   ├── appspec.yml                     # Blue/Green lifecycle hooks
│   └── scripts/
│       ├── before_install.sh           # Docker install + ECR login
│       ├── after_install.sh            # Pull image + run container
│       ├── validate.sh                 # Health check → rollback on fail
│       └── after_allow_traffic.sh      # Log after traffic shifts
│
└── scripts/
    ├── user-data.sh                    # EC2 bootstrap on first boot
    └── docker-entrypoint.sh           # Fetches secrets + starts WordPress
```

---

## AWS Services Used

| Service | Purpose |
|---|---|
| **VPC** | Isolated network with public + private subnets |
| **EC2 + ASG** | WordPress app servers with Auto Scaling |
| **ALB** | HTTPS load balancer, SSL termination |
| **RDS MySQL** | Managed database in private subnet |
| **EFS** | Shared `wp-content` across all EC2 instances |
| **ECR** | Private Docker image registry |
| **Secrets Manager** | Secure DB credentials at runtime |
| **CodePipeline** | Full CI/CD orchestration |
| **CodeBuild** | Builds Docker image + pushes to ECR |
| **CodeDeploy** | Blue/Green traffic switch with rollback |
| **CloudFront** | CDN + Disaster Recovery site |
| **Route 53** | DNS management |
| **ACM** | Free managed SSL certificates |
| **S3** | Terraform state + pipeline artifacts + DR backup |
| **IAM** | Fine-grained roles for every service |
| **SSM** | Parameter Store + session manager access |
| **CloudWatch** | Logs, metrics, and alarms |

---

## Prerequisites

- AWS account with admin access
- Registered domain (this project uses `ganeshc.shop` via Hostinger)
- GitHub account + repository
- EC2 instance (used as jump box / admin server) — Ubuntu recommended

---

## Step-by-Step Setup

### 1. AWS Certificate Manager

Request public certificates for both domains:

- `ganeshc.shop` — main production domain
- `dr.ganeshc.shop` — disaster recovery domain

> **Note:** The DR certificate must be in `us-east-1` (required for CloudFront).

```
AWS Console → Certificate Manager
→ Request public certificate
→ Add domain names: ganeshc.shop and *.ganeshc.shop
→ DNS validation → Create records in Route 53 ✅
```

---

### 2. Route 53 & Domain Setup

```bash
# 1. Create hosted zone in Route 53
#    AWS Console → Route 53 → Create Hosted Zone → ganeshc.shop

# 2. Copy the 4 Name Server (NS) records from Route 53
# 3. Go to Hostinger → Domain DNS Management
#    Replace default NS records with the Route 53 NS records

# 4. Validate ACM by creating the CNAME records Route 53 shows you
#    (Route 53 can do this automatically — click "Create records in Route 53")
```

---

### 3. Setup Tools on EC2

```bash
sudo su -
apt update -y
apt install -y git curl wget jq unzip

# Install Terraform
wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update -y && apt install -y terraform

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && ./aws/install

# Verify
terraform --version
aws --version
```

---

### 4. Create S3 State Bucket

```bash
# Configure AWS CLI (create an IAM user with S3 + EC2 access first)
aws configure
# Enter: Access Key, Secret Key, Region (ap-south-1), Output (json)

aws sts get-caller-identity  # Verify

# Create versioned S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket ganeshc-terraform-state \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket ganeshc-terraform-state \
  --versioning-configuration Status=Enabled

echo "S3 state bucket ready ✅"
```

---

### 5. Clone Repository via SSH

```bash
git config --global user.name "ganeshtamizarasi-hue"
git config --global user.email "ganeshtamizarasi@gmail.com"

# Generate SSH key
ssh-keygen -t ed25519 -C "ganeshtamizarasi@gmail.com"
cat ~/.ssh/id_ed25519.pub   # Copy this output

# Add to GitHub:
# GitHub → Settings → SSH and GPG keys → New SSH key → Paste → Save

git clone git@github.com:ganeshtamizarasi-hue/AWS-PROJECT.git
cd AWS-PROJECT && find . -type f | grep -v .git   # Verify all files
```

---

### 6. Get GitHub Connection ARN

```
AWS Console → CodePipeline → Settings (left menu)
→ Connections → Create connection
  Provider : GitHub
  Name     : github-connection
→ Connect to GitHub → Authorize ✅
→ Click connection name → Copy the ARN
```

Example ARN format:
```
arn:aws:codeconnections:ap-south-1:145400477094:connection/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

### 7. Configure terraform.tfvars

```bash
cd ~/AWS-PROJECT/terraform
nano terraform.tfvars
```

```hcl
db_password = "your-secure-password"

acm_certificate_arn = "arn:aws:acm:ap-south-1:ACCOUNT_ID:certificate/YOUR_CERT_ID"

acm_certificate_arn_us_east_1 = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/YOUR_US_EAST_CERT_ID"

github_connection_arn = "arn:aws:codeconnections:ap-south-1:ACCOUNT_ID:connection/YOUR_CONNECTION_ID"

github_repo = "ganeshtamizarasi-hue/AWS-PROJECT"
```

> ⚠️ This file is in `.gitignore` — never push it to GitHub.

---

### 8. Run Terraform

```bash
cd ~/AWS-PROJECT/terraform

terraform init     # Download providers + configure S3 backend
terraform plan     # Preview all resources to be created
terraform apply    # Apply (type: yes when prompted)
```

⏳ Takes **10–15 minutes** to provision all resources.

Expected outputs:
```
alb_dns_name  = "prod-alb-xxx.ap-south-1.elb.amazonaws.com"
ecr_repo_url  = "145400477094.dkr.ecr.ap-south-1.amazonaws.com/prod-wordpress"
pipeline_name = "wordpress-prod-pipeline"
```

---

### 9. Build & Push Docker Image to ECR

```bash
# Install Docker
apt install -y docker.io
systemctl start docker && systemctl enable docker

# Set variables
ECR_URL="145400477094.dkr.ecr.ap-south-1.amazonaws.com/prod-wordpress"
REGION="ap-south-1"

# Login to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_URL

# Build, tag, and push
cd ~/AWS-PROJECT
docker build -t wordpress-app -f docker/Dockerfile .
docker tag wordpress-app:latest $ECR_URL:latest
docker push $ECR_URL:latest

# Verify
aws ecr list-images --repository-name prod-wordpress --region $REGION
```

---

### 10. Install CodeDeploy Agent on EC2

```bash
apt install -y ruby-full wget
cd /home/ubuntu

wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install && ./install auto

systemctl start codedeploy-agent
systemctl enable codedeploy-agent
systemctl status codedeploy-agent   # Should show: active (running) ✅
```

---

### 11. Trigger the CI/CD Pipeline

```bash
cd ~/AWS-PROJECT
git add .
git commit -m "Initial deployment — Terraform + Docker + CI/CD"
git push origin main
```

Watch the pipeline in AWS Console:
```
CodePipeline → wordpress-prod-pipeline

Stage 1: Source   → ✅ GitHub pulled
Stage 2: Build    → ✅ Terraform + Docker + ECR push
Stage 3: Deploy   → ✅ Blue/Green deployment via CodeDeploy
```

⏳ Full pipeline run takes **10–15 minutes**.

---

## CI/CD Pipeline Flow

```
git push origin main
        │
        ▼
CodePipeline triggered (via CodeConnections)
        │
        ▼
CodeBuild (buildspec.yml)
  ├── terraform init + apply
  ├── docker build
  └── docker push → ECR
        │
        ▼
CodeDeploy (appspec.yml)
  ├── before_install.sh   → Install Docker, ECR login
  ├── after_install.sh    → Pull image, run container
  ├── validate.sh         → Health check — rollback if failed
  └── after_allow_traffic.sh → Log traffic shift complete
        │
        ▼
ALB shifts traffic: Blue ──► Green
Old Blue instances terminated ✅
```

---

## Blue/Green Deployment Strategy

| Stage | Action |
|---|---|
| **1. Green provisioned** | CodeDeploy launches new Green EC2 instances |
| **2. App deployed** | Docker image pulled from ECR, container started |
| **3. Health check** | `validate.sh` hits `/healthy.html` — must return 200 |
| **4. Traffic shift** | ALB listener rule updated: Blue TG → Green TG |
| **5. Rollback** | If validate.sh fails, CodeDeploy auto-reverts to Blue |
| **6. Cleanup** | Old Blue instances terminated after configurable wait |

**Key Terraform configuration for IMDSv2 + Docker on AL2023:**

```hcl
# asg.tf — Launch Template metadata options
metadata_options {
  http_endpoint               = "enabled"
  http_tokens                 = "required"   # IMDSv2 enforced
  http_put_response_hop_limit = 2            # Required for Docker containers
}
```

> ⚠️ `http_put_response_hop_limit = 2` is critical. Without it, Docker containers cannot reach IMDS and ECR login fails silently on AL2023.

---

## Testing & Validation

```bash
# Test 1 — Health check via ALB DNS
curl http://<alb-dns-name>/healthy.html
# Expected: healthy ✅

# Test 2 — Production site
open https://ganeshc.shop
# Expected: WordPress setup page ✅

# Test 3 — DR site
open https://dr.ganeshc.shop
# Expected: CloudFront DR site ✅

# Test 4 — Trigger Blue/Green
echo "<!-- v2 -->" >> README.md
git add . && git commit -m "Test Blue/Green v2" && git push origin main
# Watch CodePipeline → CodeDeploy → traffic shift ✅
```

**Verify in AWS Console:**

| Resource | Location | Expected Status |
|---|---|---|
| VPC | EC2 → VPC | prod-vpc |
| RDS | RDS console | available |
| Secrets Manager | Secrets Manager | wordpress-db-secret |
| EFS | EFS console | prod-wordpress-efs |
| ECR | ECR console | image visible |
| ALB | EC2 → Load Balancers | active |
| Target Groups | EC2 → Target Groups | prod-blue-tg + prod-green-tg — Healthy |
| Pipeline | CodePipeline | wordpress-prod-pipeline |

---

## Disaster Recovery

CloudFront is configured to serve `dr.ganeshc.shop` from an S3 bucket with a static WordPress snapshot. This provides read-only access to the site even if the primary region or EC2/RDS layer is unavailable.

DR flow:
```
dr.ganeshc.shop → CloudFront distribution → S3 bucket (static backup)
```

To update the DR snapshot, run the backup script or push to the S3 bucket configured in `s3.tf`.

---

## Security Design

| Layer | Control |
|---|---|
| **Network** | EC2 in private subnets — no direct internet access |
| **Access** | ALB only in public subnet — EC2 not directly reachable |
| **Credentials** | Secrets Manager for DB password — never in env vars or code |
| **IMDSv2** | Enforced on all EC2 via Launch Template — prevents SSRF attacks |
| **SSL/TLS** | ACM certificates — HTTPS enforced on ALB |
| **IAM** | Least-privilege roles per service (CodeBuild, CodeDeploy, EC2) |
| **State** | Terraform state in versioned, private S3 bucket |
| **Secrets** | `terraform.tfvars` in `.gitignore` — never pushed |

---

## Troubleshooting

**CodeDeploy fails at `before_install.sh` — ECR login error**

Cause: IMDSv2 hop limit is 1 (default). Docker containers can't reach IMDS.

Fix in `asg.tf`:
```hcl
metadata_options {
  http_tokens                 = "required"
  http_put_response_hop_limit = 2
}
```
Then: `terraform apply` → terminate old instances → let ASG launch fresh ones.

---

**Target group shows instances as Unhealthy**

1. Check security group: ALB SG must allow traffic to EC2 SG on port 80/443.
2. Check `/healthy.html` exists and returns 200 from inside the container.
3. Check `user-data.sh` completed successfully: `cat /var/log/cloud-init-output.log`

---

**Terraform state lock error**

```bash
terraform force-unlock <LOCK_ID>
```

---

**Docker cannot pull from ECR on EC2**

```bash
# Manually test IMDSv2
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/
```
If empty → IMDSv2 hop limit issue. Set `http_put_response_hop_limit = 2`.

---

## Author

**Ganesh Tamizarasi**
- GitHub: [@ganeshtamizarasi-hue](https://github.com/ganeshtamizarasi-hue)
- Region: ap-south-1 (Mumbai)

---

> Built with Terraform · Docker · AWS CodePipeline · WordPress · ❤️
