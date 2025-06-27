# Generate random strings for LiteLLM master and salt keys
resource "random_password" "litellm_master_key" {
  length  = 21
  special = false
}

resource "random_password" "litellm_salt_key" {
  length  = 21
  special = false
}

# Create a secret for LiteLLM master and salt keys
resource "aws_secretsmanager_secret" "litellm_master_salt" {
  name_prefix = "${var.name}-litellm-master-salt-"
  recovery_window_in_days = 0
  
  tags = {
    Name = "${var.name}-litellm-master-salt"
  }
}

locals {
  litellm_master_key = "sk-${random_password.litellm_master_key.result}"
  litellm_salt_key = "sk-${random_password.litellm_salt_key.result}"
}

# Store the generated values
resource "aws_secretsmanager_secret_version" "litellm_master_salt_ver" {
  secret_id = aws_secretsmanager_secret.litellm_master_salt.id

  secret_string = jsonencode({
    LITELLM_MASTER_KEY = local.litellm_master_key
    LITELLM_SALT_KEY   = local.litellm_salt_key
  })
}

# Create a secret for LiteLLM API keys (for external providers)
resource "aws_secretsmanager_secret" "litellm_api_keys" {
  name_prefix = "${var.name}-litellm-api-keys-"
  recovery_window_in_days = 0
  
  tags = {
    Name = "${var.name}-litellm-api-keys"
  }
}

# Store empty JSON object initially - will be populated by update-secrets.sh script
resource "aws_secretsmanager_secret_version" "litellm_api_keys_ver" {
  secret_id = aws_secretsmanager_secret.litellm_api_keys.id

  secret_string = jsonencode({
    # This will be populated dynamically by the update-secrets.sh script
    # which reads all key-value pairs from the .env file
  })
}

# Create Pod Identity for External Secrets
module "external_secrets_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "external-secrets"

  # Custom policy for Secrets Manager access with expanded permissions
  attach_custom_policy = true
  policy_statements = [
    {
      sid       = "SecretsManagerAccess"
      actions   = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:ListSecretVersionIds"
      ]
      resources = var.secret_arns
    }
  ]

  # Create Pod Identity Association
  associations = {
    external_secrets = {
      service_account      = "external-secrets-sa"
      namespace            = "external-secrets"
      cluster_name         = var.cluster_name
    }
  }

  tags = {
    Environment = var.name
  }
}

# Install External Secrets Operator with ClusterSecretStore
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets"
  create_namespace = true

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-secrets-sa"
    }
  ]

  # Wait for the chart to be installed
  wait = true
  timeout = 300
} 

module "aws_ebs_csi_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  
  name = "${var.cluster_name}-ebs-csi-driver"

  attach_aws_ebs_csi_policy = true

  # Set the common values for all associations here.
  association_defaults = {
    namespace       = "kube-system"
    service_account = "ebs-csi-controller-sa"
  }

  # Provide the unique values for each association.
  # The key 'this_cluster' is a logical map key for Terraform.
  associations = {
    this_cluster = {
      cluster_name = var.cluster_name
    }
  }

  tags = {
    Environment = var.name
  }
}