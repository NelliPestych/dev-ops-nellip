# Aurora Serverless v2 cluster (опціонально, якщо потрібен Aurora)
# Розкоментуйте, якщо хочете використовувати Aurora замість RDS

# resource "aws_rds_cluster" "aurora" {
#   cluster_identifier      = "${var.project_name}-aurora-cluster"
#   engine                  = "aurora-postgresql"
#   engine_version          = "15.4"
#   database_name           = var.db_name
#   master_username         = var.db_username
#   master_password         = var.db_password
#   db_subnet_group_name    = aws_db_subnet_group.main.name
#   vpc_security_group_ids  = var.security_group_ids
#   storage_encrypted        = true
#   skip_final_snapshot     = true
#   deletion_protection     = false
#   enabled_cloudwatch_logs_exports = ["postgresql"]
#
#   serverlessv2_scaling_configuration {
#     max_capacity = 2
#     min_capacity = 0.5
#   }
#
#   tags = {
#     Name        = "${var.project_name}-aurora-cluster"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }
#
# resource "aws_rds_cluster_instance" "aurora" {
#   identifier         = "${var.project_name}-aurora-instance-1"
#   cluster_identifier = aws_rds_cluster.aurora.id
#   instance_class     = "db.serverless"
#   engine             = aws_rds_cluster.aurora.engine
#   engine_version     = aws_rds_cluster.aurora.engine_version
#
#   tags = {
#     Name        = "${var.project_name}-aurora-instance-1"
#     Environment = var.environment
#     Project     = var.project_name
#   }
# }
