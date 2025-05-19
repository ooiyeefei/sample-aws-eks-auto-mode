# Setting up EKS Auto Mode using Terraform

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Setup Open Webui](#setup-open-webui)
- [PostgreSQL with pg_vector](#postgresql-with-pg_vector)
- [Cleanup](#cleanup)
- [Contributing](#contributing)
- [License and Disclaimer](#license-and-disclaimer)

## Overview
[Amazon EKS Auto Mode](https://aws.amazon.com/eks/auto-mode/) simplifies Kubernetes cluster management on AWS. Key benefits include:

🚀 **Simplified Management**
- One-click cluster provisioning
- Automated compute, storage, and networking
- Seamless integration with AWS services

⚡ **Workload Support**
- Graviton instances for optimal price-performance
- GPU acceleration for ML/AI workloads
- Inferentia2 for cost-effective ML inference
- Mixed architecture support

🔧 **Infrastructure Features**
- Auto-scaling with Karpenter
- Automated load balancer configuration
- Cost optimization through node consolidation

This repository provides a production-ready template for deploying various workloads on EKS Auto Mode.

## Prerequisites

🛠️ **Required Tools**
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

> **Note**: This project currently provides Linux-specific commands in the examples. Windows compatibility will be added in future updates.

## Quick Start

1. **Clone Repository**:
```bash
# Get the code
git clone https://github.com/aws-samples/sample-aws-eks-auto-mode.git
cd sample-aws-eks-auto-mode

# Configure remote
git remote set-url origin https://github.com/aws-samples/sample-aws-eks-auto-mode.git

git checkout cgk
```

2. **Deploy Cluster**:
```bash
# Navigate to Terraform directory
cd terraform

# Initialize and apply Terraform
terraform init
terraform apply -auto-approve

# Configure kubectl
$(terraform output -raw configure_kubectl)
```

## Setup Open Webui

Proceed over to [setup-open-webui](./setup-openwebui/)

## PostgreSQL with pg_vector

This project includes an RDS PostgreSQL instance with pg_vector extension for vector database capabilities.

### RDS PostgreSQL Setup

The deployment includes:
- PostgreSQL 15.3 with pg_vector extension
- Multi-AZ deployment for high availability
- Encrypted storage with autoscaling
- Deployed in private subnets for security

### Post-Deployment Steps

After the infrastructure is deployed, follow these steps to complete the pg_vector setup:

1. **Get the RDS endpoint**:
```bash
# Navigate to Terraform directory
cd terraform

# Get the RDS endpoint
terraform output rds_endpoint
```

2. **Connect to the PostgreSQL database**:
```bash
# Install PostgreSQL client if needed
sudo apt-get update && sudo apt-get install -y postgresql-client

# Connect to the database (replace with your actual endpoint)
psql -h <rds_endpoint> -U postgres -d vectordb
# Enter the password when prompted (default: YourStrongPasswordHere)
```

3. **Create the pg_vector extension**:
```sql
-- Once connected to PostgreSQL, run:
CREATE EXTENSION vector;

-- Verify the extension is installed
\dx
```

4. **Test the vector functionality**:
```sql
-- Create a test table with vector data
CREATE TABLE items (
  id serial PRIMARY KEY,
  embedding vector(3)
);

-- Insert some test vectors
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]'), ('[7,8,9]');

-- Query using vector similarity
SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```

> **Security Note**: For production use, change the default password using AWS Secrets Manager or SSM Parameter Store.

## Cleanup

🧹 Follow these steps to remove all resources:

```bash
# Navigate to Terraform directory
cd terraform

# Initialize and destroy infrastructure
terraform init
terraform destroy --auto-approve
```
## Contributing
Contributions welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

## License and Disclaimer

### License
This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

### Disclaimer
**This repository is intended for demonstration and learning purposes only.**
It is **not** intended for production use. The code provided here is for educational purposes and should not be used in a live environment without proper testing, validation, and modifications.

Use at your own risk. The authors are not responsible for any issues, damages, or losses that may result from using this code in production.

In this samples, there may be use of third-party models ("Third-Party Models") that AWS does not own, and that AWS does not exercise control over. By using any prototype or proof of concept from AWS you acknowledge that the Third-Party Models are "Third-Party Content" under your agreement for services with AWS. You should perform your own independent assessment of the Third-Party Models. You should also take measures to ensure that your use of the Third-Party Models complies with your own specific quality control practices and standards, and the local rules, laws, regulations, licenses and terms of use that apply to you, your content, and the Third-Party Models. AWS does not make any representations or warranties regarding the Third-Party Models, including that use of the Third-Party Models and the associated outputs will result in a particular outcome or result. You also acknowledge that outputs generated by the Third-Party Models are Your Content/Customer Content, as defined in the AWS Customer Agreement or the agreement between you and AWS for AWS Services. You are responsible for your use of outputs from the Third-Party Models.
