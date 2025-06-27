terraform {
  required_providers {
    rafay = {
      source  = "RafaySystems/rafay"
      version = ">= 1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
  }
}

# --- Direct EKS Authentication (This part is correct and remains) ---
provider "aws" {
  region = var.aws_region
}
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_iam_role_policy_attachment" "secrets_access_to_openwebui" {
  role       = var.openwebui_pod_identity_role_name
  policy_arn = var.secrets_access_policy_arn
}

resource "local_file" "namespace" {
  content  = templatefile("${path.module}/namespace.yaml.tpl", {
    namespace = var.namespace
  })
  filename = "${path.module}/namespace.yaml"
}

resource "local_file" "pgvector_job" {
  content  = templatefile("${path.module}/pgvector-job.yaml.tpl", {
    namespace = var.namespace
  })
  filename = "${path.module}/pgvector-job.yaml"
}

resource "local_file" "cluster_secret_store" {
  content  = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
    aws_region = var.aws_region
  })
  filename = "${path.module}/cluster-secret-store.yaml"
}

resource "local_file" "external_secret" {
  content  = templatefile("${path.module}/external-secret.yaml.tpl", {
    namespace      = var.namespace,
    db_secret_name = var.db_secret_name
  })
  filename = "${path.module}/external-secret.yaml"
}

resource "rafay_workload" "openwebui_secrets_setup" {
  metadata {  
    name    = "openwebui-secrets-setup"
    project = var.project_name
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
          name = "file://${local_file.namespace.filename}"
        }
        paths {
          name = "file://${local_file.cluster_secret_store.filename}"
        }
        paths {
          name = "file://${local_file.external_secret.filename}"
        }
      }
    }
  }
}

resource "rafay_workload" "openwebui_pgvector_job" {
  # This now depends on the secrets setup workload completing successfully.
  depends_on = [rafay_workload.openwebui_secrets_setup]

  metadata {
    name    = "openwebui-pgvector-job"
    project = var.project_name
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
          name = "file://${local_file.pgvector_job.filename}"
        }
      }
    }
  }
}