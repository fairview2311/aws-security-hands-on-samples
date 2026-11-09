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

# 演習用の脆弱性（第6章で直す）。バケットのブロックパブリックアクセスを外している
resource "aws_s3_bucket_public_access_block" "cards" {
  bucket                  = aws_s3_bucket.cards.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 演習用の脆弱性（第6章で直す）。認証なしで画像を読めるバケットポリシー。
# 本番の事故では Principal "*" だけで世界中に公開される。ここでは安全のため、
# 読めるのを自分の IP アドレスに限っている
resource "aws_s3_bucket_policy" "cards_public" {
  bucket = aws_s3_bucket.cards.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.cards.arn}/*"
      Condition = {
        IpAddress = { "aws:SourceIp" = var.allowed_cidr }
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
