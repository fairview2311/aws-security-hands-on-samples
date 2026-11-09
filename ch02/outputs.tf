output "app_url" {
  description = "顧客管理アプリの URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "instance_id" {
  value = aws_instance.app.id
}

output "instance_public_ip" {
  value = aws_eip.app.public_ip
}

output "cards_bucket" {
  value = aws_s3_bucket.cards.id
}
