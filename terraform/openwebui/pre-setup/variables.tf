variable "namespace" {
  description = "Kubernetes namespace for Open WebUI"
  type        = string
  default     = "vllm-inference"
}

variable "aws_region" {
  description = "AWS region for Secrets Manager"
  type        = string
}

variable "db_secret_name" {
  description = "Name of the secret in AWS Secrets Manager for DB credentials"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Rafay/EKS cluster to deploy to"
  type        = string
} 

variable "openwebui_repo" {
  description = "Git repository name for the Helm chart"
  type        = string
}

variable "openwebui_repo_branch" {
  description = "Git branch or revision for the Helm chart"
  type        = string
} 