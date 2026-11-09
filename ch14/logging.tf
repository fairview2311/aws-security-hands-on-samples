data "aws_caller_identity" "current" {}

# CloudTrail のログを置くバケット（公開しない）
resource "aws_s3_bucket" "trail" {
  bucket        = "${var.project}-trail-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail だけがログを書き込めるようにする
# ログを書き込めるのを、この証跡の CloudTrail だけに限定する
locals {
  trail_arn = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${var.project}-trail"
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.trail.arn
        Condition = {
          StringEquals = { "aws:SourceArn" = local.trail_arn }
        }
      },
      {
        Sid       = "Write"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource = "${aws_s3_bucket.trail.arn}/AWSLogs/${
        data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.trail.arn,
          "${aws_s3_bucket.trail.arn}/*",
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
    ]
  })
}

# すべてのリージョンの操作を記録する証跡
resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-trail"
  s3_bucket_name                = aws_s3_bucket.trail.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  # 名刺のバケットの読み書きも記録する（データイベント）
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.cards.arn}/"]
    }
  }

  depends_on = [aws_s3_bucket_policy.trail]
}

# 外部から使える権限を見つける（無料）
resource "aws_accessanalyzer_analyzer" "account" {
  analyzer_name = "${var.project}-analyzer"
  type          = "ACCOUNT"
}
