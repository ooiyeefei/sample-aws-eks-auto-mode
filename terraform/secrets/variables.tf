variable "name" {
  description = "Name prefix for Secrets Manager resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for Pod Identity association"
  type        = string
}

variable "secret_arns" {
  description = "List of Secrets Manager ARNs that External Secrets can access"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "The AWS region for the provider."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint URL."
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "EKS cluster CA data (base64 encoded)."
  type        = string
}

variable "kube_token" {
  description = "Kubernetes API token for authentication."
  type        = string
} 