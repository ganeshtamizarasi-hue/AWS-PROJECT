#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "=========================================="
echo "EC2 Bootstrap Starting..."
echo "=========================================="

# ── Variables passed from Terraform ──────────────────────────
ECR_REPO_URL="${ecr_repo_url}"
SECRET_NAME="${secret_name}"
REGION="${region}"

# ── 1. Update System ──────────────────────────────────────────
echo "[1/5] Updating system..."
dnf update -y

# ── 2. Install Docker ─────────────────────────────────────────
echo "[2/5] Installing Docker..."
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
echo "Docker installed ✅"

# ── 3. Install CodeDeploy Agent ───────────────────────────────
echo "[3/5] Installing CodeDeploy agent..."
dnf install -y ruby wget
cd /home/ec2-user
wget -q https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent
echo "CodeDeploy agent installed ✅"

# ── 4. Install AWS CLI + jq ───────────────────────────────────
echo "[4/5] Installing AWS CLI + jq..."
dnf install -y jq
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
echo "AWS CLI installed ✅"

# ── 5. Login to ECR + Pull + Run WordPress Container ──────────
echo "[5/5] Pulling Docker image from ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_REPO_URL

docker pull $ECR_REPO_URL:latest

docker run -d \
  --name wordpress-container \
  --restart always \
  -p 80:80 \
  -e SECRET_NAME="$SECRET_NAME" \
  -e AWS_REGION="$REGION" \
  $ECR_REPO_URL:latest

echo "WordPress container running ✅"

# Health check file for ALB
sleep 5
echo "healthy" > /var/www/html/healthy.html 2>/dev/null || true

echo "=========================================="
echo "EC2 Bootstrap Complete ✅"
echo "=========================================="
