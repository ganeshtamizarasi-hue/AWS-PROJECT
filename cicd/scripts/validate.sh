#!/bin/bash
echo "=== ValidateService: Health Check ==="

# Wait for container to fully start
sleep 10

# Check Docker container is running
if ! docker ps | grep -q wordpress-container; then
  echo "FAILED: WordPress container is not running ❌"
  exit 1
fi
echo "Container is running ✅"

# Check health endpoint returns HTTP 200
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/healthy.html)

if [ "$STATUS" = "200" ]; then
  echo "Health check PASSED — HTTP $STATUS ✅"
  echo "Green instance is healthy — traffic will shift from Blue to Green"
  exit 0
else
  echo "Health check FAILED — HTTP $STATUS ❌"
  echo "Triggering automatic rollback to Blue environment..."
  exit 1
fi
