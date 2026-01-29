terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "study"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-8-9-vpc"
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "nellip-tfstate-lesson8-9-053414411835"
  table_name  = "terraform-locks"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-8-9-django-ecr"
  scan_on_push = true
}

module "eks" {
  source       = "./modules/eks"
  cluster_name = "lesson-8-9-eks"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids   # або public_subnet_ids, але краще private

  desired_size = 2
  min_size     = 2
  max_size     = 6

  instance_types = ["t3.medium"]
}

# Data sources for Kubernetes and Helm providers
# Эти data sources будут вычислены после создания EKS кластера
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
  
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
  
  depends_on = [module.eks]
}

# Kubernetes provider для работы с кластером
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# Helm provider для установки Helm charts
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

module "jenkins" {
  source = "./modules/jenkins"
  
  depends_on = [
    module.eks
  ]
}

module "argo_cd" {
  source = "./modules/argo_cd"
  
  # ВАЖЛИВО: URL GitOps репозиторію (де лежить Helm chart для ArgoCD)
  # Якщо використовуєте той самий репозиторій - вкажіть його URL
  # Якщо окремий GitOps репозиторій - вкажіть його URL
  # Наприклад: "https://github.com/NelliPestych/dev-ops-nellip.git"
  gitops_repo_url = "https://github.com/NelliPestych/dev-ops-nellip.git"
  
  # Шлях до Helm chart в GitOps репозиторії
  # Якщо chart в тому ж репозиторії: "lesson-8-9/charts/django-app"
  # Якщо chart в окремому репозиторії: "charts/django-app"
  app_path = "lesson-8-9/charts/django-app"
  
  # Гілка, яку слухає ArgoCD
  target_revision = "main"
  
  depends_on = [
    module.eks
  ]
}
