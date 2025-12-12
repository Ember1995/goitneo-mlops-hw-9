terraform {
  backend "s3" {
    bucket  = "mlops-tfstate-hanna"
    key     = "argocd/terraform.tfstate"
    region  = "eu-north-1"
    profile = "hannadunska"
  }
}
