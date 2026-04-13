# 📸 Screenshots — AWS Console Verification

> All resources provisioned in **ap-south-1 (Mumbai)** via Terraform.

---

## 1. 🌐 Route 53 — Hosted Zone
<img width="979" height="423" alt="image" src="https://github.com/user-attachments/assets/195d08ab-6f93-4a32-ba16-b169caa1d875" />

> Hosted zone created for `ganeshc.shop` with NS records mapped to Hostinger DNS.


## 2. 🔒 ACM — SSL Certificates

![ACM Certificates](screenshots/02-acm-certificates.png)

> Public certificates issued for `ganeshc.shop` and `dr.ganeshc.shop` — status: **Issued ✅**

---

## 3. 🏗️ VPC — Network Setup

![VPC](screenshots/03-vpc.png)

> `prod-vpc` created with CIDR block, public and private subnets across availability zones.

---

## 4. 🔀 Subnets

![Subnets](screenshots/04-subnets.png)

> Public subnets (for ALB) and private subnets (for EC2 + RDS) configured across multiple AZs.

---

## 5. 🛡️ Security Groups

![Security Groups](screenshots/05-security-groups.png)

> 4 security groups created — ALB, EC2, RDS, and EFS — with least-privilege inbound/outbound rules.

---

## 6. 🗄️ RDS — MySQL Database

![RDS Instance](screenshots/06-rds.png)

> `prod-wordpress-db` MySQL instance running in private subnet — status: **Available ✅**

---

## 7. 🔑 Secrets Manager

![Secrets Manager](screenshots/07-secrets-manager.png)

> `wordpress-db-secret` storing DB credentials — retrieved at runtime by the Docker container.

---

## 8. 📁 EFS — Shared Storage

![EFS](screenshots/08-efs.png)

> `prod-wordpress-efs` mounted across all EC2 instances to share `wp-content` (uploads, plugins, themes).

---

## 9. 🐳 ECR — Docker Image Registry

![ECR Repository](screenshots/09-ecr-repository.png)

> `prod-wordpress` repository with the latest WordPress Docker image pushed successfully.

---

## 10. 🐳 ECR — Image Details

![ECR Image](screenshots/10-ecr-image.png)

> Docker image tagged as `latest` — pushed from EC2 via `docker push`.

---

## 11. ⚖️ ALB — Application Load Balancer

![ALB](screenshots/11-alb.png)

> `prod-alb` active in public subnets — HTTPS listener on port 443 with ACM certificate attached.

---

## 12. 🎯 Target Groups — Blue & Green

![Target Groups](screenshots/12-target-groups.png)

> `prod-blue-tg` and `prod-green-tg` both created — ready for Blue/Green traffic switching.

---

## 13. 💚 Target Group — Healthy Instances

![Target Group Healthy](screenshots/13-target-group-healthy.png)

> EC2 instances registered and showing **Healthy** status in the active target group ✅

---

## 14. 📈 Auto Scaling Group

![ASG](screenshots/14-asg.png)

> `prod-wordpress-asg` configured with Launch Template (AL2023, IMDSv2, Docker) — min/max/desired capacity set.

---

## 15. 🚀 EC2 Instances — Running

![EC2 Instances](screenshots/15-ec2-instances.png)

> EC2 instances launched by ASG in private subnets — running WordPress Docker container.

---

## 16. 🔧 IAM Roles

![IAM Roles](screenshots/16-iam-roles.png)

> Least-privilege IAM roles created for EC2, CodeBuild, CodeDeploy, and CodePipeline.

---

## 17. 🪣 S3 — Terraform State Bucket

![S3 Bucket](screenshots/17-s3-bucket.png)

> `ganeshc-terraform-state` with versioning enabled — stores Terraform state securely.

---

## 18. ⚙️ CodePipeline — Pipeline Overview

![CodePipeline](screenshots/18-codepipeline.png)

> `wordpress-prod-pipeline` with 3 stages: Source (GitHub) → Build (CodeBuild) → Deploy (CodeDeploy).

---

## 19. 🏗️ CodeBuild — Build Success

![CodeBuild](screenshots/19-codebuild-success.png)

> Docker image built and pushed to ECR successfully — all build phases passed ✅

---

## 20. 🔵🟢 CodeDeploy — Blue/Green Deployment

![CodeDeploy](screenshots/20-codedeploy-bluegreen.png)

> Blue/Green deployment completed — traffic shifted from Blue to Green, old instances terminated ✅

---

## 🌐 WordPress — Live Site

![WordPress Live](screenshots/21-wordpress-live.png)

> `https://ganeshc.shop` live and serving WordPress via ALB + EC2 + RDS ✅

---

> ☁️ CloudFront DR setup (`dr.ganeshc.shop`) — screenshot coming soon
