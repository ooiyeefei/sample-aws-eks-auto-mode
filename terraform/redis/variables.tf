variable "name" {
  description = "Name prefix for Redis resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Redis cluster will be created"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for Redis subnet group"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "EKS cluster primary security group ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 