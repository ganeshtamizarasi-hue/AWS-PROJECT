#!/bin/bash
set -e
echo "=== BeforeInstall Start ==="

# ── Get IMDSv2 token ──────────────────────────────────────────
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to get IMDSv2 token"
  exit 1
fi

# ── Get region from instance metadata ────────────────────────
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/dynamic/instance-identity/document \
  | grep region | awk -F\" '{print $4}')

if [ -z "$REGION" ]; then
  echo "ERROR: Failed to get region from metadata"
  exit 1
fi

echo "Region: $REGION"

# ── Install Docker if missing ─────────────────────────────────
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  dnf install -y docker
  systemctl enable docker --now
fi
echo "Docker ready ✅"

# ── Install AWS CLI if missing ────────────────────────────────
if ! command -v aws &> /dev/null; then
  echo "Installing AWS CLI..."
  dnf install -y unzip
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
fi
echo "AWS CLI ready ✅"

# ── Login to ECR ──────────────────────────────────────────────
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "Logging into ECR: $ECR_URL"
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$ECR_URL"
echo "ECR login success ✅"

# ── Stop and remove old container ────────────────────────────
docker stop wordpress-container 2>/dev/null || true
docker rm wordpress-container 2>/dev/null || true
echo "Old container cleaned up ✅"

echo "=== BeforeInstall Completed ==="
