variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca" {
  description = "EKS cluster CA certificate"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.0.0"
}
