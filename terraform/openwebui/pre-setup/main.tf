terraform {
  required_providers {
    rafay = {
      source  = "RafaySystems/rafay"
      version = ">= 1.0"
    }
  }
}

resource "rafay_workload" "openwebui_pre_setup" {
  metadata {
    name    = "openwebui-pre-setup"
    project = var.project_name
  }
  spec {
    namespace = var.namespace
    placement {
      selector = "rafay.dev/clusterName=${var.cluster_name}"
    }
    version = "v0"
    artifact {
      type    = "Yaml"
      content = templatefile("${path.module}/namespace.yaml.tpl", {
        namespace = var.namespace
      })
    }
    artifact {
      type    = "Yaml"
      content = templatefile("${path.module}/pgvector-job.yaml.tpl", {
        namespace = var.namespace
      })
    }
    artifact {
      type    = "Yaml"
      content = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
        namespace  = var.namespace
        aws_region = var.aws_region
      })
    }
    artifact {
      type    = "Yaml"
      content = templatefile("${path.module}/external-secret.yaml.tpl", {
        namespace      = var.namespace
        db_secret_name = var.db_secret_name
      })
    }
  }
} 