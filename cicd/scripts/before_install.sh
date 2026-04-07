#!/bin/bash
set -e

echo "=== BeforeInstall Start ==="

# Install Docker (universal)
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."

  if command -v dnf &> /dev/null; then
    dnf install -y docker
  elif command -v yum &> /dev/null; then
    yum install -y docker
  elif command -v apt &> /dev/null; then
    apt update -y
    apt install -y docker.io
  fi

  systemctl enable docker
  systemctl start docker
fi

echo "Docker ready ✅"

# Install AWS CLI if missing
if ! command -v aws &> /dev/null; then
  echo "Installing AWS CLI..."

  if command -v dnf &> /dev/null; then
    dnf install -y aws-cli
  elif command -v yum &> /dev/null; then
    yum install -y aws-cli
  elif command -v apt &> /dev/null; then
    apt install -y awscli
  fi
fi

echo "AWS CLI ready ✅"

# Get region safely
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

echo "ECR login success ✅"

# Cleanup old container
docker stop wordpress-container 2>/dev/null || true
docker rm wordpress-container 2>/dev/null || true

echo "=== BeforeInstall Completed ==="
