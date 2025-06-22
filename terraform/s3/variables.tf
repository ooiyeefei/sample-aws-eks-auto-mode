variable "name" {
  description = "Name prefix for S3 resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for Pod Identity association"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must be a valid EKS cluster name (alphanumeric and hyphens only, no newlines or special characters)."
  }
}

variable "region" {
  description = "The AWS region for the provider."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (not used in S3 module but passed by Rafay)"
  type        = string
  default     = ""
}

variable "openwebui_pod_identity_role_name" {
  description = "The name of the IAM role for OpenWebUI Pod Identity (output from this module)"
  type        = string
  default     = ""
} 