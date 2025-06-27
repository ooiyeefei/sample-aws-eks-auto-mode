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

data "kubernetes_crd_v1" "external_secrets_crd_wait" {
  metadata {
    name = "clustersecretstores.external-secrets.io"
  }

  depends_on = [
    data.aws_eks_cluster_auth.cluster
  ]
}



# Step 3: Attach IAM Policy to the OpenWebUI APP Role (The "Glue")
# This gives the actual OpenWebUI application permission to access secrets.
resource "aws_iam_role_policy_attachment" "secrets_access_to_openwebui" {
  role       = var.openwebui_pod_identity_role_name
  policy_arn = var.secrets_access_policy_arn
}

# Step 4: Create the Kubernetes resources for the application
# These depend explicitly on the Helm chart finishing its installation.

resource "kubernetes_manifest" "namespace" {

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = var.namespace
    }
  }
}


resource "kubernetes_manifest" "cluster_secret_store" {
  depends_on = [data.kubernetes_crd_v1.external_secrets_crd_wait]

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