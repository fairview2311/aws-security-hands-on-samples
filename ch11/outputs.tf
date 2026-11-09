output "app_url" {
  description = "顧客管理アプリの URL"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "instance_id" {
  value = aws_instance.app.id
}

output "cards_bucket" {
  value = aws_s3_bucket.cards.id
}

output "db_secret_arn" {
  description = "データベースのパスワードを入れたシークレット"
  value       = one(aws_db_instance.main.master_user_secret[*].secret_arn)
}

output "trail_bucket" {
  value = aws_s3_bucket.trail.id
}

output "flow_bucket" {
  value = aws_s3_bucket.flow_logs.id
}

output "waf_bucket" {
  value = aws_s3_bucket.waf_logs.id
}
