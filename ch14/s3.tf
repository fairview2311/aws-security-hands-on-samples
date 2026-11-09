resource "random_id" "suffix" {
  byte_length = 4
}

# 名刺の画像を置くバケット
resource "aws_s3_bucket" "cards" {
  bucket        = "${var.project}-cards-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "cards" {
  bucket = aws_s3_bucket.cards.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 公開を許すポリシーと ACL を、すべて拒否する
resource "aws_s3_bucket_public_access_block" "cards" {
  bucket                  = aws_s3_bucket.cards.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 誰にも読み取りを許さない。HTTPS を使わない通信は拒否する
resource "aws_s3_bucket_policy" "cards" {
  bucket = aws_s3_bucket.cards.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.cards.arn,
        "${aws_s3_bucket.cards.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.cards]
}

# アプリのコードを EC2 に届けるためのバケット（公開しない）
resource "aws_s3_bucket" "deploy" {
  bucket        = "${var.project}-deploy-${random_id.suffix.hex}"
  force_destroy = true
}

data "archive_file" "app" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "${path.module}/.build/app.zip"
  excludes = [
    ".venv/**", ".venv311/**", ".cache/**", ".pytest_cache/**",
    "**/__pycache__/**", "tests/**", "requirements-test.txt",
    "config.ini", "session.env", ".gitignore",
  ]
}

resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.deploy.id
  # コードを直すとキーが変わり、EC2 が新しいコードで作り直される
  key    = "app-${data.archive_file.app.output_md5}.zip"
  source = data.archive_file.app.output_path
  # zip は大きく、分けて送られて ETag が MD5 と一致しないため、source_hash で変更を見る
  source_hash = data.archive_file.app.output_md5
}

# 既定の暗号化は SSE-S3。お客様が用意したキー（SSE-C）での書き込みは拒否する
resource "aws_s3_bucket_server_side_encryption_configuration" "cards" {
  bucket = aws_s3_bucket.cards.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
    bucket_key_enabled       = true
    blocked_encryption_types = ["SSE-C"]
  }
}
