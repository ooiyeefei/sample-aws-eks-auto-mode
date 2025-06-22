provider "aws" {
  region = var.region
}

# This provider is required for ECR to authenticate with public repos. Please note ECR authentication requires us-east-1 as region hence its hardcoded below.
# If your region is same as us-east-1 then you can just use one aws provider
provider "aws" {
  alias  = "ecr"
  region = "us-east-1"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

################################################################################
# Common data/locals
################################################################################

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.ecr
}

#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones
data "aws_availability_zones" "available" {
  # Do not include local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  # Number of AZs we wish to create
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Blueprint  = var.name
  }
}

# Root module that orchestrates all infrastructure components

# EKS Module
module "eks" {
  source = "./eks"
  
  name                 = var.name
  region              = var.region
  eks_cluster_version = var.eks_cluster_version
  vpc_cidr            = var.vpc_cidr
}

# RDS Module
module "rds" {
  source = "./rds"
  
  name = var.name
  vpc_id = module.eks.vpc_id
  vpc_cidr = var.vpc_cidr
  private_subnets = module.eks.private_subnets
  openwebui_pod_identity_role_name = module.s3.openwebui_pod_identity_role_name
  
  depends_on = [module.eks]
}

# S3 Module
module "s3" {
  source = "./s3"
  
  name = var.name
  cluster_name = module.eks.cluster_name
  
  depends_on = [module.eks]
}

# Secrets Module
module "secrets" {
  source = "./secrets"
  
  name = var.name
  cluster_name = module.eks.cluster_name
  secret_arns = [
    module.rds.postgres_secret_arn,
    module.rds.db_connection_string_arn,
    module.rds.litellm_postgres_secret_arn,
    module.rds.litellm_db_connection_string_arn
  ]
  
  depends_on = [module.eks, module.rds]
}

# Redis Module
module "redis" {
  source = "./redis"
  
  name = var.name
  vpc_id = module.eks.vpc_id
  private_subnets = module.eks.private_subnets
  eks_security_group_id = module.eks.cluster_primary_security_group_id
  tags = {
    Blueprint = var.name
  }
  
  depends_on = [module.eks]
}

# Setup and template generation
resource "null_resource" "create_nodepools_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/../nodepools"
  }
}

resource "local_file" "setup_graviton" {
  content = templatefile("${path.module}/../nodepool-templates/graviton-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../nodepools/graviton-nodepool.yaml"
}

resource "local_file" "setup_spot" {
  content = templatefile("${path.module}/../nodepool-templates/spot-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../nodepools/spot-nodepool.yaml"
}

resource "local_file" "setup_gpu" {
  content = templatefile("${path.module}/../nodepool-templates/gpu-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../nodepools/gpu-nodepool.yaml"
}

resource "local_file" "setup_neuron" {
  content = templatefile("${path.module}/../nodepool-templates/neuron-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../nodepools/neuron-nodepool.yaml"
}

resource "local_file" "setup_openwebui_values" {
  content = templatefile("${path.module}/../setup-openwebui/templates/values.yaml.tpl", {
    s3_bucket_name = module.s3.openwebui_s3_bucket
    region         = var.region
    rds_endpoint   = module.rds.rds_endpoint
  })
  filename = "${path.module}/../setup-openwebui/values.yaml"
}

resource "local_file" "setup_openwebui_secret" {
  content = templatefile("${path.module}/../setup-openwebui/templates/secret.yaml.tpl", {
    secret_name    = module.rds.db_connection_string_arn
  })
  filename = "${path.module}/../setup-openwebui/secret.yaml"
}

resource "local_file" "setup_pgvector_job" {
  content = templatefile("${path.module}/../setup-openwebui/templates/pgvector-job.yaml.tpl", {})
  filename = "${path.module}/../setup-openwebui/pgvector-job.yaml"
}

resource "local_file" "setup_cluster_secret_store" {
  content = templatefile("${path.module}/../setup-openwebui/templates/cluster-secret-store.yaml.tpl", {
    region = var.region
  })
  filename = "${path.module}/../setup-openwebui/cluster-secret-store.yaml"
}

# LiteLLM template generation
locals {
  # Read the litellm-models.yaml file and indent it properly for YAML
  litellm_models_content = fileexists("${path.module}/../litellm-models.yaml") ? file("${path.module}/../litellm-models.yaml") : "# No models configured"
  # Add proper indentation (6 spaces) for each line
  litellm_models_indented = join("\n", [for line in split("\n", local.litellm_models_content) : line != "" ? "      ${line}" : ""])
}

resource "local_file" "setup_litellm_configmap" {
  content = templatefile("${path.module}/../setup-litellm/templates/configmap.yaml.tpl", {
    model_list = local.litellm_models_indented
    redis_host = module.redis.redis_primary_endpoint
    redis_port = module.redis.redis_port
    redis_password = module.redis.redis_password
  })
  filename = "${path.module}/../setup-litellm/configmap.yaml"
}

resource "local_file" "setup_litellm_secret" {
  content = templatefile("${path.module}/../setup-litellm/templates/secret.yaml.tpl", {
    litellm_master_salt_secret_name = module.secrets.litellm_master_salt_secret_arn
    litellm_db_connection_secret_name = module.rds.litellm_db_connection_string_arn
    litellm_api_keys_secret_name = module.secrets.litellm_api_keys_secret_arn
  })
  filename = "${path.module}/../setup-litellm/secret.yaml"
}