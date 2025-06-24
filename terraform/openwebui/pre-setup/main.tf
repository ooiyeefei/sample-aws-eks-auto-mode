variable "namespace" {}
variable "aws_region" {}
variable "db_secret_name" {}
variable "cluster_name" {}

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
  metadata {
    name    = "openwebui-pre-setup"
    project = "terraform"
  }
  spec {
    namespace = var.namespace
    placement {
      selector = "rafay.dev/clusterName=${var.cluster_name}"
    }
    version = "v0"
    artifact {
      type = "K8sYaml"
      artifact {
        yaml_paths = [
          "${path.module}/namespace.yaml",
          "${path.module}/pgvector-job.yaml"
        ]
        yaml_content = [
          local.cluster_secret_store_yaml,
          local.external_secret_yaml
        ]
      }
    }
  }
} 