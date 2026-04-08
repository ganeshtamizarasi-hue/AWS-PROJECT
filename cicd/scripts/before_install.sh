#!/bin/bash
set -e

echo "=== BeforeInstall: Green Instance Setup ==="

# Update system
yum update -y

# Install Docker if not already present
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  yum install -y docker
  systemctl enable docker
  systemctl start docker
fi

# Ensure Docker is running
systemctl start docker
echo "Docker running ✅"

# Add ec2-user to docker group (safe even if already added)
usermod -aG docker ec2-user || true

# Get region + account from metadata
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ECR_URL

echo "ECR login successful ✅"

# Stop & remove existing container if exists
docker stop wordpress-container 2>/dev/null || true
docker rm wordpress-container 2>/dev/null || true

echo "BeforeInstall complete ✅"
