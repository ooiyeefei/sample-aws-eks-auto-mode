# Generate random strings for LiteLLM master and salt keys
resource "random_password" "litellm_master_key" {
  length  = 21
  special = false
}

resource "random_password" "litellm_salt_key" {
  length  = 21
  special = false
}

# Create a secret for LiteLLM master and salt keys
resource "aws_secretsmanager_secret" "litellm_master_salt" {
  name_prefix = "${var.name}-litellm-master-salt-"
  recovery_window_in_days = 0
  
  tags = {
    Name = "${var.name}-litellm-master-salt"
  }
}

locals {
  litellm_master_key = "sk-${random_password.litellm_master_key.result}"
  litellm_salt_key = "sk-${random_password.litellm_salt_key.result}"
}

# Store the generated values
resource "aws_secretsmanager_secret_version" "litellm_master_salt_ver" {
  secret_id = aws_secretsmanager_secret.litellm_master_salt.id

  secret_string = jsonencode({
    LITELLM_MASTER_KEY = local.litellm_master_key
    LITELLM_SALT_KEY   = local.litellm_salt_key
  })
}

# Create a secret for LiteLLM API keys (for external providers)
resource "aws_secretsmanager_secret" "litellm_api_keys" {
  name_prefix = "${var.name}-litellm-api-keys-"
  recovery_window_in_days = 0
  
  tags = {
    Name = "${var.name}-litellm-api-keys"
  }
}

# Store empty values initially - these can be updated manually later
resource "aws_secretsmanager_secret_version" "litellm_api_keys_ver" {
  secret_id = aws_secretsmanager_secret.litellm_api_keys.id

  secret_string = jsonencode({
    OPENAI_API_KEY = ""
    ANTHROPIC_API_KEY = ""
    # Add other provider keys as needed
  })
}

# Output the secret ARNs for reference
output "litellm_master_salt_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM master and salt keys"
  value       = aws_secretsmanager_secret.litellm_master_salt.arn
}

output "litellm_api_keys_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM API keys"
  value       = aws_secretsmanager_secret.litellm_api_keys.arn
}

output "litellm_db_connection_string_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM database connection string"
  value       = aws_secretsmanager_secret.litellm_db_connection_string.arn
}
