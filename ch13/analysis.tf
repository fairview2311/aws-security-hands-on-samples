# VPC フローログを置くバケット
resource "aws_s3_bucket" "flow_logs" {
  bucket        = "${var.project}-flow-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket                  = aws_s3_bucket.flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# VPC の中の通信の記録を、1分ごとにまとめて S3 に送る
resource "aws_flow_log" "main" {
  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  log_destination_type     = "s3"
  log_destination          = aws_s3_bucket.flow_logs.arn
  max_aggregation_interval = 60
}

# Athena のクエリの結果を置くバケット
resource "aws_s3_bucket" "athena" {
  bucket        = "${var.project}-athena-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "athena" {
  bucket                  = aws_s3_bucket.athena.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_athena_workgroup" "main" {
  name          = var.project
  force_destroy = true

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena.id}/results/"
    }
  }
}
