variable "namespace" {
  description = "Kubernetes namespace for Open WebUI"
  type        = string
  default     = "vllm-inference"
}

variable "cluster_name" {
  description = "Name of the Rafay/EKS cluster to deploy to"
  type        = string
}

variable "chart_path" {
  description = "Relative path to the Helm chart tgz file"
  type        = string
}

variable "openwebui_repo" {
  description = "Git repository name for the Helm chart"
  type        = string
}

variable "openwebui_repo_branch" {
  description = "Git branch or revision for the Helm chart"
  type        = string
} 