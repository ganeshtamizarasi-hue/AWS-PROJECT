#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "===== EC2 BOOTSTRAP STARTING ====="

# Variables from Terraform templatefile
ECR_REPO_URL="${ecr_repo_url}"
SECRET_NAME="${secret_name}"
REGION="${region}"

# ── 1. Update System ────────────────────
echo "[1/7] Updating system..."
dnf update -y

# ── 2. Install Docker ───────────────────
echo "[2/7] Installing Docker..."
dnf install -y docker
systemctl enable docker
systemctl start docker

# ── 3. Install CodeDeploy Agent ─────────
echo "[3/7] Installing CodeDeploy agent..."
dnf install -y ruby wget
cd /tmp
wget -q https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent
sleep 5
echo "CodeDeploy agent installed ✅"

# ── 4. Install AWS CLI + jq ─────────────
echo "[4/7] Installing AWS CLI + jq..."
dnf install -y jq
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
echo "AWS CLI installed ✅"

# ── 5. Mount EFS ────────────────────────
echo "[5/7] Mounting EFS..."
dnf install -y amazon-efs-utils
mkdir -p /var/www/html
sleep 10
mount -t efs -o tls ${efs_id}:/ /var/www/html
echo "${efs_id}:/ /var/www/html efs defaults,tls,_netdev 0 0" >> /etc/fstab
chown -R 33:33 /var/www/html
chmod -R 775 /var/www/html
echo "EFS mounted ✅"

# ── 6. Pull + Run Docker Container ──────
echo "[6/7] Starting WordPress container..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker pull ${ecr_repo_url}:latest

docker run -d \
  --name wordpress-container \
  --restart always \
  -p 80:80 \
  -e SECRET_NAME="$SECRET_NAME" \
  -e AWS_REGION="$REGION" \
  ${ecr_repo_url}:latest

echo "Container started ✅"

# ── 7. Health Check File ────────────────
echo "[7/7] Creating health check..."
sleep 15
docker exec wordpress-container \
  bash -c "echo 'healthy' > /var/www/html/healthy.html"
echo "Health check created ✅"

# ── Final Status ────────────────────────
echo "===== FINAL STATUS ====="
systemctl is-active codedeploy-agent && echo "CodeDeploy : ✅" || echo "CodeDeploy : ❌"
systemctl is-active docker            && echo "Docker     : ✅" || echo "Docker     : ❌"
docker ps | grep -q wordpress         && echo "Container  : ✅" || echo "Container  : ❌"

echo "===== BOOTSTRAP COMPLETE ====="
