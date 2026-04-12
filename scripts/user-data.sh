#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "===== EC2 BOOTSTRAP STARTING ====="

# ── Variables from Terraform ─────────────────────────────────
ECR_REPO_URL="${ecr_repo_url}"
SECRET_NAME="${secret_name}"
REGION="${region}"
EFS_ID="${efs_id}"

echo "Region  : $REGION"
echo "EFS ID  : $EFS_ID"
echo "ECR URL : $ECR_REPO_URL"

# ── 1. Update System ─────────────────────────────────────────
echo "[1/7] Updating system..."
dnf update -y
echo "System updated ✅"

# ── 2. Install Docker ────────────────────────────────────────
echo "[2/7] Installing Docker..."
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
echo "Docker installed ✅"

# ── 3. Install CodeDeploy Agent ──────────────────────────────
echo "[3/7] Installing CodeDeploy agent..."
dnf install -y ruby wget
cd /tmp
wget -q https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# Verify agent is running
sleep 5
if systemctl is-active codedeploy-agent; then
  echo "CodeDeploy agent running ✅"
else
  echo "CodeDeploy agent failed — retrying..."
  systemctl restart codedeploy-agent
  sleep 5
  systemctl status codedeploy-agent
fi

# ── 4. Install AWS CLI + jq ──────────────────────────────────
echo "[4/7] Installing AWS CLI + jq..."
dnf install -y jq
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
echo "AWS CLI installed ✅"

# ── 5. Mount EFS ─────────────────────────────────────────────
echo "[5/7] Mounting EFS..."
dnf install -y amazon-efs-utils
mkdir -p /var/www/html

# Wait for network to be ready
sleep 10

mount -t efs -o tls ${EFS_ID}:/ /var/www/html

# Persist after reboot
echo "${EFS_ID}:/ /var/www/html efs defaults,tls,_netdev 0 0" >> /etc/fstab

# Permissions for WordPress (www-data = uid 33)
chown -R 33:33 /var/www/html
chmod -R 775 /var/www/html
echo "EFS mounted ✅"

# ── 6. Login to ECR + Pull + Run Container ───────────────────
echo "[6/7] Pulling Docker image from ECR..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker pull $ECR_REPO_URL:latest

docker run -d \
  --name wordpress-container \
  --restart always \
  -p 80:80 \
  -e SECRET_NAME="$SECRET_NAME" \
  -e AWS_REGION="$REGION" \
  $ECR_REPO_URL:latest

echo "WordPress container started ✅"

# ── 7. Create Health Check File ──────────────────────────────
echo "[7/7] Creating health check file..."
sleep 15
docker exec wordpress-container \
  bash -c "echo 'healthy' > /var/www/html/healthy.html && chmod 644 /var/www/html/healthy.html" || \
  echo "healthy" > /var/www/html/healthy.html

# ── Final Checks ─────────────────────────────────────────────
echo "===== FINAL STATUS ====="
systemctl is-active codedeploy-agent && echo "CodeDeploy : running ✅" || echo "CodeDeploy : FAILED ❌"
systemctl is-active docker            && echo "Docker     : running ✅" || echo "Docker     : FAILED ❌"
docker ps | grep -q wordpress         && echo "Container  : running ✅" || echo "Container  : FAILED ❌"
df -h | grep -q /var/www/html         && echo "EFS        : mounted ✅" || echo "EFS        : FAILED ❌"

echo "===== EC2 BOOTSTRAP COMPLETE ====="
