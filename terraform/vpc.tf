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

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery" = "automode-demo"
  }

  tags = local.tags
}

# S3 Gateway VPC Endpoint for secure, private access to S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  
  # Associate with private subnet route tables
  route_table_ids = module.vpc.private_route_table_ids
  
  # VPC Endpoint policy for additional security
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Access"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalServiceName" = [
              "eks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
  
  tags = merge(local.tags, {
    Name = "${var.name}-s3-vpc-endpoint"
    Purpose = "Secure S3 access for OpenWebUI"
  })
}

# Output the VPC Endpoint ID for reference
output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC Endpoint"
  value       = aws_vpc_endpoint.s3.id
}
