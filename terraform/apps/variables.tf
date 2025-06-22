variable "openwebui_pod_identity_role_name" {
  description = "The name of the IAM role for the OpenWebUI Pod Identity, created in the S3 module."
  type        = string
}

variable "secrets_access_policy_arn" {
  description = "The ARN of the IAM policy that grants access to RDS secrets, created in the RDS module."
  type        = string
} 