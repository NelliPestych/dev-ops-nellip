output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = kubernetes_namespace.jenkins.metadata[0].name
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://localhost:8080 (use: kubectl port-forward svc/jenkins 8080:8080 -n jenkins)"
}

output "jenkins_admin_password_command" {
  description = "Command to get Jenkins admin password"
  value       = "kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo"
}
