variable "name" {
  description = "Base name/prefix for DB resources (will be used in identifiers)."
  type        = string
}

variable "use_aurora" {
  description = "If true - create Aurora cluster + writer instance. If false - create standard RDS instance."
  type        = bool
  default     = false
}

variable "engine" {
  description = "DB engine. For RDS: postgres/mysql. For Aurora: aurora-postgresql/aurora-mysql."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version (e.g. 15.4 for postgres, 8.0 for mysql, or matching Aurora version)."
  type        = string
  default     = null
}

variable "instance_class" {
  description = "Instance class (e.g. db.t3.micro). For Aurora this will be used for the writer instance."
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Enable Multi-AZ for standard RDS instance (ignored for Aurora)."
  type        = bool
  default     = false
}

variable "allocated_storage" {
  description = "Allocated storage in GB for standard RDS instance (ignored for Aurora)."
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Storage type for standard RDS instance (gp2/gp3/io1)."
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Initial DB name."
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username."
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Master password."
  type        = string
  sensitive   = true
}

variable "port" {
  description = "DB port. If null, module will pick common defaults."
  type        = number
  default     = null
}

variable "vpc_id" {
  description = "VPC id where DB will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet ids for DB subnet group."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access DB port (ingress)."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access DB port (ingress)."
  type        = list(string)
  default     = []
}

variable "parameter_group_family" {
  description = "Parameter group family (e.g. postgres15, mysql8.0, aurora-postgresql15). If null, module will try basic mapping."
  type        = string
  default     = null
}

variable "parameters" {
  description = "Map of DB parameters to set in parameter group."
  type        = map(string)
  default = {
    max_connections = "200"
    log_statement   = "none"
    work_mem        = "4096"
  }
}

variable "apply_immediately" {
  description = "Apply changes immediately (may cause downtime)."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention in days."
  type        = number
  default     = 1
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

