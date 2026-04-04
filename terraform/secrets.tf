# ── Secrets Manager ───────────────────────────────────────────
# Stores RDS credentials securely
# Docker container fetches this at runtime — zero hardcoded creds

resource "aws_secretsmanager_secret" "wordpress_db" {
  name                    = "wordpress-db-secret"
  description             = "WordPress RDS credentials"
  recovery_window_in_days = 0
  tags                    = { Name = "${var.environment}-wordpress-db-secret" }
}

resource "aws_secretsmanager_secret_version" "wordpress_db" {
  secret_id = aws_secretsmanager_secret.wordpress_db.id

  secret_string = jsonencode({
    dbname   = var.db_name
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.wordpress.address
    port     = "3306"
  })

  depends_on = [aws_db_instance.wordpress]
}
