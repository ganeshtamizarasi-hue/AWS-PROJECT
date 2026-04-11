#!/bin/bash
set -e
echo "=== AfterInstall: Pull Image + Start Container ==="

REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/prod-wordpress"

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Pull latest image
echo "Pulling latest Docker image..."
docker pull $ECR_URL:latest
echo "Image pulled ✅"

# Stop old container
docker stop wordpress-container 2>/dev/null || true
docker rm   wordpress-container 2>/dev/null || true

# Run container
echo "Starting WordPress container..."
docker run -d \
  --name wordpress-container \
  --restart always \
  -p 80:80 \
  -e SECRET_NAME="wordpress-db-secret" \
  -e AWS_REGION="$REGION" \
  $ECR_URL:latest

echo "Container started ✅"

# Wait for container warmup
echo "Waiting for warmup..."
sleep 20

# Create health check file INSIDE container
echo "Creating health check file..."
docker exec wordpress-container \
  bash -c "echo 'healthy' > /var/www/html/healthy.html && chmod 644 /var/www/html/healthy.html"

echo "Health check file created ✅"
echo "AfterInstall complete ✅"
