#!/bin/bash
set -e
echo "=== AfterInstall: Pull Image + Start Container ==="

REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/prod-wordpress"

# Pull latest image
echo "Pulling latest Docker image..."
docker pull $ECR_URL:latest
echo "Image pulled ✅"

# Stop old container
docker stop wordpress-container 2>/dev/null || true
docker rm wordpress-container 2>/dev/null || true

# 🔥 Create health check file in EFS (HOST)
echo "Creating health check file in EFS..."
echo "OK" > /var/www/html/healthy.html
chmod 777 /var/www/html/healthy.html

# Run container (mount EFS inside container)
echo "Starting WordPress container..."
docker run -d \
  --name wordpress-container \
  --restart always \
  -p 80:80 \
  -v /var/www/html:/var/www/html \
  -e SECRET_NAME="wordpress-db-secret" \
  -e AWS_REGION="$REGION" \
  $ECR_URL:latest

echo "Container started ✅"

# Wait for warmup
sleep 20

echo "AfterInstall complete ✅"
