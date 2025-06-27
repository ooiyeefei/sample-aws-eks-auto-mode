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

# --- Render all YAML files to disk using the simple filename pattern ---

resource "local_file" "storage_class" {
  content  = templatefile("${path.module}/storage-class.yaml.tpl", {})
  filename = "storage-class.yaml"
}

resource "local_file" "namespace" {
  content  = templatefile("${path.module}/namespace.yaml.tpl", {
    namespace = var.namespace
  })
  filename = "namespace.yaml"
}

resource "local_file" "cluster_secret_store" {
  content  = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
    aws_region = var.aws_region
  })
  filename = "cluster-secret-store.yaml"
}

resource "local_file" "external_secret" {
  content  = templatefile("${path.module}/external-secret.yaml.tpl", {
    namespace      = var.namespace,
    db_secret_name = var.db_secret_name
  })
  filename = "external-secret.yaml"
}

resource "local_file" "pgvector_job" {
  content  = templatefile("${path.module}/pgvector-job.yaml.tpl", {
    namespace = var.namespace
  })
  filename = "pgvector-job.yaml"
}

resource "rafay_workload" "openwebui_secrets_setup" {
  depends_on = [
    local_file.storage_class,
    local_file.namespace,
    local_file.cluster_secret_store,
    local_file.external_secret
  ]

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
          name = "file://storage-class.yaml"
        }
        paths {
          name = "file://namespace.yaml"
        }
        paths {
          name = "file://cluster-secret-store.yaml"
        }
        paths {
          name = "file://external-secret.yaml"
        }
      }
    }
  }
}

resource "rafay_workload" "openwebui_pgvector_job" {
  depends_on = [
    rafay_workload.openwebui_secrets_setup,
    local_file.pgvector_job
  ]

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
          name = "file://pgvector-job.yaml"
        }
      }
    }
  }
}