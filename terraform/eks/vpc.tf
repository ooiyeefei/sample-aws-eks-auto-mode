module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  # Enable DNS hostnames and DNS resolution
  enable_dns_hostnames = true
  enable_dns_support   = true

  # EKS required tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${var.name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/${var.name}" = "shared"
  }

  # Additional tags for better resource management
  tags = merge(local.tags, {
    "kubernetes.io/cluster/${var.name}" = "shared"
  })
} 