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
    null = {
      source = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

################################################################################
# Direct EKS Authentication
# This section ensures that any 'kubectl' commands run by provisioners
# are correctly authenticated to the target EKS cluster.
################################################################################

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

resource "local_file" "load_balancer_yaml" {
  content = templatefile("${path.module}/lb.yaml.tpl", {
    namespace = var.namespace
    node_security_group_id = var.node_security_group_id
  })
  filename = "lb.yaml"
}

resource "rafay_workload" "openwebui_load_balancer" {
  depends_on = [
    rafay_workload.openwebui_helm,
    local_file.load_balancer_yaml
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

resource "local_sensitive_file" "kubeconfig" {
  content = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "default"
    clusters = [{
      name = var.cluster_name
      cluster = {
        server                   = data.aws_eks_cluster.cluster.endpoint
        certificate-authority-data = data.aws_eks_cluster.cluster.certificate_authority[0].data
      }
    }]
    contexts = [{
      name = "default"
      context = {
        cluster = var.cluster_name
        user    = "default"
      }
    }]
    users = [{
      name = "default"
      user = {
        token = data.aws_eks_cluster_auth.cluster.token
      }
    }]
  })
  filename = "/tmp/kubeconfig"
}


resource "time_sleep" "wait_for_lb_provisioning" {
  depends_on      = [rafay_workload.openwebui_load_balancer]
  create_duration = "90s"
}

data "external" "load_balancer_info" {
  depends_on = [
    rafay_workload.openwebui_load_balancer,
    local_sensitive_file.kubeconfig
  ]

  program = ["bash", "${path.module}/get-lb-hostname.sh"]

  query = {
    namespace    = var.namespace
    service_name = "open-webui-service"
  }
}