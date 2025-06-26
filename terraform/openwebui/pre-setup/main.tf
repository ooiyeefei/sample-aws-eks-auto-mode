# terraform/openwebui/pre-setup/main.tf

terraform {
  required_providers {
    # We need the kubernetes and aws providers to apply manifests directly
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    # time provider is still a good practice
    time = {
      source = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
}

# --- Direct EKS Authentication ---
# Replicate the authentication pattern from the 'secrets' module

provider "aws" {
  region = var.aws_region # Assuming you pass aws_region to this module
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

# --- Resources to Apply ---

# A delay is still good practice, even if it wasn't the root cause.
resource "time_sleep" "wait_for_crd_propagation" {
  create_duration = "15s" # Can be shorter now, just being safe.
}

# Use the kubernetes_manifest resource to apply the YAML directly.
# This bypasses local_file and rafay_workload entirely.

resource "kubernetes_manifest" "namespace" {
  depends_on = [time_sleep.wait_for_crd_propagation]

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = var.namespace
    }
  }
}

resource "kubernetes_manifest" "cluster_secret_store" {
  # This depends on the namespace being created first.
  depends_on = [kubernetes_manifest.namespace]

  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ClusterSecretStore"
    "metadata" = {
      "name" = "aws-secrets"
    }
    "spec" = {
      "provider" = {
        "aws" = {
          "service" = "SecretsManager"
          "region"  = var.aws_region
        }
      }
    }
  }
}

resource "kubernetes_manifest" "external_secret" {
  depends_on = [kubernetes_manifest.cluster_secret_store]

  manifest = {
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata" = {
      "name"      = "openwebui-db-credentials"
      "namespace" = var.namespace
    }
    "spec" = {
      "refreshInterval" = "1h"
      "secretStoreRef" = {
        "name" = "aws-secrets"
        "kind" = "ClusterSecretStore"
      }
      "target" = {
        "name"           = "openwebui-db-credentials"
        "creationPolicy" = "Owner"
      }
      "data" = [
        {
          "secretKey" = "url"
          "remoteRef" = {
            "key"      = var.db_secret_name
            "property" = "connectionString"
          }
        },
        {
          "secretKey" = "dbname"
          "remoteRef" = {
            "key"      = var.db_secret_name
            "property" = "dbname"
          }
        },
        {
          "secretKey" = "host"
          "remoteRef" = {
            "key"      = var.db_secret_name
            "property" = "host"
          }
        },
        {
          "secretKey" = "password"
          "remoteRef" = {
            "key"      = var.db_secret_name
            "property" = "password"
          }
        },
        {
          "secretKey" = "port"
          "remoteRef" = {
            "key"      = var.db_secret_name
            "property" = "port"
          }
        },
        {
          "secretKey" = "username"
          "remoteRef" = {
            "key"      = var.db_secret_name
            "property" = "username"
          }
        },
      ]
    }
  }
}