#!/bin/bash
set -xe

echo "=========================================="
echo "EC2 Bootstrap Started"
echo "=========================================="

# ── 1. Update system ─────────────────────────────────────────
echo "[1/7] Updating system..."
dnf update -y

# ── 2. Install Docker ────────────────────────────────────────
echo "[2/7] Installing Docker..."
dnf install -y docker
systemctl enable docker
systemctl start docker
echo "Docker running ✅"

# ── 3. Install CodeDeploy Agent ─────────────────────────────
echo "[3/7] Installing CodeDeploy agent..."
dnf install -y ruby wget

cd /home/ec2-user
wget https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/install
chmod +x ./install
./install auto

systemctl enable codedeploy-agent
systemctl start codedeploy-agent

sleep 5
echo "CodeDeploy agent installed ✅"

# ── 4. Install AWS CLI + jq ─────────────────────────────────
echo "[4/7] Installing AWS CLI + jq..."
dnf install -y jq unzip amazon-efs-utils

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install

echo "AWS CLI installed ✅"

# ── 5. Mount EFS + Fix Permissions ──────────────────────────
echo "[5/7] Mounting EFS..."

mkdir -p /var/www/html

# Mount EFS
mount -t efs -o tls ${efs_id}:/ /var/www/html

# Persist mount after reboot
echo "${efs_id}:/ /var/www/html efs defaults,_netdev 0 0" >> /etc/fstab

# 🔥 Fix WordPress permissions
chown -R 33:33 /var/www/html
chmod -R 775 /var/www/html

echo "EFS mounted & permissions fixed ✅"

# ── 6. Login to ECR ─────────────────────────────────────────
echo "[6/7] Logging into ECR..."

REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo "ECR login successful ✅"

# ── 7. Final Checks ─────────────────────────────────────────
echo "[7/7] Verifying services..."

systemctl is-active --quiet codedeploy-agent && echo "CodeDeploy running ✅" || echo "CodeDeploy failed ❌"
systemctl is-active --quiet docker && echo "Docker running ✅" || echo "Docker failed ❌"

echo "=========================================="
echo "EC2 Bootstrap Complete ✅"
echo "=========================================="
