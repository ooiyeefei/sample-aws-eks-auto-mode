# S3 bucket for Open WebUI document storage
resource "aws_s3_bucket" "openwebui_docs" {
  bucket = "${var.name}-openwebui-docs"
  
  tags = {
    Name = "${var.name}-openwebui-docs"
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "openwebui_docs" {
  bucket = aws_s3_bucket.openwebui_docs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "openwebui_docs" {
  bucket = aws_s3_bucket.openwebui_docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create IAM role for Open WebUI using the EKS Pod Identity module
module "openwebui_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "openwebui"

  # Custom policy for S3 access
  attach_custom_policy = true
  policy_statements = [
    {
      sid       = "S3Access"
      actions   = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      resources = [
        aws_s3_bucket.openwebui_docs.arn,
        "${aws_s3_bucket.openwebui_docs.arn}/*"
      ]
    }
  ]

  # Create Pod Identity Association
  associations = {
    openwebui = {
      service_account      = "open-webui-pia"
      namespace            = "vllm-inference"
      cluster_name         = module.eks.cluster_name
    }
  }

  tags = {
    Environment = var.name
  }
}

# Output the S3 bucket name and Pod Identity details
output "openwebui_s3_bucket" {
  description = "The name of the S3 bucket for Open WebUI document storage"
  value       = aws_s3_bucket.openwebui_docs.id
}

output "openwebui_pod_identity_role_arn" {
  description = "The ARN of the IAM role for Open WebUI Pod Identity"
  value       = module.openwebui_pod_identity.iam_role_arn
}
