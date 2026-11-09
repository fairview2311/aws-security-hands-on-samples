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
        # 検証用の安全装置: 盗まれた認証情報が、この VPC（VPC エンドポイント
        # 経由の EC2）と自分の IP アドレス以外から使われたら拒否する
        Sid      = "OnlyFromVpcOrMyIp"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = var.allowed_cidr
          }
          StringNotEqualsIfExists = {
            "aws:SourceVpc" = aws_vpc.main.id
          }
          BoolIfExists = { "aws:ViaAWSService" = "false" }
        }
      },
    ]
  })
}

# Session Manager で接続するための、AWS 管理ポリシー
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project}-app"
  role = aws_iam_role.app.name
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = "t4g.micro"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.app.name

  # IMDSv2 だけを使う（トークンの無い GET を拒否する）
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
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
    aws_iam_role_policy_attachment.ssm,
    aws_vpc_endpoint.interface,
    aws_vpc_endpoint.s3,
  ]

  tags = { Name = "${var.project}-app" }
}
