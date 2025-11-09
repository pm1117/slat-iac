# RDS for PostgreSQL と DB サブネットグループ
resource "aws_db_subnet_group" "postgres" {
  name       = "${local.project}-${local.environment}-db-subnet"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-db-subnet"
  })
}

resource "aws_db_instance" "postgres" {
  identifier             = "${local.project}-${local.environment}-postgres"
  engine                 = "postgres"
  engine_version         = "16.10"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_name
  skip_final_snapshot    = true
  deletion_protection    = false
  publicly_accessible    = false
  backup_retention_period = 7
  max_allocated_storage  = 100

  tags = merge(local.common_tags, {
    Name = "${local.project}-${local.environment}-postgres"
  })
}

