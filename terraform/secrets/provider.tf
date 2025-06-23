provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  token                  = var.kube_token
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    token                  = var.kube_token
  }
} 