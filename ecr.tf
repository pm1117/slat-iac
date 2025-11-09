# ECR リポジトリ（NestJS 用・Python 用）
resource "aws_ecr_repository" "nestjs" {
  name                 = "${local.project}-${local.environment}-nestjs"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-nestjs-repo"
  })
}

resource "aws_ecr_repository" "python" {
  name                 = "${local.project}-${local.environment}-python"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-python-repo"
  })
}

