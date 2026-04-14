# 📸 Screenshots — AWS Console Verification

> All resources provisioned in **ap-south-1 (Mumbai)** via Terraform.

---

## 1. 🌐 Route 53 — Hosted Zone
<img width="979" height="423" alt="image" src="https://github.com/user-attachments/assets/195d08ab-6f93-4a32-ba16-b169caa1d875" />

> Hosted zone created for `ganeshc.shop` with NS records mapped to Hostinger DNS.


## 2. 🔒 ACM — SSL Certificates

### Certificate Issued — ap-south-1

<img width="979" height="341" alt="image" src="https://github.com/user-attachments/assets/38518e60-7a4e-40ed-91e1-f82638ea017e" />

### Certificate Issued — us-east-1 (CloudFront)

<img width="979" height="250" alt="image" src="https://github.com/user-attachments/assets/3aff8bb3-2118-4bf7-be33-435e1a19a7ca" />

> Public certificates issued for `ganeshc.shop` and `dr.ganeshc.shop` — status: **Issued ✅**

---

## 3. 🏗️ VPC — Network Setup
### VPC Created — prod-vpc
<img width="979" height="268" alt="image" src="https://github.com/user-attachments/assets/59595700-1eae-4004-8167-8c7a5edeed70" />
### Route Tables
<img width="979" height="315" alt="image" src="https://github.com/user-attachments/assets/9887bdd0-a4e6-4b95-99da-4f14b717ad77" />
### Internet Gateway
<img width="979" height="277" alt="image" src="https://github.com/user-attachments/assets/00fe8297-5141-42a7-9e4a-41afb56c6809" />
### Elastic Ip
<img width="979" height="258" alt="image" src="https://github.com/user-attachments/assets/b4e15851-a7df-4aac-9420-30c0a6e5e323" />
### NAT Gateway
<img width="979" height="241" alt="image" src="https://github.com/user-attachments/assets/de98d81d-9a9e-44e3-9318-386b5874aee4" />

> `prod-vpc` created with CIDR block, public and private subnets across availability zones.

---

## 4. 🔀 Subnets
<img width="979" height="301" alt="image" src="https://github.com/user-attachments/assets/8a3f46fe-7a3f-4df0-a51a-badc175d866d" />

> Public subnets (for ALB) and private subnets (for EC2 + RDS) configured across multiple AZs.

---

## 5. 🛡️ Security Groups
<img width="979" height="363" alt="image" src="https://github.com/user-attachments/assets/59e456eb-ea3b-4286-a735-27908a1d6b6e" />

> 4 security groups created — ALB, EC2, RDS, and EFS — with least-privilege inbound/outbound rules.

## 6. 🗄️ RDS — MySQL Database
<img width="979" height="265" alt="image" src="https://github.com/user-attachments/assets/623c9cf6-c3b4-4274-8a82-d7e528665a37" />

> `prod-wordpress-db` MySQL instance running in private subnet — status: **Available ✅**

---

## 7. 🔑 Secrets Manager

<img width="979" height="287" alt="image" src="https://github.com/user-attachments/assets/1a7f11af-587f-48a8-b625-316a7ec327f6" />

> `wordpress-db-secret` storing DB credentials — retrieved at runtime by the Docker container.

---

## 8. 📁 EFS — Shared Storage

<img width="979" height="318" alt="image" src="https://github.com/user-attachments/assets/357ff49f-6053-4652-8e7c-c944f3243fcb" />

> `prod-wordpress-efs` mounted across all EC2 instances to share `wp-content` (uploads, plugins, themes).

---

## 9. 🐳 ECR — Docker Image Registry

<img width="979" height="327" alt="image" src="https://github.com/user-attachments/assets/e43ccf99-beba-42d9-896a-689093424c3f" />

> `prod-wordpress` repository with the latest WordPress Docker image pushed successfully.

---
## 10. 🐳 ECR — Image Details

<img width="979" height="275" alt="image" src="https://github.com/user-attachments/assets/6ab8a2ca-842f-4010-b3c4-2e11d8220a6e" />

> Docker image tagged as `latest` — pushed from EC2 via `docker push`.

---

## 11. ⚖️ ALB — Application Load Balancer

<img width="979" height="340" alt="image" src="https://github.com/user-attachments/assets/7e2ef44e-48bf-4acb-b2b6-bbedb04b4fce" />

> `prod-alb` active in public subnets — HTTPS listener on port 443 with ACM certificate attached.

---

## 12. 🎯 Target Groups — Blue & Green

<img width="979" height="416" alt="image" src="https://github.com/user-attachments/assets/64399393-ce2d-49ca-b052-1fce6e6230a1" />

> `prod-blue-tg` and `prod-green-tg` both created — ready for Blue/Green traffic switching.

---

## 13. 💚 Target Group — Healthy Instances

<img width="979" height="363" alt="image" src="https://github.com/user-attachments/assets/a0d0aa31-8bf8-4f59-a477-9c0457d3625a" />

> EC2 instances registered and showing **Healthy** status in the active target group ✅

---

## 14. 📈 Auto Scaling Group
### ASG Created — prod-wordpress-asg
<img width="979" height="311" alt="image" src="https://github.com/user-attachments/assets/cc2e7126-11af-46c2-928f-f9d6279ad3a5" />
### Launch Template — AL2023 + IMDSv2
<img width="979" height="315" alt="image" src="https://github.com/user-attachments/assets/fb2d857a-a9f2-4aa4-90c0-1ffd08303248" />

> `prod-wordpress-asg` configured with Launch Template (AL2023, IMDSv2, Docker) — min/max/desired capacity set.

---

## 15. 🚀 EC2 Instances — Running
<img width="979" height="339" alt="image" src="https://github.com/user-attachments/assets/2e0a5769-e51e-499f-a15c-b0fdd697746a" />

> EC2 instances launched by ASG in private subnets — running WordPress Docker container.

---

## 16. 🔧 IAM Roles
<img width="979" height="398" alt="image" src="https://github.com/user-attachments/assets/c8d21b33-d2d5-4397-9186-4c2cc59fb830" />

> Least-privilege IAM roles created for EC2, CodeBuild, CodeDeploy, and CodePipeline.

---

## 17. 🪣 S3 — Terraform State Bucket

<img width="979" height="388" alt="image" src="https://github.com/user-attachments/assets/92d11219-a7fb-4f4a-bd0b-26d1fd69f7cd" />


> `ganeshc-terraform-state` with versioning enabled — stores Terraform state securely.

---

## 18. ⚙️ CodePipeline — Pipeline Overview

<img width="979" height="265" alt="image" src="https://github.com/user-attachments/assets/dfb51549-7971-4a8c-b2f4-c869279bab0e" />


> `wordpress-prod-pipeline` with 3 stages: Source (GitHub) → Build (CodeBuild) → Deploy (CodeDeploy).

---

## 19. 🏗️ CodeBuild — Build Success

<img width="979" height="387" alt="image" src="https://github.com/user-attachments/assets/4bedfae4-c07a-4be0-bee5-bae069b3868e" />


> Docker image built and pushed to ECR successfully — all build phases passed ✅

---

## 20. 🔵🟢 CodeDeploy — Blue/Green Deployment

<img width="979" height="390" alt="image" src="https://github.com/user-attachments/assets/01ac7723-409a-467f-b05a-c860d668406c" />
<img width="979" height="433" alt="image" src="https://github.com/user-attachments/assets/74195f67-cf01-46d2-993d-a94ec20ec9de" />
<img width="979" height="358" alt="image" src="https://github.com/user-attachments/assets/dd7507a4-8d21-4fa7-bd86-092d55960c50" />
<img width="979" height="339" alt="image" src="https://github.com/user-attachments/assets/654b88a5-1c7d-458b-8985-7d9d9c4f0fec" />
> Blue/Green deployment completed — traffic shifted from Blue to Green, old instances terminated ✅

**#21. CloudWatch Alarms**
<img width="979" height="258" alt="image" src="https://github.com/user-attachments/assets/ab835f51-535f-48fe-86aa-8692672dba19" />
---
## 22. CodeConnections — GitHub
<img width="979" height="305" alt="image" src="https://github.com/user-attachments/assets/c3d1d575-8bfa-4c39-922f-3e79d1ae76c8" />

## 🌐 WordPress — Live Site

<img width="979" height="444" alt="image" src="https://github.com/user-attachments/assets/e5aad217-fc9c-4677-a16e-49bfb0754b56" />

<img width="979" height="471" alt="image" src="https://github.com/user-attachments/assets/9bdf5a07-b7fc-4865-8b34-cc94661323c7" />



> `https://ganeshc.shop` live and serving WordPress via ALB + EC2 + RDS ✅

---
