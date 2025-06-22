# Terraform Infrastructure as Code

This directory contains the Terraform configuration for the AWS infrastructure, organized into modular components for better maintainability and separation of concerns.

## Architecture Overview

The infrastructure consists of the following AWS services:

### Core Infrastructure
- **EKS (Elastic Kubernetes Service)** - Main Kubernetes cluster
- **VPC** - Virtual Private Cloud with public/private subnets
- **NAT Gateway** - For private subnet internet access
- **IAM** - Various roles and policies for EKS, RDS, S3, Secrets Manager

### Database Services
- **RDS PostgreSQL** - Two instances:
  - Main PostgreSQL for OpenWebUI (vectordb)
  - LiteLLM PostgreSQL for LLM proxy
- **ElastiCache Redis** - For LiteLLM caching

### Storage & Secrets
- **S3** - Document storage for OpenWebUI
- **Secrets Manager** - Multiple secrets for:
  - PostgreSQL credentials
  - LiteLLM master/salt keys
  - API keys
  - Database connection strings

### Additional Services
- **ECR Public** - Container registry access
- **CloudWatch** - Logging and monitoring
- **Security Groups** - Network security for various services

## Directory Structure

```
terraform/
├── main.tf                 # Root module orchestrating all components
├── variables.tf            # Root module variables
├── outputs.tf              # Root module outputs
├── versions.tf             # Provider versions
├── eks/                    # EKS and VPC infrastructure
│   ├── main.tf            # Provider configuration and data sources
│   ├── vpc.tf             # VPC, subnets, NAT Gateway
│   ├── cluster.tf         # EKS cluster configuration
│   ├── variables.tf       # EKS module variables
│   ├── outputs.tf         # EKS module outputs
│   └── versions.tf        # EKS module provider versions
├── rds/                    # Database infrastructure
│   ├── main.tf            # Main PostgreSQL instance
│   ├── litellm-rds.tf     # LiteLLM PostgreSQL instance
│   ├── variables.tf       # RDS module variables
│   ├── outputs.tf         # RDS module outputs
│   └── versions.tf        # RDS module provider versions
├── s3/                     # S3 storage infrastructure
│   ├── main.tf            # S3 bucket and Pod Identity
│   ├── variables.tf       # S3 module variables
│   ├── outputs.tf         # S3 module outputs
│   └── versions.tf        # S3 module provider versions
├── secrets/                # Secrets Manager infrastructure
│   ├── main.tf            # Secrets and External Secrets Operator
│   ├── variables.tf       # Secrets module variables
│   ├── outputs.tf         # Secrets module outputs
│   └── versions.tf        # Secrets module provider versions
└── redis/                  # Redis cache infrastructure
    ├── main.tf            # ElastiCache Redis cluster
    ├── variables.tf       # Redis module variables
    ├── outputs.tf         # Redis module outputs
    └── versions.tf        # Redis module provider versions
```

## Module Dependencies

The modules have the following dependencies:

1. **EKS** - No dependencies (creates VPC and cluster)
2. **S3** - Depends on EKS (for cluster name)
3. **RDS** - Depends on EKS (for VPC and subnets)
4. **Redis** - Depends on EKS (for VPC and security groups)
5. **Secrets** - Depends on EKS and RDS (for cluster and secret ARNs)

## Usage

### Deploy All Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### Deploy Individual Modules

You can also deploy individual modules by navigating to their directories:

```bash
# Deploy only EKS
cd eks
terraform init
terraform plan
terraform apply

# Deploy only RDS (after EKS is deployed)
cd ../rds
terraform init
terraform plan
terraform apply
```

### Variables

The main variables can be configured in `variables.tf` or via command line:

```bash
terraform apply -var="name=my-cluster" -var="region=us-west-2"
```

### Outputs

After deployment, you can view the outputs:

```bash
terraform output
```

## Security Considerations

- All databases are encrypted at rest
- S3 buckets have public access blocked
- Security groups restrict access to necessary ports only
- IAM roles follow the principle of least privilege
- Secrets Manager is used for sensitive data storage

## Maintenance

### Updating Individual Components

To update a specific component, you can modify the corresponding module and apply changes:

```bash
# Update RDS configuration
cd rds
terraform plan
terraform apply

# Update S3 configuration
cd ../s3
terraform plan
terraform apply
```

### Destroying Infrastructure

To destroy all infrastructure:

```bash
terraform destroy
```

To destroy individual modules:

```bash
cd rds
terraform destroy
```

## Notes

- The infrastructure uses Terraform modules for better organization
- Each module has its own variables, outputs, and provider configurations
- Dependencies are managed through `depends_on` and module references
- The root module orchestrates all sub-modules and generates configuration files 