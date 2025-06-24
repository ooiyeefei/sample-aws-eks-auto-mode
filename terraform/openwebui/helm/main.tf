variable "project_id" {}
variable "cluster_id" {}
variable "namespace" {}

locals {
  values_yaml = file("${path.module}/values.yaml.tpl")
}

resource "rafay_workload" "openwebui_helm" {
  name        = "openwebui"
  project_id  = var.project_id
  cluster_id  = var.cluster_id
  namespace   = var.namespace
  type        = "Helm"
  helm {
    chart_name    = "open-webui"
    chart_version = "latest"
    repo_url      = "https://helm.openwebui.com/"
    values_yaml   = local.values_yaml
  }
} 