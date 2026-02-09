output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://localhost:9090 (use: kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n monitoring)"
}

output "grafana_url" {
  description = "Grafana URL"
  value       = "http://localhost:3000 (use: kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring)"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = "admin"
  sensitive   = true
}
