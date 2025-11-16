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

# AWS CLI やワークフローから run-task を組み立てやすくする。
output "private_subnet_ids" {
  description = "プライベートサブネットの ID 一覧"
  value       = [for subnet in aws_subnet.private : subnet.id]
}
output "ecs_service_security_group_id" {
  description = "ECS サービス／マイグレーションタスクで利用するセキュリティグループ ID"
  value       = aws_security_group.ecs_service.id
}
output "ecs_cluster_name" {
  description = "ECS クラスター名"
  value       = aws_ecs_cluster.this.name
}
output "migration_task_definition_arn" {
  description = "マイグレーション用 ECS タスク定義 ARN"
  value       = aws_ecs_task_definition.migration.arn
}
