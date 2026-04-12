#!/bin/bash
set -e
echo "=== AfterInstall: Pull Image + Start Container ==="

# ── Hardcode region — curl metadata unreliable on Green instances
REGION="ap-south-1"
ACCOUNT_ID=$(aws sts get-caller-identity \
  --region "$REGION" \
  --query Account \
  --output text)

ECR_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
ECR_IMAGE="$ECR_REPO/prod-wordpress:latest"

echo "Region    : $REGION"
echo "Account   : $ACCOUNT_ID"
echo "ECR Image : $ECR_IMAGE"

# ── ECR Login ─────────────────────────────────────────────────
echo "Logging into ECR..."
aws ecr get-login-password \
  --region "$REGION" > /tmp/ecr_token

docker login \
  --username AWS \
  --password-stdin \
  "$ECR_REPO" < /tmp/ecr_token

rm -f /tmp/ecr_token
echo "ECR login ✅"

# ── Pull image ────────────────────────────────────────────────
echo "Pulling Docker image..."
docker pull "$ECR_IMAGE"
echo "Image pulled ✅"

# ── Stop old container ────────────────────────────────────────
docker stop wordpress-container 2>/dev/null || true
docker rm   wordpress-container 2>/dev/null || true

# ── Run container ─────────────────────────────────────────────
echo "Starting WordPress container..."
docker run -d \
  --name wordpress-container \
  --restart always \
  -p 80:80 \
  -e SECRET_NAME="wordpress-db-secret" \
  -e AWS_REGION="$REGION" \
  "$ECR_IMAGE"
echo "Container started ✅"

sleep 20

# ── Health check ──────────────────────────────────────────────
echo "Creating health check..."
docker exec wordpress-container \
  bash -c "echo 'healthy' > /var/www/html/healthy.html && chmod 644 /var/www/html/healthy.html"
echo "Health check created ✅"

echo "=== AfterInstall complete ✅ ==="
