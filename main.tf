terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Модуль VPC
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  project_name       = var.project_name
}

# Модуль ECR
module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
  environment     = var.environment
  project_name    = var.project_name
}

# Модуль EKS
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.eks_cluster_name
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  environment     = var.environment
  node_group_size = var.eks_node_group_size
  project_name    = var.project_name

  depends_on = [module.vpc]
}

# Модуль RDS
module "rds" {
  source = "./modules/rds"

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.database_subnet_ids
  security_group_ids = [module.vpc.database_security_group_id]
  environment        = var.environment
  db_instance_class  = var.rds_instance_class
  db_name            = var.rds_db_name
  db_username        = var.rds_username
  db_password        = var.rds_password
  project_name       = var.project_name

  depends_on = [module.vpc]
}

# Модуль Jenkins
module "jenkins" {
  source = "./modules/jenkins"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca       = module.eks.cluster_ca
  aws_region       = var.aws_region
  chart_version    = var.jenkins_chart_version
}

# Модуль Argo CD
module "argo_cd" {
  source = "./modules/argo_cd"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca       = module.eks.cluster_ca
  aws_region       = var.aws_region
  chart_version    = var.argocd_chart_version
}

# Модуль Monitoring (Prometheus & Grafana)
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca       = module.eks.cluster_ca
  aws_region       = var.aws_region
}
