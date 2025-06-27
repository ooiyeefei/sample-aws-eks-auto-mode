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

resource "null_resource" "apply_namespace" {
  # This depends on auth being ready.
  depends_on = [data.aws_eks_cluster_auth.cluster]

  provisioner "local-exec" {
    # 'kubectl apply -f -' reads from standard input.
    command = "echo \"$MANIFEST\" | kubectl apply -f -"
    
    # The 'environment' map passes the rendered YAML content into the
    # shell's environment as a variable named MANIFEST.
    environment = {
      MANIFEST = templatefile("${path.module}/namespace.yaml.tpl", {
        namespace = var.namespace
      })
    }
  }
}

resource "null_resource" "apply_cluster_secret_store" {
  # This depends on the namespace apply finishing.
  depends_on = [null_resource.apply_namespace]

  provisioner "local-exec" {
    command     = "echo \"$MANIFEST\" | kubectl apply -f -"
    interpreter = ["/bin/sh", "-c"] # Good practice for complex commands

    # Add a small, deliberate pause before applying.
    on_failure  = "continue" # Prevent failure from stopping the whole chain
    
    environment = {
      MANIFEST = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
        aws_region = var.aws_region
      })
    }
    
    # Run a wait command after applying
    post_apply_command = "sleep 5"
  }
  
   provisioner "local-exec" {
     when = "destroy"
     command = "echo \"$MANIFEST\" | kubectl delete -f -"
      environment = {
      MANIFEST = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
        aws_region = var.aws_region
      })
    }
   }
}


resource "null_resource" "apply_external_secret" {
  # This depends on the ClusterSecretStore apply finishing.
  depends_on = [null_resource.apply_cluster_secret_store]

  provisioner "local-exec" {
    command = "echo \"$MANIFEST\" | kubectl apply -f -"
    
    environment = {
      MANIFEST = templatefile("${path.module}/external-secret.yaml.tpl", {
        namespace      = var.namespace,
        db_secret_name = var.db_secret_name
      })
    }
  }
}