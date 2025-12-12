variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "hannadunska"
}

variable "aws_region" {
  description = "AWS region for AWS provider (має відповідати регіону EKS)"
  type        = string
  default     = "eu-north-1"
}

variable "eks_cluster_name" {
  description = "Назва існуючого EKS-кластера"
  type        = string
  default     = "goit-eks"
}

variable "eks_state_key" {
  description = "S3 key для remote state EKS"
  type        = string
  default     = "eks/terraform.tfstate"
}

variable "eks_state_region" {
  description = "Регіон бакета з remote state EKS"
  type        = string
  default     = "eu-north-1"
}

variable "argocd_namespace" {
  description = "Namespace для ArgoCD"
  type        = string
  default     = "infra-tools"
}

variable "argocd_chart_version" {
  description = "Версія Helm-чарту ArgoCD"
  type        = string
  default     = "7.7.5"
}

variable "app_repo_url" {
  description = "Публічний Git-репозиторій з маніфестами"
  type        = string
  default     = "https://github.com/Ember1995/goit-argo.git"
}

variable "app_repo_branch" {
  description = "Git гілка"
  type        = string
  default     = "main"
}