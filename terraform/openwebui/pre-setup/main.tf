terraform {
  required_providers {
    rafay = {
      source  = "RafaySystems/rafay"
      version = ">= 1.0"
    }
  }
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
    namespace  = var.namespace,
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
      type = "Yaml"
      paths {
        name = local_file.namespace.filename
      }
      paths {
        name = local_file.pgvector_job.filename
      }
      paths {
        name = local_file.cluster_secret_store.filename
      }
      paths {
        name = local_file.external_secret.filename
      }
    }
  }
} 