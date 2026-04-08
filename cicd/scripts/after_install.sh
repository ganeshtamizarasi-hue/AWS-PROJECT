#!/bin/bash
set -e
echo "=== AfterInstall: Pull Image + Start Container ==="

REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/prod-wordpress"

# Pull latest image from ECR
echo "Pulling latest Docker image from ECR..."
docker pull $ECR_URL:latest
echo "Image pulled ✅"

# Run WordPress container
echo "Starting WordPress container..."
docker run -d \
  --name wordpress-container \
  --restart always \
  -p 80:80 \
  -e SECRET_NAME="wordpress-db-secret" \
  -e AWS_REGION="$REGION" \
  $ECR_URL:latest

echo "Container started ✅"

# Wait for container to warm up
sleep 10

echo "AfterInstall complete ✅"
