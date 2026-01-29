output "namespace" {
  value       = kubernetes_namespace.argocd.metadata[0].name
  description = "Argo CD namespace"
}

output "server_service_name" {
  value       = "argocd-server"
  description = "Argo CD server service name"
}

output "admin_password_secret" {
  value       = "argocd-initial-admin-secret"
  description = "Secret name containing Argo CD admin password"
}

output "loadbalancer_url" {
  value       = "kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || kubectl port-forward -n argocd svc/argocd-server 8080:443"
  description = "Command to get Argo CD LoadBalancer URL or use port-forward"
}

