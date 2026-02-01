locals {
  is_aurora = var.use_aurora

  # Common default ports
  default_port = (
    contains(["mysql", "aurora-mysql"], var.engine) ? 3306 :
    contains(["postgres", "aurora-postgresql"], var.engine) ? 5432 :
    5432
  )

  db_port = coalesce(var.port, local.default_port)

  # Family names differ by engine:
  # - Postgres / aurora-postgresql use only MAJOR version (e.g. postgres16, aurora-postgresql16)
  # - MySQL / aurora-mysql use MAJOR.MINOR (e.g. mysql8.0, aurora-mysql8.0)
  engine_version_parts = var.engine_version != null ? split(".", var.engine_version) : []
  major                = length(local.engine_version_parts) > 0 ? local.engine_version_parts[0] : "15"
  major_minor          = length(local.engine_version_parts) >= 2 ? "${local.engine_version_parts[0]}.${local.engine_version_parts[1]}" : local.major

  is_mysql_family = can(regex("mysql", var.engine))
  family_suffix   = local.is_mysql_family ? local.major_minor : local.major

  # Build family name: engine + version suffix
  # For postgres: postgres15, postgres16, etc.
  # For mysql: mysql8.0, mysql5.7, etc.
  # For aurora-postgresql: aurora-postgresql15, aurora-postgresql16, etc.
  # For aurora-mysql: aurora-mysql8.0, aurora-mysql5.7, etc.
  computed_family = "${var.engine}${local.family_suffix}"

  # Use explicit parameter_group_family if provided, otherwise use computed family
  # If engine_version is null, fall back to inferred defaults
  inferred_family = (
    var.engine_version != null ? local.computed_family : (
      local.is_aurora && var.engine == "aurora-postgresql" ? "aurora-postgresql15" :
      local.is_aurora && var.engine == "aurora-mysql" ? "aurora-mysql8.0" :
      (!local.is_aurora && var.engine == "postgres") ? "postgres15" :
      (!local.is_aurora && var.engine == "mysql") ? "mysql8.0" :
      null
    )
  )

  param_family = coalesce(var.parameter_group_family, local.inferred_family)
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnets"
  })
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Security group for ${var.name} database"
  vpc_id      = var.vpc_id

  # Allow from CIDRs
  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      description = "DB access from CIDR"
      from_port   = local.db_port
      to_port     = local.db_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Allow from other SGs
  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "DB access from SG"
      from_port       = local.db_port
      to_port         = local.db_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-db-sg"
  })
}

# Parameter group: for RDS use aws_db_parameter_group; for Aurora use aws_rds_cluster_parameter_group
resource "aws_db_parameter_group" "rds" {
  count  = local.is_aurora ? 0 : 1
  name   = "${var.name}-rds-pg"
  family = local.param_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-rds-pg" })
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  count  = local.is_aurora ? 1 : 0
  name   = "${var.name}-aurora-pg"
  family = local.param_family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(var.tags, { Name = "${var.name}-aurora-pg" })
}
