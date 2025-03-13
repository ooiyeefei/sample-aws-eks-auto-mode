# Setting up EKS Auto Mode using Terraform

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Examples](#examples)
- [Cleanup](#cleanup)
- [Security Considerations](#security-considerations)
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
```

2. **Deploy Cluster**:
```bash
# Navigate to Terraform directory
cd sample-aws-eks-auto-mode/terraform

# Initialize and apply Terraform
terraform init
terraform apply -auto-approve

# Configure kubectl
$(terraform output -raw configure_kubectl)
```

## Architecture

### 🔄 NodePools
EKS Auto Mode leverages [Karpenter](https://karpenter.sh/docs/) for intelligent node management:

⚡ **Auto-scaling Features**
- Dynamic node provisioning
- Workload-aware scaling
- Resource optimization

📦 **Preconfigured NodePools**
In these samples we configure the following Nodepools for you:
- ARM64-optimized Graviton nodes
- GPU-accelerated compute nodes

> 📘 **Note**: Check [NodePool Templates](/nodepool-templates) for detailed configurations.

### 🌐 Load Balancer Configuration
EKS Auto Mode automates load balancer setup with AWS best practices:

1. 🔹 **Application Load Balancer (ALB)**
   - IngressClass-based configuration
   - [AWS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-alb.html)
   - Example: [2048 Game Ingress](/examples/graviton/2048-ingress.yaml)

2. 🔸 **Network Load Balancer (NLB)**
   - Native Kubernetes service integration
   - [AWS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-nlb.html)
   - Example: [GPU Web UI Service](/examples/gpu/lb-service.yaml)

> **Important**: If subnet IDs are not specified in IngressClassParams, AWS requires specific tags on subnets for proper load balancer functionality:
> - Public subnets: `kubernetes.io/role/elb: "1"`
> - Private subnets: `kubernetes.io/role/internal-elb: "1"`
> 
> Our Terraform code automatically creates these necessary subnet tags, but you may need to add them manually if using custom networking configurations.

## Examples

🚀 Get started with our sample workloads:

### ARM64 Applications
🎮 [Running Graviton Workloads](examples/graviton/)
- Cost-effective ARM64 deployments
- Optimized performance
- Example: 2048 game application

### GPU Applications
📱 [Running GPU Workloads](examples/gpu/)
- ML/AI model deployment
- GPU-accelerated computing
- Example: DeepSeek model inference

## Cleanup

🧹 Follow these steps to remove all resources:

```bash
# Navigate to Terraform directory
cd terraform

# Initialize and destroy infrastructure
terraform init
terraform destroy --auto-approve
```

> ⚠️ **Warning**: This will delete all cluster resources. Make sure to back up any important data.

## Security Considerations
Our code is continuously scanned using [Checkov](https://www.checkov.io/5.Policy%20Index/kubernetes.html). The following security considerations are documented for transparency:

|Checks	|Details	|Reasons	|
|---	|---	|---	|
|CKV_TF_1	|Ensure Terraform module sources use a commit hash	|For easy experimentation, we set version of module, instead of setting a commit hash. Consider implementing a commit hash in a production cluster. [Read more on why we need to set commit hash for modules here.](https://medium.com/boostsecurity/erosion-of-trust-unmasking-supply-chain-vulnerabilities-in-the-terraform-registry-2af48a7eb2)	|
|CKV2_K8S_6	|Minimize the admission of pods which lack an associated NetworkPolicy	|All Pod to Pod communication is allowed by default for easy experimentation in this project. Amazon VPC CNI now supports [Kubernetes Network Policies](https://aws.amazon.com/blogs/containers/amazon-vpc-cni-now-supports-kubernetes-network-policies/) to secure network traffic in kubernetes clusters	|
|CKV_K8S_8	|Liveness Probe Should be Configured	|For easy experimentation, no health checks is to be performed against the container to determine whether it is alive or not. Consider implementing [health checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) in a production cluster.	|
|CKV_K8S_9	|Readiness Probe Should be Configured	|For easy experimentation, no health checks is to be performed against the container to determine whether it is alive or not. Consider implementing health checks in a production cluster.	|
|CKV_K8S_22	|Use read-only filesystem for containers where possible	|We've made an exception for the workloads that requires are Read/Write file system. [Configure your images with read-only root file system](https://docs.aws.amazon.com/eks/latest/best-practices/pod-security.html#_configure_your_images_with_read_only_root_file_system)	|
|CKV_K8S_23	|Minimize the admission of root containers	|This project uses default root container configurations for demonstration purposes. While this doesn't follow security best practices, it ensures compatibility with demo images. For production, configure runAsNonRoot: true and follow [guidance](https://docs.docker.com/engine/reference/builder/#user) on building images with specified user ID.  	|
|CKV_K8S_37	|Minimize the admission of containers with capabilities assigned	|For easy experimentation, we've made exception for the workloads that requires added capability. For production purposes, we recommend [capabilities field](https://docs.aws.amazon.com/eks/latest/best-practices/pod-security.html#_linux_capabilities) that allows granting certain privileges to a process without granting all the privileges of the root user.  	|
|CKV_K8S_40	|Containers should run as a high UID to avoid host conflict	|We've used publicly available container images in this project for customers' easy access. For test purposes, the container images user id are left intact. See [how to define UID](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod).	| 

## Contributing
Contributions welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

## License and Disclaimer

### License
This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

### Disclaimer
**This repository is intended for demonstration and learning purposes only.**
It is **not** intended for production use. The code provided here is for educational purposes and should not be used in a live environment without proper testing, validation, and modifications.

Use at your own risk. The authors are not responsible for any issues, damages, or losses that may result from using this code in production.

In this samples, there may be use of third-party models (“Third-Party Models”) that AWS does not own, and that AWS does not exercise control over. By using any prototype or proof of concept from AWS you acknowledge that the Third-Party Models are “Third-Party Content” under your agreement for services with AWS. You should perform your own independent assessment of the Third-Party Models. You should also take measures to ensure that your use of the Third-Party Models complies with your own specific quality control practices and standards, and the local rules, laws, regulations, licenses and terms of use that apply to you, your content, and the Third-Party Models. AWS does not make any representations or warranties regarding the Third-Party Models, including that use of the Third-Party Models and the associated outputs will result in a particular outcome or result. You also acknowledge that outputs generated by the Third-Party Models are Your Content/Customer Content, as defined in the AWS Customer Agreement or the agreement between you and AWS for AWS Services. You are responsible for your use of outputs from the Third-Party Models.
