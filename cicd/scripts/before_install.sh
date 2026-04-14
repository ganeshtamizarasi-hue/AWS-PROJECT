#!/bin/bash
set -e
echo "=== BeforeInstall: Setup Green Instance ==="

# ── Hardcode region ───────────────────────────────────────────
REGION="ap-south-1"

# ── Get Account ID ────────────────────────────────────────────
ACCOUNT_ID=$(aws sts get-caller-identity \
  --region "$REGION" \
  --query Account \
  --output text)

echo "Region     : $REGION"
echo "Account ID : $ACCOUNT_ID"

# ── Install Docker if not present ─────────────────────────────
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  dnf install -y docker
  systemctl enable docker
  systemctl start docker
  echo "Docker installed ✅"
else
  echo "Docker already installed ✅"
  systemctl start docker || true
fi

# ── ECR Login (file method) ───────────────────────────────────
ECR_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
echo "Logging into ECR...."

aws ecr get-login-password \
  --region "$REGION" > /tmp/ecr_token

docker login \
  --username AWS \
  --password-stdin \
  "$ECR_REPO" < /tmp/ecr_token

rm -f /tmp/ecr_token
echo "ECR login successful ✅"

# ── Stop old container ────────────────────────────────────────
docker stop wordpress-container 2>/dev/null || true
docker rm   wordpress-container 2>/dev/null || true
echo "Old container removed ✅"

echo "=== BeforeInstall complete ✅ ==="
