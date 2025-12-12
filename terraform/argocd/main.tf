# Namespace для ArgoCD
resource "kubernetes_namespace" "argo" {
  metadata {
    name = var.argocd_namespace
  }
}

# Встановлення ArgoCD через офіційний Helm-чарт
resource "helm_release" "argo" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argo.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  recreate_pods = true
  replace       = true

  values = [file("${path.module}/values/argocd-values.yaml")]

  depends_on = [
    kubernetes_namespace.argo
  ]
}

resource "kubernetes_manifest" "namespaces_appset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "namespaces-appset"
      namespace = var.argocd_namespace
    }
    spec = {
      generators = [{
        git = {
          repoURL    = var.app_repo_url
          revision   = var.app_repo_branch
          directories = [
            { path = "namespaces/*" }
          ]
        }
      }]
      template = {
        metadata = {
          name      = "ns-{{path.basename}}"
          namespace = var.argocd_namespace
        }
        spec = {
          project = "default"
          source = {
            repoURL        = var.app_repo_url
            targetRevision = var.app_repo_branch
            path           = "{{path}}"
            directory = { recurse = true }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{path.basename}}"
          }
          syncPolicy = {
            automated = { prune = true, selfHeal = true }
            syncOptions = ["CreateNamespace=true"]
          }
          revisionHistoryLimit = 2
        }
      }
    }
  }

  depends_on = [helm_release.argo]
}

resource "kubernetes_manifest" "apps_appset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "apps-appset"
      namespace = var.argocd_namespace  # infra-tools
    }
    spec = {
      generators = [{
        git = {
          repoURL    = var.app_repo_url
          revision   = var.app_repo_branch
          directories = [
            { path = "apps/*/*" } # apps/<namespace>/<app>
          ]
        }
      }]

      template = {
        metadata = {
          name      = "{{path.segments[2]}}"   # app name (mlflow)
          namespace = var.argocd_namespace      # where ArgoCD lives
        }

        spec = {
          project = "default"

          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{path.segments[1]}}" # target namespace (application)
          }

          # Multi-source: chart из Helm repo + values из git
          sources = [
            {
              repoURL        = "https://community-charts.github.io/helm-charts"
              chart          = "{{path.segments[2]}}"    # имя чарта = имя папки (mlflow)
              targetRevision = "0.1.10"                  # можно вынести в values.yaml позже
              helm = {
                valueFiles = [
                  "$values/{{path}}/values.yaml"         # apps/<ns>/<app>/values.yaml
                ]
              }
            },
            {
              repoURL        = var.app_repo_url
              targetRevision = var.app_repo_branch
              ref            = "values"
            }
          ]

          syncPolicy = {
            automated = { prune = true, selfHeal = true }
            syncOptions = ["CreateNamespace=true"]
          }

          revisionHistoryLimit = 2
        }
      }
    }
  }

  depends_on = [helm_release.argo]
}

resource "kubernetes_manifest" "monitoring_appset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "monitoring-appset"
      namespace = var.argocd_namespace
    }
    spec = {
      generators = [{
        git = {
          repoURL    = var.app_repo_url
          revision   = var.app_repo_branch
          directories = [
            { path = "apps/monitoring/*" }
          ]
        }
      }]
      template = {
        metadata = {
          name      = "mon-{{path.basename}}"
          namespace = var.argocd_namespace
        }
        spec = {
          project = "default"
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "monitoring"
          }
          sources = [
            {
              repoURL        = "https://prometheus-community.github.io/helm-charts"
              chart          = "{{path.basename}}"
              targetRevision = "65.0.0"
              helm = {
                valueFiles = [
                  "$values/{{path}}/values.yaml"
                ]
              }
            },
            {
              repoURL        = var.app_repo_url
              targetRevision = var.app_repo_branch
              ref            = "values"
            }
          ]
          syncPolicy = {
            automated = { prune = true, selfHeal = true }
            syncOptions = ["CreateNamespace=true"]
          }
          revisionHistoryLimit = 2
        }
      }
    }
  }

  depends_on = [helm_release.argo]
}
