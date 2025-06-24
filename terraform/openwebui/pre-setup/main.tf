variable "namespace" {}
variable "aws_region" {}
variable "db_secret_name" {}
variable "cluster_name" {}

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
          name = "namespace.yaml"
        }
        paths {
          name = "pgvector-job.yaml"
        }
        paths {
          name = "cluster-secret-store.yaml"
        }
        paths {
          name = "external-secret.yaml"
        }
        # If using a git repo, add repository and revision here
        # repository = var.repo_name
        # revision   = var.repo_branch
      }
    }
  }
} 