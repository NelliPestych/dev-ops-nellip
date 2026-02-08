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

variable "cluster_token" {
  description = "EKS cluster token"
  type        = string
  sensitive   = true
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.0.0"
}
