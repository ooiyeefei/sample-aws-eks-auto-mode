variable "namespace" {
  description = "Kubernetes namespace for Open WebUI"
  type        = string
  default     = "vllm-inference"
}

variable "project_name" {
  description = "Rafay project name"
  type        = string
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

variable "openwebui_presetup_repo" {
  description = "Git repository name for the yaml"
  type        = string
}

variable "openwebui_presetup_repo_branch" {
  description = "Git branch for the yaml"
  type        = string
}