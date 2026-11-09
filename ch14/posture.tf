# 新しい Security Hub を有効にする
resource "aws_securityhub_account_v2" "main" {}

# Security Hub CSPM を有効にし、FSBP の基準で点検する
resource "aws_securityhub_account" "main" {
  enable_default_standards = false
  depends_on               = [aws_securityhub_account_v2.main]
}

resource "aws_securityhub_standards_subscription" "fsbp" {
  standards_arn = "arn:aws:securityhub:${var.region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# S3.5: デプロイ用のバケットでも HTTPS 以外の通信を拒否する
resource "aws_s3_bucket_policy" "deploy" {
  bucket = aws_s3_bucket.deploy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.deploy.arn,
        "${aws_s3_bucket.deploy.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

# S3.5: Athena の結果のバケットでも HTTPS 以外の通信を拒否する
resource "aws_s3_bucket_policy" "athena" {
  bucket = aws_s3_bucket.athena.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.athena.arn,
        "${aws_s3_bucket.athena.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

# S3.5: VPC フローログのバケット。ログの配信に必要な許可も一緒に書く
resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.flow_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = { "aws:SourceArn" = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*" }
        }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.flow_logs.arn
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
          ArnLike      = { "aws:SourceArn" = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*" }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.flow_logs.arn,
          "${aws_s3_bucket.flow_logs.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })

  # フローログの作成時に AWS が付けるポリシーで上書きされないよう、後から設定する
  depends_on = [aws_flow_log.main]
}

# S3.5: WAF のログのバケット。WAF のログは us-east-1 に配信される
resource "aws_s3_bucket_policy" "waf_logs" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.waf_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.waf_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = { "aws:SourceArn" = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*" }
        }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.waf_logs.arn
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
          ArnLike      = { "aws:SourceArn" = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*" }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.waf_logs.arn,
          "${aws_s3_bucket.waf_logs.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })

  # WAF のログの設定で AWS が付けるポリシーで上書きされないよう、後から設定する
  depends_on = [aws_wafv2_web_acl_logging_configuration.main]
}

# RDS.5（マルチ AZ）: 検証環境では料金を抑えるため対象外にする
resource "aws_securityhub_standards_control" "rds_multi_az" {
  standards_control_arn = "arn:aws:securityhub:${var.region}:${data.aws_caller_identity.current.account_id}:control/aws-foundational-security-best-practices/v/1.0.0/RDS.5"
  control_status        = "DISABLED"
  disabled_reason       = "検証環境のため、マルチ AZ の料金をかけない"
  depends_on            = [aws_securityhub_standards_subscription.fsbp]
}
