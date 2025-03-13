# Graviton Workloads on EKS Auto Mode

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Implementation Steps](#implementation-steps)
- [Cleanup](#cleanup)
- [Troubleshooting](#troubleshooting)

## Overview
[AWS Graviton](https://aws.amazon.com/ec2/graviton/) processors deliver the best price performance for your cloud workloads running on Amazon EC2. Key benefits include:

💰 **Cost Optimization**
- Up to 40% better price performance over comparable x86-based instances
- Pay only for the compute resources you use

⚡ **Performance**
- Custom-built ARM-based processors by AWS
- Optimized for cloud-native applications

🔒 **Requirements**
- Applications must be ARM64 compatible
- Proper configuration of node taints and tolerations

## Architecture
This example demonstrates how to run Graviton workloads on EKS Auto Mode by configuring Karpenter to provision ARM64-compatible nodes.

**Key Components**:
📄 **NodePool Template**
- Defines Graviton instance requirements
- Available [here](../../nodepool-templates/graviton-nodepool.yaml.tpl)

🔄 **Load Balancer**
- Application Load Balancer (ALB)
- Exposes the application to external traffic

🎮 **Sample Application**
- 2048 game (sliding tile puzzle)
- ARM64-compatible container image

## Implementation Steps

### 1. Setup EKS Auto Mode Cluster
First, we'll set up our EKS cluster using Terraform:

```bash
cd sample-aws-eks-auto-mode/terraform

terraform init
terraform apply -auto-approve

$(terraform output -raw configure_kubectl)
```

### 2. Deploy Graviton NodePool
Deploy the NodePool that will manage our Graviton instances:

```bash
cd ../nodepools

kubectl apply -f graviton-nodepool.yaml
```

> ⚠️ The Graviton NodePool applies the following taint to ensure only ARM64-compatible workloads are scheduled on these nodes:
>
> ```yaml
> taints:
>   - key: "arm64"
>     value: "true"
>     effect: "NoSchedule"   # Prevents non-ARM64 pods from scheduling
> ```
>
> Any pods that need to run on Graviton nodes must include matching tolerations in their specifications. This ensures workload compatibility with the ARM64 architecture.

### 3. Deploy the 2048 Game
Deploy our ARM64-compatible 2048 game application:

```bash
cd ../examples/graviton

kubectl apply -f game-2048.yaml
```


> ✅ The 2048 game deployment includes the required toleration to run on Graviton nodes:
>
> ```yaml
> tolerations:
>   - key: "arm64"     # Matches the Graviton node taint
>     value: "true"
>     effect: "NoSchedule"   # Allows scheduling on tainted nodes
> ```
>
> This toleration enables the pods to be scheduled on our ARM64 Graviton instances.

### 4. Configure Load Balancer
Set up the Application Load Balancer using Ingress:

```bash
kubectl apply -f 2048-ingress.yaml
```

### 5. Configure Security Groups
Configure security group rules to allow communication between the ALB and EKS cluster:

```bash
# Set AWS region
aws configure set region us-west-2

# Get security group IDs
ALB_SG=$(aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(DNSName, `game2048`)].SecurityGroups[0]' \
  --output text)
EKS_SG=$(aws eks describe-cluster \
  --name automode-cluster \
  --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' \
  --output text)

# Allow ALB to communicate with EKS cluster
aws ec2 authorize-security-group-ingress \
  --group-id $EKS_SG \
  --source-group $ALB_SG \
  --protocol tcp \
  --port 80
```

### 6. Access the Application
After the ALB is provisioned (usually takes 5-10 minutes):

1. Get the ALB hostname:
```bash
kubectl get ingress ingress-2048 \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' \
  -n game-2048
```

2. Open the URL in your browser to play the 2048 game! 🎮

## Cleanup

🧹 Follow these steps to clean up all resources:

### 1. Remove Kubernetes Resources
First, remove the application and node pool:

```bash
# Remove application components
kubectl delete -f 2048-ingress.yaml
kubectl delete -f game-2048.yaml

# Remove Graviton node pool
kubectl delete -f ../../nodepools/graviton-nodepool.yaml
```

### 2. Remove Cluster (Optional)
If you're done with the entire cluster:

```bash
# Navigate to Terraform directory
cd ../../terraform

# Initialize and destroy infrastructure
terraform init
terraform destroy --auto-approve
```

> ⚠️ **Warning**: This will delete the entire EKS cluster and all associated resources. Make sure you want to proceed.

## Troubleshooting

🔧 Common issues and their solutions:

### Ingress Issues
If your ALB ingress isn't working properly:

1. **Stuck Ingress Deletion**
```bash
# Remove finalizers if ingress is stuck
kubectl -n game-2048 patch ingress ingress-2048 \
  -p '{"metadata":{"finalizers":null}}' \
  --type=merge
```

2. **ALB Controller Issues**
```bash
# Check ALB controller logs for errors
kubectl logs -n kube-system \
  deployment/aws-load-balancer-controller
```

> 💡 **Tip**: Always verify the ALB security group configuration if you're having connectivity issues.
