# Terraform Infrastructure as Code for Rafay Environment Templates

This directory contains the Terraform configuration for an AWS infrastructure, organized into decoupled, composable modules. This structure is specifically designed to be used with a platform engineering approach, such as **Rafay's Environment Templates**, where each folder represents an independent "lego block" or **Resource Template**.

## Rafay Platform Engineering Model

This repository follows a composable infrastructure model:
- **Resource Templates**: Each folder (`/eks`, `/rds`, `/s3`, `/apps`, etc.) is a standalone Terraform module intended to be a Rafay Resource Template.
- **Environment Templates**: A Rafay Environment Template defines which Resource Templates to deploy and orchestrates the dependencies between them.
- **Inputs & Outputs**: Rafay connects the templates by passing the outputs from one resource (e.g., VPC ID from the `eks` template) as inputs to another (e.g., the `rds` template).
- **Decoupling**: The modules themselves are fully decoupled. There are no hardcoded cross-module dependencies. For example, the `rds` module does not depend on the `s3` module. The connection is made by a dedicated `apps` module.

## Architecture Overview & Modules

The infrastructure consists of the following modular components:

- **`eks/`**: Deploys the foundational **EKS Cluster** and **VPC**. It outputs the network details and cluster identity information required by other modules.
- **`rds/`**: Deploys **RDS PostgreSQL** instances for application data and an optional LiteLLM proxy. It outputs database endpoints and the ARN of a secret access policy.
- **`s3/`**: Deploys an **S3 Bucket** for document storage and creates an **EKS Pod Identity IAM Role** for the OpenWebUI application.
- **`redis/`**: Deploys an **ElastiCache Redis** cluster for caching.
- **`secrets/`**: Manages **Secrets Manager** resources and deploys the **External Secrets Operator** to the cluster.
- **`apps/`**: A special "glue" module. It contains resources that connect other modules, such as the **IAM policy attachment** that grants the application role (from `s3`) permission to access secrets (from `rds`).

### Example Composition in Rafay

An Environment Template in Rafay would be configured with the following dependencies:

1.  `eks` (No dependencies)
2.  `s3` (Depends on `eks`)
3.  `rds` (Depends on `eks`)
4.  `redis` (Depends on `eks`)
5.  `secrets` (Depends on `eks`, `rds`)
6.  `apps` (Depends on `rds`, `s3`)

This ensures that networking and IAM roles are available before the resources that need them are created.

## Directory Structure

```
terraform/
├── main.tf                 # EXAMPLE root module showing how to compose the modules
├── README.md               # This documentation
├── eks/                    # EKS + VPC Resource Template
├── rds/                    # RDS Resource Template
├── s3/                     # S3 Resource Template
├── redis/                  # Redis Resource Template
├── secrets/                # Secrets Resource Template
└── apps/                   # App Integration/Glue Resource Template
```

## How Communication is Enabled

You asked specifically how the cluster can talk to RDS/S3 with this decoupled approach. This is achieved by passing outputs as inputs, orchestrated by the platform (Rafay):

1.  **Network**: The `eks` module creates the VPC and subnets. It **outputs** `vpc_id` and `private_subnet_ids`.
2.  The `rds` module takes `vpc_id` and `private_subnet_ids` as **input variables** to deploy the database into the correct network. It creates a security group allowing traffic from the VPC's CIDR range.
3.  **Permissions**:
    - The `rds` module creates an IAM policy to access its secrets and **outputs** the `policy_arn`.
    - The `s3` module creates the application's IAM role and **outputs** the `role_name`.
    - The `apps` module takes the `policy_arn` and `role_name` as **input variables** and creates the `aws_iam_role_policy_attachment` to link them.

This model ensures that if you have a use case that doesn't need S3, you simply don't include the `s3` or `apps` resource templates in your Rafay Environment Template. The `eks` and `rds` modules will still deploy successfully without any failures due to missing dependencies.

## EKS Node Groups

The EKS cluster is configured with three managed node groups:

### 1. General Purpose Node Group
- **Instance Types**: t3.medium, t3.large
- **Capacity Type**: ON_DEMAND
- **Min/Max Size**: 1/5 nodes
- **Desired Size**: 2 nodes
- **Use Case**: General workloads, system pods

### 2. GPU Node Group
- **Instance Types**: g5.xlarge, g5.2xlarge, g5.4xlarge
- **Capacity Type**: ON_DEMAND
- **Min/Max Size**: 0/3 nodes
- **Desired Size**: 0 nodes (scale up as needed)
- **Use Case**: ML/AI workloads requiring GPUs
- **Taints**: nvidia.com/gpu=true:NoSchedule

### 3. Spot Node Group
- **Instance Types**: t3.medium, t3.large, c6i.large, m6i.large
- **Capacity Type**: SPOT
- **Min/Max Size**: 0/5 nodes
- **Desired Size**: 0 nodes (scale up as needed)
- **Use Case**: Cost-optimized workloads
- **Taints**: spot=true:NoSchedule

## Module Dependencies

The modules have the following dependencies:

1. **EKS** - No dependencies (creates VPC and cluster with node groups)
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

## Node Group Management

### Scaling Node Groups

```bash
# Scale general node group
aws eks update-nodegroup-config \
  --cluster-name <cluster-name> \
  --nodegroup-name general \
  --scaling-config minSize=2,maxSize=10,desiredSize=5

# Scale GPU node group
aws eks update-nodegroup-config \
  --cluster-name <cluster-name> \
  --nodegroup-name gpu \
  --scaling-config minSize=1,maxSize=5,desiredSize=2
```

### Deploying to Specific Node Groups

```yaml
# Deploy to GPU nodes
apiVersion: v1
kind: Pod
metadata:
  name: gpu-app
spec:
  containers:
  - name: gpu-app
    image: nvidia/cuda:11.0-base
    resources:
      limits:
        nvidia.com/gpu: 1
  tolerations:
  - key: nvidia.com/gpu
    operator: Equal
    value: "true"
    effect: NoSchedule
  nodeSelector:
    NodeGroup: gpu
```

## Security Considerations

- All databases are encrypted at rest
- S3 buckets have public access blocked
- Security groups restrict access to necessary ports only
- IAM roles follow the principle of least privilege
- Secrets Manager is used for sensitive data storage
- Node groups use appropriate taints and labels for workload isolation

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

## Migration from Automode

This configuration has been migrated from EKS automode to traditional managed node groups. Key changes:

- Removed Karpenter automode configuration
- Added three managed node groups (general, gpu, spot)
- Removed automode-specific subnet tags
- Added proper node group labels and taints
- Maintained all existing functionality with better control

## Notes

- The infrastructure uses Terraform modules for better organization
- Each module has its own variables, outputs, and provider configurations
- Dependencies are managed through `depends_on` and module references
- The root module orchestrates all sub-modules and generates configuration files 