variable "namespace" {
  type        = string
  description = "Kubernetes namespace for Argo CD"
  default     = "argocd"
}

variable "chart_version" {
  type        = string
  description = "Argo CD Helm chart version"
  default     = "5.51.6"
}

variable "enable_loadbalancer" {
  type        = bool
  description = "Enable LoadBalancer for Argo CD server"
  default     = true
}

variable "gitops_repo_url" {
  type        = string
  description = "GitOps repository URL (Repo B)"
  default     = ""
}

variable "app_name" {
  type        = string
  description = "Argo CD Application name"
  default     = "django-app"
}

variable "app_path" {
  type        = string
  description = "Path to Helm chart in GitOps repo"
  default     = "charts/django-app"
}

variable "target_revision" {
  type        = string
  description = "Target revision/branch in GitOps repo"
  default     = "main"
}

