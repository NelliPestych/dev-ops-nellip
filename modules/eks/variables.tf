variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "node_group_size" {
  description = "Node group size"
  type        = number
}

variable "project_name" {
  description = "Project name"
  type        = string
}
