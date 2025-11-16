
# ECS クラスター、Fargate サービス、タスク定義、CloudWatch Logs、ALB リスナー・ターゲットグループ
# NestJS API をコンテナ化して AWS Fargate（ECS on Fargate）で動かすと、EC2 の管理から解放される。ALB と組み合わせてスケールアウト／SSL 終端も簡単。
# 「リクエスト頻度が高い／常時稼働が必要」「処理内容の重さが読みきれない」などの要因を想定し、まずは Fargate ベースで API サーバーを作る。
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.project}/${local.environment}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-ecs-logs"
  })
}

resource "aws_ecs_cluster" "this" {
  name = "${local.project}-${local.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.project}-${local.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb" "api" {
  name               = "${local.project}-${local.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-alb"
  })
}

resource "aws_lb_target_group" "nestjs" {
  name        = "${local.project}-${local.environment}-nestjs"
  port        = var.nestjs_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-nestjs-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nestjs.arn
  }
}

resource "aws_ecs_task_definition" "nestjs" {
  family                   = "${local.project}-${local.environment}-nestjs"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "nestjs"
      image     = var.nestjs_image
      essential = true
      portMappings = [
        {
          containerPort = var.nestjs_container_port
          hostPort      = var.nestjs_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DATABASE_HOST", value = aws_db_instance.postgres.address },
        { name = "DATABASE_PORT", value = tostring(aws_db_instance.postgres.port) },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USER", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "nestjs"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-nestjs-td"
  })

  depends_on = [aws_db_instance.postgres]
}

resource "aws_ecs_task_definition" "python" {
  family                   = "${local.project}-${local.environment}-python"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "python"
      image     = var.python_image
      essential = true
      portMappings = [
        {
          containerPort = var.python_container_port
          hostPort      = var.python_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DATABASE_HOST", value = aws_db_instance.postgres.address },
        { name = "DATABASE_PORT", value = tostring(aws_db_instance.postgres.port) },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USER", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "python"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-python-td"
  })

  depends_on = [aws_db_instance.postgres]
}

resource "aws_ecs_service" "nestjs" {
  name            = "${local.project}-${local.environment}-nestjs"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.nestjs.arn
  desired_count   = var.nestjs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [for subnet in aws_subnet.private : subnet.id]
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nestjs.arn
    container_name   = "nestjs"
    container_port   = var.nestjs_container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-nestjs-svc"
  })

  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "python" {
  name            = "${local.project}-${local.environment}-python"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.python.arn
  desired_count   = var.python_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [for subnet in aws_subnet.private : subnet.id]
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-python-svc"
  })
}

# GitHub Actions など外部から直接 RDS へ入らず、同一 VPC 内で安全に Prisma の migrate を実行するため。
resource "aws_ecs_task_definition" "migration" {
  family                   = "${local.project}-${local.environment}-migration"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "migration"
      image     = local.migration_image
      essential = true
      command   = ["sh", "-c", var.migration_command]
      environment = [
        { name = "DATABASE_HOST", value = aws_db_instance.postgres.address },
        { name = "DATABASE_PORT", value = tostring(aws_db_instance.postgres.port) },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USER", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "migration"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-migration-td"
  })

  depends_on = [aws_db_instance.postgres]
}

# Lambda + Step Functions
# 得意なこと-> イベント駆動（S3アップロード、API Gateway、EventBridge、キューなど）で瞬時に起動し、短時間の処理をさっと実行。
# 適したユースケース-> 処理がバースト的・低頻度・定型的。
# 注意点-> 1 実行 15 分以内（現行の制約）。メモリと CPU（最大 10GB / 6 vCPU）の上限。コンテナとは違い、長時間の処理や状態保持には不向き。
# Fargate + EventBridge
# 得意なこと-> 任意の Docker コンテナを、サーバーレス基盤上で常駐サービスとして動かす。
# 適したユースケース-> 常に稼働している API やマイクロサービス。ジョブの処理時間が長い、または並列で大量に動かす必要がある。コールドスタートを避けたい／オンメモリキャッシュを使いたい。
# 注意点-> タスクが走っている限りリソース課金が発生。Task 定義や ALB、セキュリティグループなど周辺設定が Lambda より多い。