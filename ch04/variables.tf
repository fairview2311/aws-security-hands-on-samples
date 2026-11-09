variable "region" {
  description = "リソースを作るリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "タグとリソース名に付ける名前"
  type        = string
  default     = "aws-security-book"
}

variable "allowed_cidr" {
  description = "アクセスを許可する自分の IP アドレス（例 203.0.113.10/32）"
  type        = string

  # 穴のある環境を世界に公開しないよう、IP アドレス1つ（/32）だけを受け付ける
  validation {
    condition = (
      can(cidrhost(var.allowed_cidr, 0)) &&
      endswith(var.allowed_cidr, "/32")
    )
    error_message = "自分の IP アドレスを 203.0.113.10/32 の形で書いてください。"
  }
}

variable "ami_id" {
  description = "EC2 の AMI（本で確かめた Amazon Linux 2023 arm64。東京リージョン）"
  type        = string
  default     = "ami-0726b213222e0072c"
}

variable "ssh_public_key" {
  description = "EC2 に SSH で入るための公開鍵（第7章で使わなくなる）"
  type        = string
}
