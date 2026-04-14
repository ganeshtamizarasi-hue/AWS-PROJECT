#!/bin/bash
set -e
echo "Starting WordPress container..."

# ── Fetch credentials from Secrets Manager ────────────────────
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_NAME:-wordpress-db-secret}" \
  --region "${AWS_REGION:-ap-south-1}" \
  --query SecretString --output text)

DB_NAME=$(echo $SECRET | jq -r .dbname)
DB_USER=$(echo $SECRET | jq -r .username)
DB_PASS=$(echo $SECRET | jq -r .password)
DB_HOST=$(echo $SECRET | jq -r .host)

echo "Credentials fetched from Secrets Manager ✅"

# ── Configure WordPress ───────────────────────────────────────
if [ ! -f /var/www/html/wp-config.php ]; then
  cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
  sed -i "s/database_name_here/$DB_NAME/" /var/www/html/wp-config.php
  sed -i "s/username_here/$DB_USER/"      /var/www/html/wp-config.php
  sed -i "s/password_here/$DB_PASS/"      /var/www/html/wp-config.php
  sed -i "s/localhost/$DB_HOST/"          /var/www/html/wp-config.php
  echo "WordPress configured ✅"
fi

# ── ✅ Fix HTTPS for ALB (ONLY ONCE) ───────────────────────────
if ! grep -q "X_FORWARDED_PROTO" /var/www/html/wp-config.php; then
  echo "Applying ALB HTTPS fix..."

  cat >> /var/www/html/wp-config.php << 'WPEOF'

// Force HTTPS (required behind AWS ALB)
define('FORCE_SSL_ADMIN', true);

if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Correct site URL
define('WP_HOME', 'https://ganeshc.shop');
define('WP_SITEURL', 'https://ganeshc.shop');

WPEOF

  echo "HTTPS config added ✅"
fi

# ── Fix permissions ───────────────────────────────────────────
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod 644 /var/www/html/wp-config.php

echo "Permissions fixed ✅"

# ── Start Apache (MUST BE LAST) ───────────────────────────────
echo "Starting Apache..."
exec apache2-foreground
