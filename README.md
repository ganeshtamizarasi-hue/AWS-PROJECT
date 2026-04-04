# AWS WordPress HA + DR Project

## Architecture
![Architecture Diagram](architecture/diagram.png)

## Tech Stack
| Category       | Tools |
|----------------|-------|
| Cloud          | VPC, EC2, RDS MySQL, EFS, ALB, ASG, S3, CloudFront, Route53, ACM |
| Security       | Secrets Manager, IAM, Private Subnets, SG Chaining, HTTPS |
| IaC            | Terraform (remote state in S3) |
| Containers     | Docker, Amazon ECR |
| CI/CD          | CodePipeline + CodeBuild + CodeDeploy (Blue/Green) |
| Monitoring     | CloudWatch Metrics + Alarms |

## CI/CD Pipeline Flow
```
Developer pushes code to GitHub
        ↓
AWS CodePipeline triggers automatically
        ↓
CodeBuild Stage:
  - terraform apply  (infrastructure update)
  - docker build     (build WordPress image)
  - docker push      (push to ECR)
        ↓
CodeDeploy Blue/Green Deployment:
  - Green instances launched from ASG copy
  - Latest Docker image pulled from ECR
  - Container started with secrets from Secrets Manager
        ↓
Validation Phase:
  - validate.sh checks /healthy.html via ALB
  - If FAILED → auto rollback to Blue ✅
        ↓
Traffic Shift:
  - ALB routes traffic Blue → Green ✅
        ↓
Blue instances terminated after 5 mins
        ↓
https://ganeshc.shop live ✅
```

## Security — No Hardcoded Credentials
```
terraform.tfvars   → EC2 only, never pushed to GitHub (.gitignore)
Secrets Manager    → RDS creds fetched by Docker at runtime
IAM Roles          → EC2/CodeBuild access via roles, not keys
```

## Project Structure
```
├── terraform/
│   ├── main.tf            # Provider + S3 backend
│   ├── variables.tf       # All variables
│   ├── terraform.tfvars   # Secrets — NEVER pushed to GitHub
│   ├── vpc.tf             # VPC, subnets, IGW, NAT
│   ├── sg.tf              # Security groups
│   ├── rds.tf             # MySQL RDS
│   ├── secrets.tf         # Secrets Manager
│   ├── efs.tf             # EFS shared storage
│   ├── ecr.tf             # ECR repository
│   ├── iam.tf             # All IAM roles
│   ├── alb.tf             # ALB + Blue/Green target groups
│   ├── asg.tf             # Launch template + ASG
│   ├── codepipeline.tf    # Full CI/CD pipeline
│   ├── s3.tf              # S3 + CloudFront DR
│   └── outputs.tf
├── docker/
│   └── Dockerfile         # WordPress Docker image
├── cicd/
│   ├── buildspec.yml      # CodeBuild instructions
│   ├── appspec.yml        # CodeDeploy Blue/Green hooks
│   └── scripts/           # Deployment lifecycle scripts
├── scripts/
│   ├── user-data.sh       # EC2 bootstrap
│   └── docker-entrypoint.sh
├── .gitignore             # Blocks tfvars + sensitive files
└── README.md
```

## How to Deploy

### Step 1 — Create GitHub Connection
```
AWS Console → CodePipeline → Settings → Connections
→ Create connection → GitHub → Authorize → Copy ARN
```

### Step 2 — Fill terraform.tfvars
```hcl
db_password                   = "your-password"
acm_certificate_arn           = "arn:aws:acm:ap-south-1:..."
acm_certificate_arn_us_east_1 = "arn:aws:acm:us-east-1:..."
github_connection_arn         = "arn:aws:codestar-connections:..."
github_repo                   = "username/repo-name"
```

### Step 3 — Run Terraform
```bash
cd terraform/
terraform init
terraform apply
# Type yes
```

### Step 4 — Push Code to Trigger Pipeline
```bash
git add .
git commit -m "trigger pipeline"
git push origin main
```

## Live URLs
- Production : https://ganeshc.shop
- DR Site    : https://dr.ganeshc.shop
