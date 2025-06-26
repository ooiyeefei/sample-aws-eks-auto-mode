provider "aws" {
  region = var.region
}

# Data source to get information about the EKS cluster by name
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

# Data source to generate a temporary authentication token for the cluster
# This uses the AWS credentials provided by the Rafay Environment's Config Context
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# Configure the Kubernetes provider to use the dynamic data
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure the Helm provider to use the same dynamic data
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}