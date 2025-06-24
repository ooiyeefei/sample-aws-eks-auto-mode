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