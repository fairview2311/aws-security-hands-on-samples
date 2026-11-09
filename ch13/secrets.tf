# アプリの IAM ロールに、この本で作る2つのシークレットだけを読む権限を付ける
resource "aws_iam_role_policy" "app_secrets" {
  name = "read-secrets"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "secretsmanager:GetSecretValue"
      Resource = [
        aws_db_instance.main.master_user_secret[0].secret_arn,
        aws_secretsmanager_secret.app_login.arn,
      ]
    }]
  })
}

# データベースのシークレットを読めるのは、アプリの IAM ロールだけにする
resource "aws_secretsmanager_secret_policy" "db" {
  secret_arn = aws_db_instance.main.master_user_secret[0].secret_arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "OnlyAppRoleCanRead"
      Effect    = "Deny"
      Principal = "*"
      Action    = "secretsmanager:GetSecretValue"
      Resource  = "*"
      Condition = {
        ArnNotEquals = { "aws:PrincipalArn" = aws_iam_role.app.arn }
        Bool         = { "aws:PrincipalIsAWSService" = "false" }
      }
    }]
  })
}

# アプリのログインのパスワード。Terraform が作るが、state には残さない
ephemeral "random_password" "app_login" {
  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "app_login" {
  name = "${var.project}/app-login"
  # 検証環境なので、待機期間なしですぐ削除する（本番は 7〜30 日の待機期間を残す）
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_login" {
  secret_id = aws_secretsmanager_secret.app_login.id
  # write-only の引数。値は AWS に送るだけで、state に保存しない
  secret_string_wo         = ephemeral.random_password.app_login.result
  secret_string_wo_version = 1
}
