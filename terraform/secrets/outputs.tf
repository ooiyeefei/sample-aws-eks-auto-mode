# Output the secret ARNs for reference
output "litellm_master_salt_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM master and salt keys"
  value       = aws_secretsmanager_secret.litellm_master_salt.arn
}

output "litellm_api_keys_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM API keys"
  value       = aws_secretsmanager_secret.litellm_api_keys.arn
}

output "external_secrets_pod_identity_role_arn" {
  description = "The ARN of the IAM role for External Secrets Pod Identity"
  value       = module.external_secrets_pod_identity.iam_role_arn
}

output "external_secrets_pod_identity_role_name" {
  description = "The name of the IAM role for External Secrets Pod Identity"
  value       = module.external_secrets_pod_identity.iam_role_name
} 

output "external_secrets_status" {
  description = "The status of the External Secrets Helm release. Used for creating dependencies."
  value       = helm_release.external_secrets.status
}