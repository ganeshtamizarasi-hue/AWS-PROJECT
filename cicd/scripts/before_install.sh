#!/bin/bash
set -e

echo "=== BeforeInstall: Green Instance Setup ==="

# Install AWS CLI (if not exists)
if ! command -v aws &> /dev/null; then
  echo "Installing AWS CLI..."
  dnf install -y aws-cli || apt update -y && apt install -y awscli
fi

# Install Docker
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  dnf install -y docker || apt install -y docker.io
  systemctl enable docker
  systemctl start docker
fi

echo "Docker running ✅"

# Get region safely
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

echo "ECR login successful ✅"

# Stop old container
docker stop wordpress-container 2>/dev/null || true
docker rm wordpress-container 2>/dev/null || true

echo "BeforeInstall complete ✅"
