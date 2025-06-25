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
        values_paths {
          name = "values.yaml"
        }
        repository   = var.openwebui_helm_repo
        chart_name   = var.openwebui_chart_name
        chart_version = var.openwebui_chart_version
        # If you want to use a custom values.yaml, add:
        # values_paths {
        #   name = "file://path/to/your/values.yaml"
        # }
      }
    }
  }
} 