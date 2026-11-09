resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project}-db"
  engine            = "postgres"
  engine_version    = "18.6"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_encrypted = true

  db_name  = "customers"
  username = "app_admin"
  # パスワードは RDS が作り、Secrets Manager に保存して7日ごとにローテーションする
  manage_master_user_password = true
  # 変更をメンテナンスウィンドウまで待たずに、すぐ反映する
  apply_immediately = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
}
