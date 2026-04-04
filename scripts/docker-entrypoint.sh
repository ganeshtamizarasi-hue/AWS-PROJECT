#!/bin/bash
set -e
echo "Starting WordPress container..."

# Fetch credentials from Secrets Manager at runtime
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_NAME:-wordpress-db-secret}" \
  --region "${AWS_REGION:-ap-south-1}" \
  --query SecretString --output text)

DB_NAME=$(echo $SECRET | jq -r .dbname)
DB_USER=$(echo $SECRET | jq -r .username)
DB_PASS=$(echo $SECRET | jq -r .password)
DB_HOST=$(echo $SECRET | jq -r .host)

echo "Credentials fetched from Secrets Manager ✅"

# Configure WordPress
if [ ! -f /var/www/html/wp-config.php ]; then
  cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
  sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
  sed -i "s/username_here/$DB_USER/"      /var/www/html/wp-config.php
  sed -i "s/password_here/$DB_PASS/"      /var/www/html/wp-config.php
  sed -i "s/localhost/$DB_HOST/"          /var/www/html/wp-config.php
  chmod 640 /var/www/html/wp-config.php
  echo "WordPress configured ✅"
fi

exec apache2-foreground
