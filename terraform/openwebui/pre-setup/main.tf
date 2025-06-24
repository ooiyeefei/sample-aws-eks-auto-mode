variable "project_id" {}
variable "cluster_id" {}
variable "namespace" {}
variable "aws_region" {}
variable "db_secret_name" {}

locals {
  cluster_secret_store_yaml = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
    namespace   = var.namespace
    aws_region  = var.aws_region
  })
  external_secret_yaml = templatefile("${path.module}/external-secret.yaml.tpl", {
    namespace       = var.namespace
    db_secret_name  = var.db_secret_name
  })
}

resource "rafay_workload" "openwebui_pre_setup" {
  name        = "openwebui-pre-setup"
  project_id  = var.project_id
  cluster_id  = var.cluster_id
  namespace   = var.namespace
  type        = "K8sYaml"
  yaml_paths  = [
    "${path.module}/namespace.yaml",
    "${path.module}/pgvector-job.yaml"
  ]
  yaml_content = [
    local.cluster_secret_store_yaml,
    local.external_secret_yaml
  ]
} 