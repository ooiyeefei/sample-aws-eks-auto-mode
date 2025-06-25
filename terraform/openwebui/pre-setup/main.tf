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
      type = "Yaml"
      artifact {
        paths {
          name = "terraform/openwebui/pre-setup/namespace.yaml"
        }
        paths {
          name = "terraform/openwebui/pre-setup/pgvector-job.yaml"
        }
        paths {
          name = "terraform/openwebui/pre-setup/cluster-secret-store.yaml"
        }
        paths {
          name = "terraform/openwebui/pre-setup/external-secret.yaml"
        }
        repository = var.openwebui_presetup_repo
        revision   = var.openwebui_presetup_repo_branch
      }
    }
  }
} 