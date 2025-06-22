variable "name" {
  description = "Name prefix for RDS resources, passed from the environment."
  type        = string
}

variable "region" {
  description = "The AWS region for the provider."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS instances will be created. This should be wired from the EKS module's output."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules. This should be wired from the EKS module's output."
  type        = string
}

variable "private_subnets_json" {
  description = "A JSON-encoded string of private subnet IDs. This should be wired from the EKS module's output using the jsonencode() function."
  type        = string
  default     = ""
}