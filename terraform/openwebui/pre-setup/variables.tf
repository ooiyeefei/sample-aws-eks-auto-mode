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

variable "secret_arns" {
  description = "A list of ARNs for the AWS Secrets Manager secrets that the External Secrets operator needs permission to access."
  type        = list(string)
}

variable "openwebui_presetup_repo" {
  description = "Git repository name for the yaml"
  type        = string
}

variable "openwebui_presetup_repo_branch" {
  description = "Git branch for the yaml"
  type        = string
}