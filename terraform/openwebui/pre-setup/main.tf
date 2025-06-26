terraform {
  required_providers {
    rafay = {
      source  = "RafaySystems/rafay"
      version = ">= 1.0"
    }
  }
}

resource "rafay_workload" "external_secrets_operator" {
  metadata {
    name    = var.namespace
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
        repository    = "external-secrets"
        chart_name    = "external-secrets"
        chart_version = "0.18.1"
        # values_paths can be added if you want to customize values
      }
    }
  }
}

resource "null_resource" "wait_for_external_secrets_crds" {
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..30}; do
        kubectl get crd externalsecrets.external-secrets.io && \
        kubectl get crd clustersecretstores.external-secrets.io && \
        exit 0
        echo "Waiting for External Secrets CRDs to be ready..."
        sleep 5
      done
      echo "CRDs not ready after 150 seconds" >&2
      exit 1
    EOT
  }
  depends_on = [rafay_workload.external_secrets_operator]
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
        paths {
          name = "file://${local_file.pgvector_job.filename}"
        }
      }
      type = "Yaml"
    }
  }
  depends_on = [null_resource.wait_for_external_secrets_crds]
}

