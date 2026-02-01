output "rds_endpoint" {
  description = "Database endpoint"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "Database port"
  value       = module.rds.port
}

output "rds_security_group_id" {
  description = "DB Security Group ID"
  value       = module.rds.security_group_id
}

output "rds_resource_id" {
  description = "RDS instance id or Aurora cluster id"
  value       = module.rds.resource_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

