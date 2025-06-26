# terraform/openwebui/pre-setup/main.tf

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    # NOTE: time_sleep is no longer needed
  }
}

# --- Direct EKS Authentication ---

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

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# --- Resources to Apply (All in one place) ---

# 1. Create Pod Identity for External Secrets
#    (This module needs access to the `aws_eks_cluster` data source)
module "external_secrets_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  name   = "external-secrets"

  attach_custom_policy = true
  policy_statements = [
    {
      sid     = "SecretsManagerAccess"
      actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:ListSecretVersionIds"]
      resources = var.secret_arns # This variable must be passed from the secrets module output
    }
  ]

  associations = {
    external_secrets = {
      service_account = "external-secrets-sa"
      namespace       = "external-secrets"
      cluster_name    = var.cluster_name
    }
  }
}

# 2. Install the External Secrets operator via Helm
#    This explicitly depends on the Pod Identity being created.
resource "helm_release" "external_secrets" {
  depends_on = [module.external_secrets_pod_identity]

  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true

  set = [
    { name = "installCRDs", value = "true" },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "external-secrets-sa" }
  ]

  wait    = true
  timeout = 300
}

# 3. Create the Namespace
#    This must depend on the Helm release finishing successfully.
resource "kubernetes_manifest" "namespace" {
  depends_on = [helm_release.external_secrets]

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = var.namespace
    }
  }
}

# 4. Create the ClusterSecretStore
#    This must depend on the Helm release finishing successfully.
resource "kubernetes_manifest" "cluster_secret_store" {
  depends_on = [helm_release.external_secrets]

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

# 5. Create the ExternalSecret
#    This depends on BOTH the namespace and the store.
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