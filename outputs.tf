# 主要リソースのアウトプット（VPC ID、ALB DNS、RDS エンドポイント等）
output "vpc_id" {
  description = "作成した VPC の ID"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "NestJS API 用 ALB の DNS 名"
  value       = aws_lb.api.dns_name
}

output "rds_endpoint" {
  description = "PostgreSQL RDS のエンドポイント"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "PostgreSQL RDS のポート"
  value       = aws_db_instance.postgres.port
}

