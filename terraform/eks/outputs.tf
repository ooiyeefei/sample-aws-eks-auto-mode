output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block for the VPC."
  value       = var.vpc_cidr
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "cluster_primary_security_group_id" {
  description = "EKS cluster primary security group ID"
  value       = module.eks.cluster_primary_security_group_id
}

output "node_iam_role_name" {
  description = "EKS node IAM role name"
  value       = module.eks.node_iam_role_name
}

# Node group outputs
output "node_groups" {
  description = "EKS managed node groups"
  value = {
    general = module.eks.eks_managed_node_groups["general"]
    gpu     = module.eks.eks_managed_node_groups["gpu"]
    spot    = module.eks.eks_managed_node_groups["spot"]
  }
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "kube_token" {
  description = "Short-lived token for authenticating to the EKS cluster"
  value       = data.aws_eks_cluster_auth.this.token
  sensitive   = true
}
 
output "node_security_group_id" {
  description = "The ID of the security group attached to the EKS worker nodes."
  value       = module.eks.node_security_group_id
}