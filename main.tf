# AWS プロバイダ設定、共通タグ用 locals など基盤共通設定
provider "aws" {
  region = var.aws_region
}

locals {
  project     = var.project_name
  environment = var.environment

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}