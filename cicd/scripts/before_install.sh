#!/bin/bash
set -e

echo "=== BeforeInstall: Green Instance Setup ==="

# Install Docker
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  sudo dnf install -y docker
  sudo systemctl enable docker
  sudo systemctl start docker
fi

echo "Docker running ✅"

# FIX 1: Use IMDSv2 (IMPORTANT)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

REGION=$(curl -s \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

echo "Region detected: $REGION"

# Safety check
if [ -z "$REGION" ]; then
  echo "ERROR: Region not found ❌"
  exit 1
fi

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR URL
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "Logging into ECR..."

# FIX 2: Proper login (non-interactive)
aws ecr get-login-password --region "$REGION" | \
docker login --username AWS --password-stdin "$ECR_URL"

echo "ECR login successful ✅"

# Stop old container
docker stop wordpress-container 2>/dev/null || true
docker rm wordpress-container 2>/dev/null || true

echo "BeforeInstall complete ✅"
