output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "state_bucket_name" {
  value = module.s3_backend.bucket_name
}

output "dynamodb_table_name" {
  value = module.s3_backend.dynamodb_table_name
}

output "jenkins_namespace" {
  value       = module.jenkins.namespace
  description = "Jenkins namespace"
}

output "jenkins_admin_password_secret" {
  value       = module.jenkins.admin_password_secret
  description = "Secret name containing Jenkins admin password"
}

output "jenkins_loadbalancer_url" {
  value       = module.jenkins.loadbalancer_url
  description = "Jenkins LoadBalancer URL or port-forward command"
}

output "argocd_namespace" {
  value       = module.argo_cd.namespace
  description = "Argo CD namespace"
}

output "argocd_admin_password_secret" {
  value       = module.argo_cd.admin_password_secret
  description = "Secret name containing Argo CD admin password"
}

output "argocd_loadbalancer_url" {
  value       = module.argo_cd.loadbalancer_url
  description = "Argo CD LoadBalancer URL or port-forward command"
}
