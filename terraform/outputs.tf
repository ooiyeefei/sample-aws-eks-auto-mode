# Root module outputs

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.eks.configure_kubectl
}

# EKS outputs
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
  value       = module.eks.vpc_id
}

# RDS outputs
output "rds_endpoint" {
  description = "The connection endpoint for the PostgreSQL instance"
  value       = module.rds.rds_endpoint
}

output "litellm_rds_endpoint" {
  description = "The connection endpoint for the LiteLLM PostgreSQL instance"
  value       = module.rds.litellm_rds_endpoint
}

# S3 outputs
output "openwebui_s3_bucket" {
  description = "The name of the S3 bucket for Open WebUI document storage"
  value       = module.s3.openwebui_s3_bucket
}

# Redis outputs
output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = module.redis.redis_primary_endpoint
}

# Secrets outputs
output "litellm_master_salt_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM master and salt keys"
  value       = module.secrets.litellm_master_salt_secret_arn
}

output "litellm_api_keys_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing LiteLLM API keys"
  value       = module.secrets.litellm_api_keys_secret_arn
}