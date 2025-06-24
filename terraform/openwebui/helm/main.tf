variable "namespace" {}
variable "cluster_name" {}
variable "chart_path" {}
variable "openwebui_repo" {}
variable "openwebui_repo_branch" {}

locals {
  values_yaml = templatefile("${path.module}/values.yaml.tpl", {
    namespace = var.namespace
  })
}

resource "rafay_workload" "openwebui_helm" {
  metadata {
    name    = "openwebui"
    project = "terraform"
  }
  spec {
    namespace = var.namespace
    placement {
      selector = "rafay.dev/clusterName=${var.cluster_name}"
    }
    version = "v0"
    artifact {
      type = "Helm"
      artifact {
        chart_path {
          name = var.chart_path
        }
        repository = var.openwebui_repo
        revision   = var.openwebui_repo_branch
      }
      values_yaml = local.values_yaml
    }
  }
} 