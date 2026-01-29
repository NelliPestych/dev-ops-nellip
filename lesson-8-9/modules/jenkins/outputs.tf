output "namespace" {
  value       = kubernetes_namespace.jenkins.metadata[0].name
  description = "Jenkins namespace"
}

output "service_name" {
  value       = helm_release.jenkins.name
  description = "Jenkins service name"
}

output "admin_password_secret" {
  value       = "jenkins-admin-password"
  description = "Secret name containing Jenkins admin password"
}

output "loadbalancer_url" {
  value       = "kubectl get svc -n jenkins jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || kubectl port-forward -n jenkins svc/jenkins 8080:8080"
  description = "Command to get Jenkins LoadBalancer URL or use port-forward"
}

