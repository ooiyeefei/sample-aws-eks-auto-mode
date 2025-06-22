# Output the S3 bucket name and Pod Identity details
output "openwebui_s3_bucket" {
  description = "The name of the S3 bucket for Open WebUI document storage"
  value       = aws_s3_bucket.openwebui_docs.id
}

output "openwebui_pod_identity_role_arn" {
  description = "The ARN of the IAM role for Open WebUI Pod Identity"
  value       = module.openwebui_pod_identity.iam_role_arn
}

output "openwebui_pod_identity_role_name" {
  description = "The name of the IAM role for Open WebUI Pod Identity"
  value       = module.openwebui_pod_identity.iam_role_name
} 