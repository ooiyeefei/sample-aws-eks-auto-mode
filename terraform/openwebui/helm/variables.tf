variable "namespace" {
  description = "Kubernetes namespace for Open WebUI"
  type        = string
  default     = "vllm-inference"
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