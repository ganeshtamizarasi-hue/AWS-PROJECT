#!/bin/bash
set -e

echo "=== BeforeInstall: Green Instance Setup ==="

# Install Docker (Amazon Linux 2023 uses dnf, not apt)
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  sudo dnf install -y docker
  sudo systemctl enable docker
  sudo systemctl start docker
fi

echo "Docker running ✅"

# Get region from instance metadata
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Build ECR URL
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_URL

echo "ECR login successful ✅"

# Stop existing container if running
docker stop wordpress-container 2>/dev/null || true
docker rm wordpress-container 2>/dev/null || true

echo "BeforeInstall complete ✅"
