# Pod Identity for CloudWatch Observability
module "cloudwatch_observability_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "cloudwatch-agent"

  # Attach the required CloudWatchAgentServerPolicy
  additional_policy_arns = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  associations = {
    cloudwatch_agent = {
      service_account      = "cloudwatch-agent"
      namespace            = "amazon-cloudwatch"
      cluster_name         = module.eks.cluster_name
    }
  }

  tags = local.tags
}

# Amazon CloudWatch Observability EKS add-on
resource "aws_eks_addon" "amazon_cloudwatch_observability" {
  cluster_name             = module.eks.cluster_name
  addon_name              = "amazon-cloudwatch-observability"
  addon_version           = "v1.7.0-eksbuild.1"
  configuration_values    = file("${path.module}/configs/amazon-cloudwatch-observability.json")
  
  tags = local.tags
}

# Output for Container Insights status
output "container_insights_addon_status" {
  description = "Status of the Container Insights add-on"
  value       = aws_eks_addon.amazon_cloudwatch_observability.status
}

output "cloudwatch_observability_pod_identity_role_arn" {
  description = "The ARN of the IAM role for CloudWatch Observability Pod Identity"
  value       = module.cloudwatch_observability_pod_identity.iam_role_arn
}

# KubeCost EKS Add-on (Optional - Free Standard Bundle)
resource "aws_eks_addon" "kubecost" {
  count        = var.enable_kubecost ? 1 : 0
  cluster_name = module.eks.cluster_name
  addon_name   = "kubecost_kubecost"
  addon_version = "v1.97.0-eksbuild.1"
  
  tags = local.tags
}

# Output for KubeCost status (conditional)
output "kubecost_addon_status" {
  description = "Status of the KubeCost add-on (if enabled)"
  value       = var.enable_kubecost ? aws_eks_addon.kubecost[0].status : "disabled"
}
