# Terraform RDS Module (Aurora or Standard RDS)

This project contains a reusable Terraform module `modules/rds` that can create:

- **Standard RDS instance** (PostgreSQL/MySQL)
- **OR Aurora cluster + writer instance** (Aurora PostgreSQL / Aurora MySQL)

Switch is controlled by `use_aurora` flag.

## How to use

### Example: Standard RDS PostgreSQL

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "lesson-db"
  use_aurora = false

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro"
  multi_az       = false

  db_name  = "appdb"
  username = "admin"
  password = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks = ["10.0.0.0/16"]

  # Optional if engine cannot be inferred
  # parameter_group_family = "postgres15"

  tags = {
    Project = "lesson-db-module"
  }
}

variable "db_password" {
  type      = string
  sensitive = true
}
```

### Example: Aurora PostgreSQL

```hcl
module "rds" {
  source = "./modules/rds"

  name       = "lesson-db"
  use_aurora = true

  engine         = "aurora-postgresql"
  engine_version = "15.4"
  instance_class = "db.t3.micro"

  db_name  = "appdb"
  username = "admin"
  password = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks = ["10.0.0.0/16"]

  # Optional if engine cannot be inferred
  # parameter_group_family = "aurora-postgresql15"

  tags = {
    Project = "lesson-db-module"
  }
}
```

## Variables

### Required Variables

- **name** (string): Base name/prefix for DB resources (will be used in identifiers)
- **vpc_id** (string): VPC id where DB will be deployed
- **subnet_ids** (list(string)): Private subnet ids for DB subnet group
- **password** (string, sensitive): Master password

### Root Variables (in main.tf)

- **aws_region** (string, default: `"us-west-2"`): AWS region for resources
- **aws_profile** (string, default: `"study"`): AWS profile to use
- **db_password** (string, sensitive): Master password for database

### Module Variables (in modules/rds)

- **use_aurora** (bool, default: `false`): If `true` → Aurora cluster + writer, if `false` → standard RDS instance
- **engine** (string, default: `"postgres"`): DB engine. For RDS: `postgres`/`mysql`. For Aurora: `aurora-postgresql`/`aurora-mysql`
- **engine_version** (string, default: `null`): Engine version (e.g. `15.4` for postgres, `8.0` for mysql, or matching Aurora version)
- **instance_class** (string, default: `"db.t3.micro"`): Instance class (e.g. `db.t3.micro`). For Aurora this will be used for the writer instance
- **multi_az** (bool, default: `false`): Enable Multi-AZ for standard RDS instance (ignored for Aurora)
- **allocated_storage** (number, default: `20`): Allocated storage in GB for standard RDS instance (ignored for Aurora)
- **storage_type** (string, default: `"gp3"`): Storage type for standard RDS instance (`gp2`/`gp3`/`io1`)
- **db_name** (string, default: `"appdb"`): Initial DB name
- **username** (string, default: `"admin"`): Master username
- **port** (number, default: `null`): DB port. If null, module will pick common defaults (5432 for PostgreSQL, 3306 for MySQL)
- **allowed_cidr_blocks** (list(string), default: `[]`): CIDR blocks allowed to access DB port (ingress)
- **allowed_security_group_ids** (list(string), default: `[]`): Security group IDs allowed to access DB port (ingress)
- **parameter_group_family** (string, default: `null`): Parameter group family (e.g. `postgres15`, `mysql8.0`, `aurora-postgresql15`). If null, module will try basic mapping
- **parameters** (map(string), default: see below): Map of DB parameters to set in parameter group
  - Default: `max_connections = "200"`, `log_statement = "none"`, `work_mem = "4096"`
- **apply_immediately** (bool, default: `true`): Apply changes immediately (may cause downtime)
- **backup_retention_period** (number, default: `1`): Backup retention in days
- **skip_final_snapshot** (bool, default: `true`): Skip final snapshot on destroy
- **deletion_protection** (bool, default: `false`): Enable deletion protection
- **tags** (map(string), default: `{}`): Tags to apply to all resources

## Change DB type / Engine

### Standard PostgreSQL:
```hcl
use_aurora = false
engine = "postgres"
parameter_group_family = "postgres15" # if needed
```

**Parameter Group Families for PostgreSQL:**
- `postgres15` - PostgreSQL 15.x
- `postgres14` - PostgreSQL 14.x
- `postgres13` - PostgreSQL 13.x
- `postgres12` - PostgreSQL 12.x

### Standard MySQL:
```hcl
use_aurora = false
engine = "mysql"
parameter_group_family = "mysql8.0" # if needed
```

**Parameter Group Families for MySQL:**
- `mysql8.0` - MySQL 8.0.x
- `mysql5.7` - MySQL 5.7.x

### Aurora PostgreSQL:
```hcl
use_aurora = true
engine = "aurora-postgresql"
parameter_group_family = "aurora-postgresql15" # if needed
```

**Parameter Group Families for Aurora PostgreSQL:**
- `aurora-postgresql15` - Aurora PostgreSQL 15.x
- `aurora-postgresql14` - Aurora PostgreSQL 14.x
- `aurora-postgresql13` - Aurora PostgreSQL 13.x
- `aurora-postgresql12` - Aurora PostgreSQL 12.x

### Aurora MySQL:
```hcl
use_aurora = true
engine = "aurora-mysql"
parameter_group_family = "aurora-mysql8.0" # if needed
```

**Parameter Group Families for Aurora MySQL:**
- `aurora-mysql8.0` - Aurora MySQL 8.0.x
- `aurora-mysql5.7` - Aurora MySQL 5.7.x

**⚠️ Important:** 
- If `use_aurora = true`, `engine` MUST start with `aurora-` (e.g. `aurora-postgresql`, `aurora-mysql`)
- If `use_aurora = false`, `engine` MUST NOT start with `aurora-` (e.g. `postgres`, `mysql`)
- The module includes validation to enforce this rule

## Module Features

- **Conditional creation**: Creates Aurora cluster OR standard RDS instance based on `use_aurora`
- **Automatic resources**: Always creates:
  - DB Subnet Group
  - Security Group (with configurable ingress rules)
  - Parameter Group (with configurable parameters: max_connections, log_statement, work_mem)
- **Flexible configuration**: Supports PostgreSQL/MySQL and Aurora variants
- **Parameter management**: Configurable parameter group with sensible defaults
- **Port auto-detection**: Automatically selects correct port (5432 for PostgreSQL, 3306 for MySQL)

## Outputs

- **endpoint** (string): Database endpoint (cluster endpoint for Aurora, instance address for RDS)
- **port** (number): Database port
- **security_group_id** (string): DB Security Group ID
- **subnet_group_name** (string): DB Subnet Group name
- **resource_id** (string): RDS instance id or Aurora cluster id

## Commands

```bash
# Initialize Terraform
terraform init

# Plan for standard RDS
terraform plan -var="db_password=YourStrongPassword"

# Plan for Aurora (set use_aurora = true in main.tf)
terraform plan -var="db_password=YourStrongPassword"

# Apply changes
terraform apply -var="db_password=YourStrongPassword"

# Destroy infrastructure
terraform destroy -var="db_password=YourStrongPassword"
```

**⚠️ After verification, don't forget to run `terraform destroy` to avoid AWS charges.**

## Project Structure

```
.
├── main.tf                  # Main file with module usage
├── backend.tf               # Backend configuration (S3 + DynamoDB)
├── outputs.tf              # Root outputs
│
├── modules/
│   ├── vpc/                # VPC module
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── rds/                # RDS module
│       ├── rds.tf          # Standard RDS instance
│       ├── aurora.tf       # Aurora cluster + writer
│       ├── shared.tf       # Shared resources (Subnet Group, SG, Parameter Group)
│       ├── variables.tf    # Module variables
│       └── outputs.tf      # Module outputs
```

## Troubleshooting

### Error: "parameter_group_family is null"

If Terraform reports that `parameter_group_family` is null, explicitly set it:

```hcl
parameter_group_family = "postgres15"  # or "mysql8.0", "aurora-postgresql15", etc.
```

### Error: "engine version not supported"

Check available engine versions for your region:
```bash
aws rds describe-db-engine-versions --engine postgres --region us-west-2
```

## Author

Nellipestych

## License

Educational project for GoIT Neoversity
