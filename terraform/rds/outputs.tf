# Output the RDS endpoint
output "rds_endpoint" {
  description = "The connection endpoint for the PostgreSQL instance"
  value       = aws_db_instance.postgres.endpoint
}

# Output the Secrets Manager secret ARN
output "postgres_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing PostgreSQL credentials"
  value       = aws_secretsmanager_secret.postgres_credentials.arn
}

# Output the LiteLLM RDS endpoint
output "litellm_rds_endpoint" {
  description = "The connection endpoint for the LiteLLM PostgreSQL instance"
  value       = aws_db_instance.litellm_postgres.endpoint
}

# Output the LiteLLM Secrets Manager secret ARN
output "litellm_postgres_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM PostgreSQL credentials"
  value       = aws_secretsmanager_secret.litellm_db_credentials.arn
}

# Output the connection string secret ARN
output "db_connection_string_arn" {
  description = "The ARN of the Secrets Manager secret containing database connection string"
  value       = aws_secretsmanager_secret.db_connection_string.arn
}

# Output the LiteLLM connection string secret ARN
output "litellm_db_connection_string_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM database connection string"
  value       = aws_secretsmanager_secret.litellm_db_connection_string.arn
}

# Output the secrets access policy ARN
output "secrets_access_policy_arn" {
  description = "The ARN of the IAM policy for Secrets Manager access"
  value       = aws_iam_policy.secrets_access.arn
}

output "secret_arns" {
  description = "List of all secret ARNs created by this module."
  value = [
    aws_secretsmanager_secret.postgres_credentials.arn,
    aws_secretsmanager_secret.db_connection_string.arn,
    aws_secretsmanager_secret.litellm_db_credentials.arn,
    aws_secretsmanager_secret.litellm_db_connection_string.arn
  ]
}

output "postgres_secret_name" {
  description = "The name of the AWS Secrets Manager secret for Postgres credentials"
  value       = aws_secretsmanager_secret.postgres_credentials.name
} 