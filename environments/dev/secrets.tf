resource "aws_secretsmanager_secret" "db_password" {
  name                    = "retailstore/${var.environment}/db-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

resource "aws_secretsmanager_secret" "admin_password" {
  name                    = "retailstore/dev/admin-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "admin_password" {
  secret_id     = aws_secretsmanager_secret.admin_password.id
  secret_string = var.admin_password
}

resource "aws_secretsmanager_secret" "admin_jwt_secret" {
  name                    = "retailstore/dev/admin-jwt-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "admin_jwt_secret" {
  secret_id     = aws_secretsmanager_secret.admin_jwt_secret.id
  secret_string = var.admin_jwt_secret
}
