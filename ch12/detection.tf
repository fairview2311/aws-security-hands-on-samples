# 脅威を検出する GuardDuty を有効にする
resource "aws_guardduty_detector" "main" {
  enable = true
}

# 通知先の SNS トピック
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

# EventBridge から SNS へ発行することを許す
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridge"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.alerts.arn
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
}

# メールの宛先（確認のメールのリンクを押すと、届くようになる）
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 重要度が中以上の検出結果を SNS に送る
resource "aws_cloudwatch_event_rule" "guardduty" {
  name = "${var.project}-guardduty"
  event_pattern = jsonencode({
    source        = ["aws.guardduty"]
    "detail-type" = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 4] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule = aws_cloudwatch_event_rule.guardduty.name
  arn  = aws_sns_topic.alerts.arn
}

# サンプルの検出結果を作るときに使う検出器の ID
output "detector_id" {
  value = aws_guardduty_detector.main.id
}

# 対応しないと決めた検出結果を、自動でアーカイブする抑制ルール
resource "aws_guardduty_filter" "suppress_port_probe" {
  name        = "suppress-port-probe"
  action      = "ARCHIVE"
  detector_id = aws_guardduty_detector.main.id
  rank        = 1

  finding_criteria {
    criterion {
      field  = "type"
      equals = ["Recon:EC2/PortProbeUnprotectedPort"]
    }

    # サンプルの検出結果だけを対象にする（実際の検出は隠さない）
    criterion {
      field  = "service.additionalInfo.sample"
      equals = ["true"]
    }
  }
}
