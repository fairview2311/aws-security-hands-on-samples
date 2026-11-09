# バックアップを保管するボールト
resource "aws_backup_vault" "main" {
  name          = "${var.project}-vault"
  kms_key_arn   = aws_kms_key.main.arn
  force_destroy = true
}

# ボールトロック（ガバナンスモード）: 保持が1日より短い削除を拒否する
resource "aws_backup_vault_lock_configuration" "main" {
  backup_vault_name  = aws_backup_vault.main.name
  min_retention_days = 1
  max_retention_days = 35
}

# AWS Backup が使う IAM ロール
resource "aws_iam_role" "backup" {
  name = "${var.project}-backup"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# 毎日バックアップを取り、7日間保持する
resource "aws_backup_plan" "main" {
  name = "${var.project}-plan"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 18 * * ? *)"

    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "db" {
  name         = "${var.project}-db"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn
  resources    = [aws_db_instance.main.arn]
}
