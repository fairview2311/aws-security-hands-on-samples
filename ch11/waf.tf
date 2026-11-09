# 自分の IP アドレス（検証用の安全装置。これ以外からのリクエストは WAF で拒否する）
resource "aws_wafv2_ip_set" "me" {
  provider           = aws.us_east_1
  name               = "${var.project}-me"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = [var.allowed_cidr]
}

resource "aws_wafv2_web_acl" "main" {
  provider = aws.us_east_1
  name     = "${var.project}-acl"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # 検証用の安全装置: 自分の IP アドレス以外を拒否する
  rule {
    name     = "OnlyMyIp"
    priority = 0

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.me.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "OnlyMyIp"
      sampled_requests_enabled   = true
    }
  }

  # XSS などの、よくある攻撃のルール
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    # ルールグループの判定（ブロック）をそのまま使う
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"

        # 名刺の画像のアップロード（8 KB を超える本文）は誤検知なので、カウントだけにする
        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # SQL インジェクションのルール
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # 1つの IP アドレスから1分間に100回を超えたら拒否する
  rule {
    name     = "RateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = 100
        evaluation_window_sec = 60
        aggregate_key_type    = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-acl"
    sampled_requests_enabled   = true
  }
}

# WAF のログを置くバケット（名前は aws-waf-logs- で始める決まり）
resource "aws_s3_bucket" "waf_logs" {
  provider      = aws.us_east_1
  bucket        = "aws-waf-logs-${var.project}-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  provider                = aws.us_east_1
  bucket                  = aws_s3_bucket.waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  provider                = aws.us_east_1
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_s3_bucket.waf_logs.arn]
}
