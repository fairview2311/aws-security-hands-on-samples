# 名刺の画像・データベース・EC2 のディスクを暗号化するカスタマー管理キー
resource "aws_kms_key" "main" {
  description             = "${var.project} data key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project}"
  target_key_id = aws_kms_key.main.key_id
}
