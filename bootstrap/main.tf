terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

module "s3_backend" {
  source = "../modules/s3-backend"

  bucket_name  = var.tf_state_bucket_name
  table_name   = var.tf_lock_table_name
  environment  = var.env
  project_name = var.project_name
}

