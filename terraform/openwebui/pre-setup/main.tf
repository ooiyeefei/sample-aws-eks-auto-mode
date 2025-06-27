# terraform/openwebui/pre-setup/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
  }
}

# --- Direct EKS Authentication (This part is correct and remains) ---
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

resource "aws_iam_role_policy_attachment" "secrets_access_to_openwebui" {
  role       = var.openwebui_pod_identity_role_name
  policy_arn = var.secrets_access_policy_arn
}


# --- Apply Manifests by Piping Directly to Kubectl Stdin ---

resource "null_resource" "apply_namespace" {
  depends_on = [data.aws_eks_cluster_auth.cluster]

  provisioner "local-exec" {
    command     = "echo \"$MANIFEST\" | kubectl apply -f -"
    environment = {
      MANIFEST = templatefile("${path.module}/namespace.yaml.tpl", {
        namespace = var.namespace
      })
    }
  }
}

resource "null_resource" "apply_cluster_secret_store" {
  depends_on = [null_resource.apply_namespace]

  # THE FIX: Use 'triggers' to safely pass variables to provisioners.
  triggers = {
    # This makes var.aws_region available as self.triggers.aws_region_trigger
    aws_region_trigger = var.aws_region
  }

  # Create-time provisioner
  provisioner "local-exec" {
    command     = "sleep 5 && echo \"$MANIFEST\" | kubectl apply -f -"
    interpreter = ["/bin/sh", "-c"]
    environment = {
      # Use the trigger value to render the manifest
      MANIFEST = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
        aws_region = self.triggers.aws_region_trigger
      })
    }
  }

  # Destroy-time provisioner
  provisioner "local-exec" {
    when    = "destroy"
    command = "echo \"$MANIFEST\" | kubectl delete -f -"
    environment = {
      # It is now safe to use the trigger value here
      MANIFEST = templatefile("${path.module}/cluster-secret-store.yaml.tpl", {
        aws_region = self.triggers.aws_region_trigger
      })
    }
  }
}

resource "null_resource" "apply_external_secret" {
  depends_on = [null_resource.apply_cluster_secret_store]

  provisioner "local-exec" {
    command     = "sleep 5 && echo \"$MANIFEST\" | kubectl apply -f -"
    interpreter = ["/bin/sh", "-c"]
    environment = {
      MANIFEST = templatefile("${path.module}/external-secret.yaml.tpl", {
        namespace      = var.namespace,
        db_secret_name = var.db_secret_name
      })
    }
  }
}