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