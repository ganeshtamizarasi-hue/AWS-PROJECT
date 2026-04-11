#!/bin/bash
set -e

echo "=== AfterInstall: Pull Image + Start Container ==="

# -------------------------------
# IMDSv2 (FIX REGION ISSUE)
# -------------------------------
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

REGION=$(curl -s \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

# Safety check
if [ -z "$REGION" ]; then
  echo "ERROR: Region not found ❌"
  exit 1
fi

echo "Region: $REGION"

# -------------------------------
# Account ID
# -------------------------------
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Account ID: $ACCOUNT_ID"

# -------------------------------
# ECR URL (your repo)
# -------------------------------
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/prod-wordpress"

echo "Image: $ECR_URL:latest"

# -------------------------------
# Login to ECR
# -------------------------------
aws ecr get-login-password --region "$REGION" | \
docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# -------------------------------
# Pull image
# -------------------------------
echo "Pulling latest Docker image from ECR..."
docker pull "$ECR_URL:latest"
echo "Image pulled ✅"

# -------------------------------
# Run container
# -------------------------------
echo "Starting WordPress container..."

docker stop wordpress-container 2>/dev/null || true
docker rm wordpress-container 2>/dev/null || true

docker run -d \
  --name wordpress-container \
  --restart always \
  -p 80:80 \
  -e SECRET_NAME="wordpress-db-secret" \
  -e AWS_REGION="$REGION" \
  "$ECR_URL:latest"

echo "Container started ✅"

# Wait for app
sleep 10

echo "AfterInstall complete ✅"
