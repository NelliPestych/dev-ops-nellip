variable "namespace" {
  type        = string
  description = "Kubernetes namespace for Jenkins"
  default     = "jenkins"
}

variable "service_account_name" {
  type        = string
  description = "Service account name for Jenkins"
  default     = "jenkins-sa"
}

variable "chart_version" {
  type        = string
  description = "Jenkins Helm chart version"
  default     = "4.3.0"
}

variable "enable_loadbalancer" {
  type        = bool
  description = "Enable LoadBalancer for Jenkins UI"
  default     = true
}

