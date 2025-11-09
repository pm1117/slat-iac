# ALB／ECS タスク／RDS 向けセキュリティグループ

# Application Load Balancer (ALB)
# NestJS API を外部へ公開するための HTTP エントリポイント。リクエストを ECS タスクへ振り分け、将来的に HTTPS 化やパスごとのルーティングを追加しやすい構成です。
resource "aws_security_group" "alb" {
  name        = "${local.project}-${local.environment}-alb-sg"
  description = "Allow inbound access to ALB"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allowed_api_cidrs
    content {
      description = "Allow HTTP from ${ingress.value}"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-alb-sg"
  })
}

# ECS（Fargate）クラスター & サービス
# NestJS API と Python 姿勢分析をコンテナとしてデプロイ。Fargate を使うことで EC2 の管理が不要になり、スケーリングや OS パッチ適用の手間を削減できます。
# それぞれのサービスを分離することで、独立したスケール設定やデプロイが可能です。
resource "aws_security_group" "ecs_service" {
  name        = "${local.project}-${local.environment}-ecs-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow ALB to reach service"
    from_port       = var.nestjs_container_port
    to_port         = var.nestjs_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Allow ECS tasks to communicate internally on Python port"
    from_port   = var.python_container_port
    to_port     = var.python_container_port
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-ecs-sg"
  })
}

resource "aws_security_group" "rds" {
  name        = "${local.project}-${local.environment}-rds-sg"
  description = "Allow DB access from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_service.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-rds-sg"
  })
}

