# IAM role for LiteLLM Pod Identity
module "litellm_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "litellm"

  # Custom policy for Secrets Manager access
  attach_custom_policy = true
  policy_statements = [
    {
      sid       = "SecretsManagerAccess"
      actions   = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:ListSecretVersionIds"
      ]
      resources = [
        aws_secretsmanager_secret.litellm_master_salt.arn,
        aws_secretsmanager_secret.litellm_api_keys.arn,
        aws_secretsmanager_secret.litellm_db_connection_string.arn
      ]
    }
  ]

  # Create Pod Identity Association
  associations = {
    litellm = {
      service_account      = "litellm-sa"
      namespace            = "litellm"
      cluster_name         = module.eks.cluster_name
    }
  }

  tags = {
    Environment = var.name
  }
}

# Output the IAM role ARN for reference
output "litellm_pod_identity_role_arn" {
  description = "The ARN of the IAM role for LiteLLM Pod Identity"
  value       = module.litellm_pod_identity.iam_role_arn
}
