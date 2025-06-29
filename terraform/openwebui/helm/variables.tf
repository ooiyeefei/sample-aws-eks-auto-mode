variable "namespace" {
  description = "Kubernetes namespace for Open WebUI"
  type        = string
  default     = "vllm-inference"
}

variable "project_name" {
  description = "Rafay project name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Rafay/EKS cluster to deploy to"
  type        = string
}

variable "openwebui_helm_repo" {
  description = "Git repository name for the Helm chart"
  type        = string
}

variable "openwebui_chart_name" {
  description = "Helm chart name"
  type        = string
} 

variable "openwebui_chart_version" {
  description = "Helm chart version"
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the S3 bucket is located. This is required by the values.yaml template."
  type        = string
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for OpenWebUI document persistence. This is required by the values.yaml template."
  type        = string
}

variable "node_security_group_id" {
  description = "The ID of the worker node security group to be used by the NLB."
  type        = string
}