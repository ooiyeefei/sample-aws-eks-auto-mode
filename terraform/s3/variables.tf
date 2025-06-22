variable "name" {
  description = "Name prefix for S3 resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for Pod Identity association"
  type        = string
} 