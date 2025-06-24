variable "project_id" {
  description = "Rafay project ID"
  type        = string
}

variable "cluster_id" {
  description = "Rafay cluster ID"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Open WebUI"
  type        = string
  default     = "vllm-inference"
} 