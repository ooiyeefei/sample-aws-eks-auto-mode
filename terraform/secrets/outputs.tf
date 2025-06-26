# Output the secret ARNs for reference
output "litellm_master_salt_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM master and salt keys"
  value       = aws_secretsmanager_secret.litellm_master_salt.arn
}

output "litellm_api_keys_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM API keys"
  value       = aws_secretsmanager_secret.litellm_api_keys.arn
}