# Namespace для ArgoCD
resource "kubernetes_namespace" "argo" {
  metadata {
    name = var.argocd_namespace
  }
}

# Встановлення ArgoCD через офіційний Helm-чарт
resource "helm_release" "argo" {
  name      = "argocd"
  namespace = kubernetes_namespace.argo.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  recreate_pods = true
  replace       = true
  set {
  name  = "crds.install"
  value = "false"
}

  values = [file("${path.module}/values/argocd-values.yaml")]

  depends_on = [
    kubernetes_namespace.argo
  ]
}

# Bootstrap GitOps repo (ArgoCD will watch goit-argo-9/applications)
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
        targetRevision = "main"
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


