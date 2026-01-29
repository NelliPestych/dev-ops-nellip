resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Argo CD Application через Helm chart
resource "helm_release" "argocd_apps" {
  count = var.gitops_repo_url != "" ? 1 : 0

  name       = "argocd-apps"
  chart      = "${path.module}/charts"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode({
      applications = [
        {
          name          = var.app_name
          namespace     = var.namespace
          project       = "default"
          repoURL       = var.gitops_repo_url
          targetRevision = var.target_revision
          path          = var.app_path
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "django"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      ]
    })
  ]

  depends_on = [
    helm_release.argocd
  ]
}

