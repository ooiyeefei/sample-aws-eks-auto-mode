output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "openwebui_oauth_secret_arn" {
  description = "ARN of the OpenWebUI OAuth credentials secret"
  value       = aws_secretsmanager_secret.oauth_credentials.arn
}
