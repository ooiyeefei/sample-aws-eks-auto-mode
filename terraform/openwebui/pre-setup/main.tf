# terraform/openwebui/pre-setup/main.tf

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    time = {
      source = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
}

# --- Provider Configuration ---

provider "aws" {
  region = var.aws_region
}

# Direct EKS Authentication
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


# --- Step 1: Attach IAM Policy to the OpenWebUI Role (The "Glue") ---
# This gives the OpenWebUI application's identity the permission to read the RDS secret.
resource "aws_iam_role_policy_attachment" "secrets_access_to_openwebui" {
  # This depends on variables passed in from the `s3` and `rds` module outputs
  role       = var.openwebui_pod_identity_role_name
  policy_arn = var.secrets_access_policy_arn
}


# --- Step 2: Kubernetes Resources ---

# Safety delay to ensure CRDs from the 'secrets' module are fully propagated.
resource "time_sleep" "wait_for_crd_propagation" {
  # This is a safety measure; it doesn't need to depend on the IAM attachment.
  create_duration = "15s"
}

# Use the kubernetes_manifest resource to apply the YAML directly.
# This bypasses local_file and the problematic rafay_workload resource.

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
  # This must depend on the Helm release from the previous step being complete.
  # Since that's in a different Rafay template, the time_sleep is our proxy for that.
  depends_on = [time_sleep.wait_for_crd_propagation]

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
  depends_on = [
    kubernetes_manifest.namespace,
    kubernetes_manifest.cluster_secret_store
  ]

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
          "secretKey" = "url",
          "remoteRef" = { "key" = var.db_secret_name, "property" = "connectionString" }
        },
        {
          "secretKey" = "dbname",
          "remoteRef" = { "key" = var.db_secret_name, "property" = "dbname" }
        },
        {
          "secretKey" = "host",
          "remoteRef" = { "key" = var.db_secret_name, "property" = "host" }
        },
        {
          "secretKey" = "password",
          "remoteRef" = { "key" = var.db_secret_name, "property" = "password" }
        },
        {
          "secretKey" = "port",
          "remoteRef" = { "key" = var.db_secret_name, "property" = "port" }
        },
        {
          "secretKey" = "username",
          "remoteRef" = { "key" = var.db_secret_name, "property" = "username" }
        },
      ]
    }
  }
}