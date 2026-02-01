output "endpoint" {
  description = "Database endpoint"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "port" {
  description = "Database port"
  value       = local.db_port
}

output "security_group_id" {
  description = "DB Security Group ID"
  value       = aws_security_group.db.id
}

output "subnet_group_name" {
  description = "DB Subnet Group name"
  value       = aws_db_subnet_group.this.name
}

output "resource_id" {
  description = "RDS instance id or Aurora cluster id"
  value       = var.use_aurora ? aws_rds_cluster.this[0].id : aws_db_instance.this[0].id
}

