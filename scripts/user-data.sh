#!/bin/bash
set -xe

echo "===== EC2 BOOTSTRAP START ====="

# Get region
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# ── 1. Install packages ─────────────────────────────────────
dnf update -y
dnf install -y docker git amazon-efs-utils jq unzip

# ── 2. Start Docker ─────────────────────────────────────────
systemctl enable docker
systemctl start docker

echo "Docker installed and running ✅"

# ── 3. Install CodeDeploy Agent ─────────────────────────────
dnf install -y ruby wget

cd /home/ec2-user
wget https://aws-codedeploy-$REGION.s3.$REGION.amazonaws.com/latest/install
chmod +x ./install
./install auto

systemctl enable codedeploy-agent
systemctl start codedeploy-agent

echo "CodeDeploy agent installed ✅"

# ── 4. Install AWS CLI v2 ───────────────────────────────────
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install

echo "AWS CLI installed ✅"

# ── 5. Mount EFS ────────────────────────────────────────────
echo "Mounting EFS..."

mkdir -p /var/www/html

# Wait a bit to ensure network is ready
sleep 10

mount -t efs -o tls ${efs_id}:/ /var/www/html

# Persist after reboot
echo "${efs_id}:/ /var/www/html efs defaults,_netdev 0 0" >> /etc/fstab

# Permissions for WordPress
chown -R 33:33 /var/www/html
chmod -R 775 /var/www/html

echo "EFS mounted successfully ✅"

# ── 6. Login to ECR ─────────────────────────────────────────
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

echo "ECR login successful ✅"

# ── 7. Final Checks ─────────────────────────────────────────
systemctl is-active --quiet codedeploy-agent && echo "CodeDeploy running ✅" || echo "CodeDeploy failed ❌"
systemctl is-active --quiet docker && echo "Docker running ✅" || echo "Docker failed ❌"

echo "===== EC2 BOOTSTRAP COMPLETE ====="
