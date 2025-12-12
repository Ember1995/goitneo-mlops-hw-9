output "argocd_namespace" {
  description = "Namespace, де розгорнуто ArgoCD"
  value       = kubernetes_namespace.argo.metadata[0].name
}
