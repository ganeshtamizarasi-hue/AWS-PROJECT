#!/bin/bash
echo "== AfterAllowTraffic =="
echo "Traffic successfully switched from Blue → Green ✅"
echo "Blue instances will be terminated in 5 minutes..."
echo "Deployment completed at $(date)" >> /var/log/deployments.log
echo "Blue/Green deployment successful ✅"
