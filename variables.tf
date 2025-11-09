# 変数定義（リージョン、サブネット CIDR、コンテナイメージ URI、DB 認証情報など）
variable "project_name" {
  description = "プロジェクト名（タグなどに使用）"
  type        = string
  default     = "slat"
}

variable "environment" {
  description = "環境名（dev/stg/prod など）"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネットの CIDR 一覧"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネットの CIDR 一覧"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "allowed_api_cidrs" {
  description = "API（ALB）へアクセスを許可する CIDR"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_username" {
  description = "PostgreSQL のユーザー名"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL のパスワード"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL のデフォルト DB 名"
  type        = string
  default     = "slat"
}

variable "db_instance_class" {
  description = "RDS インスタンスクラス"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS のストレージサイズ (GiB)"
  type        = number
  default     = 20
}

variable "nestjs_image" {
  description = "NestJS API のコンテナイメージ URI"
  type        = string
}

variable "nestjs_desired_count" {
  description = "NestJS サービスの希望タスク数"
  type        = number
  default     = 2
}

variable "nestjs_container_port" {
  description = "NestJS コンテナのリッスンポート"
  type        = number
  default     = 3000
}

variable "python_image" {
  description = "姿勢分析 Python サービスのコンテナイメージ URI"
  type        = string
}

variable "python_desired_count" {
  description = "Python サービスの希望タスク数"
  type        = number
  default     = 1
}

variable "python_container_port" {
  description = "Python コンテナのリッスンポート"
  type        = number
  default     = 8000
}


