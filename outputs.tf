output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://localhost:8080 (use: kubectl port-forward svc/jenkins 8080:8080 -n jenkins)"
}

output "argocd_url" {
  description = "Argo CD URL"
  value       = "https://localhost:8081 (use: kubectl port-forward svc/argocd-server 8081:443 -n argocd)"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://localhost:3000 (use: kubectl port-forward svc/grafana 3000:80 -n monitoring)"
}
