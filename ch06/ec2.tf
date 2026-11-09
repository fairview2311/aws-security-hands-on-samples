resource "aws_key_pair" "app" {
  key_name   = "${var.project}-key"
  public_key = var.ssh_public_key
}

resource "aws_iam_role" "app" {
  name = "${var.project}-app"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# アプリと起動スクリプトが使う操作だけを許す
resource "aws_iam_role_policy" "app" {
  name = "least-privilege"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 名刺とロゴの画像を置き、署名付き URL で見せる（削除は許さない）
        Sid    = "PutAndGetImages"
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.cards.arn}/cards/*",
          "${aws_s3_bucket.cards.arn}/logos/*",
        ]
      },
      {
        # 起動スクリプトが、アプリの zip を1つ取り出すだけ
        Sid      = "GetAppZip"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.deploy.arn}/${aws_s3_object.app.key}"
      },
      {
        # 検証用の安全装置: 盗まれた認証情報が、EC2 と自分の IP アドレス
        # 以外から使われたら拒否する（本の演習を自分の環境に閉じ込める）
        Sid      = "OnlyFromInstanceOrMyIp"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = [var.allowed_cidr, "${aws_eip.app.public_ip}/32"]
          }
          BoolIfExists = { "aws:ViaAWSService" = "false" }
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project}-app"
  role = aws_iam_role.app.name
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = "t4g.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.app.key_name
  iam_instance_profile   = aws_iam_instance_profile.app.name

  # 演習用の脆弱性（第7章で直す）。IMDSv1 を許している
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    region     = var.region
    deploy_obj = "s3://${aws_s3_bucket.deploy.id}/${aws_s3_object.app.key}"
    db_host    = aws_db_instance.main.address
    db_secret  = aws_db_instance.main.master_user_secret[0].secret_arn
    bucket     = aws_s3_bucket.cards.id
    app_login  = aws_secretsmanager_secret.app_login.arn
  })
  user_data_replace_on_change = true

  # 権限が付いてから起動する（起動スクリプトが S3 からコードを取るため）
  depends_on = [
    aws_iam_role_policy.app,
    aws_iam_role_policy.app_secrets,
    aws_secretsmanager_secret_version.app_login,
    aws_route_table_association.public,
  ]

  tags = { Name = "${var.project}-app" }
}

# EC2 の固定の IP アドレス（上の安全装置で、EC2 からの API の呼び出しを許すために使う）
resource "aws_eip" "app" {
  domain = "vpc"
}

resource "aws_eip_association" "app" {
  allocation_id = aws_eip.app.id
  instance_id   = aws_instance.app.id
}
