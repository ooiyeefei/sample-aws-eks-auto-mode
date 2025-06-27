terraform {
  required_providers {
    # We only need aws for auth, and local/null for the apply logic.
    # The kubernetes provider is NOT used to apply manifests here.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    local = {
      source = "hashicorp/local"
      version = ">= 2.5.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
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


# Attach IAM Policy to the OpenWebUI APP Role (The "Glue")
# This gives the actual OpenWebUI application permission to access secrets.
resource "aws_iam_role_policy_attachment" "secrets_access_to_openwebui" {
  role       = var.openwebui_pod_identity_role_name
  policy_arn = var.secrets_access_policy_arn
}

# --- Step 1: Render the YAML files to disk ---
#resource "local_file" "namespace" {
  content  = templatefile("${path.module}/namespace.yaml.tpl", {
    namespace = var.namespace
  })
  filename = "./namespace.yaml" 
}

resource "local_file" "cluster_secret_store" {
  content  = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
    aws_region = var.aws_region
  })
  filename = "./cluster-secret-store.yaml"
}

resource "local_file" "external_secret" {
  content  = templatefile("${path.module}/external-secret.yaml.tpl", {
    namespace      = var.namespace,
    db_secret_name = var.db_secret_name
  })
  filename = "./external-secret.yaml"
}


# --- Step 2: Use a Provisioner to Apply the Files ---
# The 'plan' for a null_resource is always trivial. The real work
# happens at 'apply' time.
resource "null_resource" "apply_manifests" {
  
  # This makes the resource depend on the files being written first.
  depends_on = [
    local_file.namespace,
    local_file.cluster_secret_store,
    local_file.external_secret
  ]

  # This provisioner runs during the 'apply' phase, after auth is configured.
  provisioner "local-exec" {
    # The command is the exact manual command we know works.
    # It applies the files in a specific, reliable order.
    command = <<EOT
      kubectl apply -f ${local_file.namespace.filename} && \
      echo "Namespace applied. Waiting 5 seconds..." && sleep 5 && \
      kubectl apply -f ${local_file.cluster_secret_store.filename} && \
      echo "ClusterSecretStore applied. Waiting 5 seconds..." && sleep 5 && \
      kubectl apply -f ${local_file.external_secret.filename}
    EOT
  }
}