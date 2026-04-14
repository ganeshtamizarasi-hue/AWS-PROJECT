#!/bin/bash
echo "=== ValidateService: Health Check ==="

sleep 10

# Check container running
if ! docker ps | grep -q wordpress-container; then
  echo "FAILED: Container not running ❌"
  exit 1
fi
echo "Container Running ✅"

# Check health endpoint
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/healthy.html)

if [ "$STATUS" = "200" ]; then
  echo "Health check PASSED — HTTP $STATUS ✅"
  exit 0
else
  echo "Health check FAILED — HTTP $STATUS ❌"
  exit 1
fi
