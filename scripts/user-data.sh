#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "=========================================="
echo "EC2 Bootstrap Starting..."
echo "=========================================="

# ── Variables passed from Terraform ──────────────────────────
ECR_REPO_URL="${ecr_repo_url}"
SECRET_NAME="${secret_name}"
REGION="${region}"

# ── 1. Update System ──────────────────────────────────────────
echo "[1/7] Updating system..."
dnf update -y

# ── 1.5 Install SSM Agent ────────────────────────────────────
echo "[1.5/7] Installing SSM Agent..."
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
echo "SSM Agent installed and running ✅"

# ── 2. Install Docker ─────────────────────────────────────────
echo "[2/7] Installing Docker..."
dnf install -y docker
systemctl enable docker --now
usermod -aG docker ec2-user
echo "Docker installed ✅"

# ── 3. Install CodeDeploy Agent ───────────────────────────────
echo "[3/7] Installing CodeDeploy agent..."
dnf install -y ruby wget
cd /home/ec2-user

wget -q https://aws-codedeploy-$REGION.s3.$REGION.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Configure agent to use IMDSv2
mkdir -p /etc/codedeploy-agent/conf
cat > /etc/codedeploy-agent/conf/codedeployagent.yml <<EOF
---
:log_aws_wire: false
:log_dir: '/var/log/aws/codedeploy-agent/'
:pid_dir: '/opt/codedeploy-agent/state/.pid/'
:program_name: codedeploy-agent
:root_dir: '/opt/codedeploy-agent/deployment-root'
:verbose: false
:wait_between_runs: 1
:max_revisions: 5
:enable_auth_policy: false
:proxy_uri:
:metadata_token_ttl_seconds: 21600
EOF

systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# Wait until agent is running
for i in {1..10}; do
  systemctl is-active --quiet codedeploy-agent && break
  echo "Waiting for CodeDeploy agent... attempt $i"
  sleep 5
done

echo "CodeDeploy agent installed ✅"

# ── 4. Install AWS CLI + jq ───────────────────────────────────
echo "[4/7] Installing AWS CLI + jq..."
dnf install -y jq unzip
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
echo "AWS CLI installed ✅"

# ── 5. Login to ECR (only login, no container run) ────────────
echo "[5/7] Logging into ECR..."

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

if [ -z "$TOKEN" ]; then
  echo "ERROR: Could not get IMDSv2 token"
  exit 1
fi

aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ECR_REPO_URL

echo "ECR login successful ✅"

# ── 6. DO NOT RUN CONTAINER HERE ──────────────────────────────
echo "[6/7] Skipping container start (handled by CodeDeploy)"

# ── 7. Final Check ───────────────────────────────────────────
echo "[7/7] Verifying services..."

systemctl is-active --quiet amazon-ssm-agent && echo "SSM running ✅" || echo "SSM failed ❌"
systemctl is-active --quiet codedeploy-agent && echo "CodeDeploy running ✅" || echo "CodeDeploy failed ❌"
systemctl is-active --quiet docker && echo "Docker running ✅" || echo "Docker failed ❌"

echo "=========================================="
echo "EC2 Bootstrap Complete ✅"
echo "=========================================="
