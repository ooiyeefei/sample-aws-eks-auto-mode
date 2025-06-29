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
    time = {
      source = "hashicorp/time"
      version = ">= 0.9.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "local_file" "openwebui_values_yaml" {
  content  = templatefile("${path.module}/values.yaml.tpl", {
    s3_bucket_name = var.s3_bucket_name
    region         = var.aws_region
  })
  filename = "values.yaml"
}

resource "rafay_workload" "openwebui_helm" {
  depends_on = [
    local_file.openwebui_values_yaml
  ]

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
          name = "file://values.yaml"
        }
      }
    }
  }
}

resource "rafay_workload" "openwebui_load_balancer" {
  depends_on = [
    rafay_workload.openwebui_helm
  ]

  metadata {
    name    = "openwebui-load-balancer"
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
          name = "file://lb.yaml"
        }
      }
    }
  }
}

resource "time_sleep" "wait_for_lb" {
  depends_on = [rafay_workload.openwebui_load_balancer]

  # Wait for 2 minutes to give the AWS NLB time to provision.
  create_duration = "120s"
}

data "kubernetes_service" "openwebui_lb" {
  depends_on = [time_sleep.wait_for_lb]

  metadata {
    name      = "open-webui-service"
    namespace = var.namespace
  }
}