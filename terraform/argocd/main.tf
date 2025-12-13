resource "kubernetes_manifest" "argocd_gitops_repo" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "gitops-root"
      namespace = kubernetes_namespace.argo.metadata[0].name
    }
    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/Ember1995/goit-argo-9"
        targetRevision = "lesson-8-9"  # или "main"
        path           = "applications"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [helm_release.argo]
}
