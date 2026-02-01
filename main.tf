terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "study"
}

# VPC модуль
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-db-vpc"
}

# Пример использования модуля RDS
module "rds" {
  source = "./modules/rds"

  name       = "lesson-db"
  use_aurora = false # true for aurora (change to true to test Aurora)

  engine = "postgres" # aurora-postgresql when use_aurora=true
  # engine_version = "15.4"

  instance_class = "db.t3.micro"
  multi_az       = false

  db_name  = "appdb"
  username = "admin"
  password = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks = ["10.0.0.0/16"]

  # Якщо Terraform скаже що family null — задай явно:
  # parameter_group_family = "postgres15"

  tags = {
    Project = "lesson-db-module"
  }
}

variable "db_password" {
  type      = string
  sensitive = true
}

