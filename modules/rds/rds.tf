resource "aws_db_instance" "main" {
  identifier            = "${var.project_name}-rds"
  engine                = "postgres"
  engine_version        = "15.4"
  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot        = true
  deletion_protection        = false
  publicly_accessible        = false
  multi_az                   = false
  auto_minor_version_upgrade = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "${var.project_name}-rds"
    Environment = var.environment
    Project     = var.project_name
  }
}
