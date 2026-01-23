variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.29"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for EKS (recommended: private subnets)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS will be created"
}

variable "node_group_name" {
  type        = string
  description = "EKS managed node group name"
  default     = "default-ng"
}

variable "instance_types" {
  type        = list(string)
  description = "EC2 instance types for worker nodes"
  default     = ["t3.medium"]
}

variable "desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 2
}

variable "max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 6
}
