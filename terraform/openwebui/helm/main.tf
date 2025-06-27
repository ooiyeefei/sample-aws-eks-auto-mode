terraform {
  required_providers {
    rafay = {
      source  = "RafaySystems/rafay"
      version = ">= 1.0"
    }
  }
}

resource "rafay_workload" "openwebui_helm" {

  metadata {
    name    = "openwebui"
    project = var.project_name
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
        repository    = var.openwebui_helm_repo
        chart_name    = var.openwebui_chart_name
        chart_version = var.openwebui_chart_version
        
        values_paths {
          name = templatefile("${path.module}/values.yaml", {
            s3_bucket_name = var.s3_bucket_name
            region         = var.aws_region
          })
        }
      }
    }
  }
}