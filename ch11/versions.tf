terraform {
  required_version = ">= 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.72"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = var.region

  # 本で作るものすべてに同じタグを付ける（最後にタグで探して削除する）
  default_tags {
    tags = {
      Project = var.project
    }
  }
}

# CloudFront 用の AWS WAF とそのログは、米国東部（バージニア北部）に作る
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project = var.project
    }
  }
}
