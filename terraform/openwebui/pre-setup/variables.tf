variable "namespace" {
  description = "Kubernetes namespace for Open WebUI and its related resources."
  type        = string
  default     = "vllm-inference"
}

variable "aws_region" {
  description = "AWS region where the EKS cluster and Secrets Manager reside."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster to deploy to."
  type        = string
}

variable "db_secret_name" {
  description = "The name/ARN of the secret in AWS Secrets Manager containing the database credentials."
  type        = string
}

variable "openwebui_pod_identity_role_name" {
  description = "The name of the IAM role created for the OpenWebUI application."
  type        = string
}

variable "project_name" {
  description = "Rafay Project Name"
  type        = string
}

variable "secrets_access_policy_arn" {
  description = "The ARN of the IAM policy that grants access to the RDS database secret."
  type        = string
}

variable "openwebui_presetup_repo" {
  description = "Git repository name for the yaml"
  type        = string
}

variable "openwebui_presetup_repo_branch" {
  description = "Git branch for the yaml"
  type        = string
}