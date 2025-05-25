# LiteLLM Setup

> **🔄 Step 3 of 3**: This should be completed after OpenWebUI setup is finished.

## Overview

This directory contains the configuration files and deployment manifests for setting up LiteLLM as a multi-provider AI gateway on EKS Auto Mode. LiteLLM provides a unified interface to access multiple LLM providers, cost tracking, rate limiting, and caching capabilities.

## Architecture

LiteLLM is deployed with the following components:

- **LiteLLM Gateway**: Main proxy service that routes requests to different LLM providers
- **Redis (ElastiCache)**: Used for caching and session management
- **PostgreSQL (RDS)**: Stores LiteLLM configuration, user management, and usage tracking
- **AWS Secrets Manager**: Securely stores database credentials and API keys
- **External Secrets Operator**: Syncs secrets from AWS Secrets Manager to Kubernetes

## Prerequisites

Before deploying LiteLLM, ensure you have:

1. ✅ **Completed**: Main Terraform infrastructure deployment ([see main README](../README.md))
2. ✅ **Completed**: OpenWebUI setup ([see OpenWebUI README](../setup-openwebui/))

## Deployment Steps

### 1. Navigate to LiteLLM Directory

```bash
cd setup-litellm
```

### 2. Deploy Kubernetes Resources

Deploy the resources in the following order:

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Create service account with Pod Identity
kubectl apply -f serviceaccount.yaml

# Apply External Secrets to fetch credentials from AWS Secrets Manager
# Note: ClusterSecretStore already exists from OpenWebUI setup
kubectl apply -f secret.yaml

# Create ConfigMap with LiteLLM configuration
kubectl apply -f configmap.yaml

# Deploy LiteLLM application
kubectl apply -f deployment.yaml

# Create service
kubectl apply -f service.yaml

# Create ingress for external access (uses EKS Auto Mode format)
kubectl apply -f ingress.yaml
```

> **Note**: The ClusterSecretStore (`aws-secretsmanager`) was already created during OpenWebUI setup and is shared between both applications.

### 3. Verify Deployment

Check that all components are running:

```bash
# Check pods
kubectl get pods -n litellm

# Check services
kubectl get svc -n litellm

# Check ingress and IngressClass
kubectl get ingress -n litellm
kubectl get ingressclass -n litellm

# Check secrets (should be populated by External Secrets Operator)
kubectl get secrets -n litellm
```

### 4. Get Access URL

Get the ALB URL for accessing LiteLLM:

```bash
# Wait for ALB to be provisioned (may take a few minutes)

# Get the load balancer URL
export LB_URL=$(kubectl get ingress litellm-ingress -n litellm -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Display the URL
echo "LiteLLM is available at: http://$LB_URL"
```

Click on the *LiteLLM Admin Panel on /ui* hyperlink. 

Login Details:
```bash
echo "Username: admin"
echo "Password: $(kubectl get secret litellm-master-salt -n litellm -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d)"
```

## Usage

### Basic API Usage

Once deployed, you can use LiteLLM's OpenAI-compatible API:

```bash
# Get the master key from secrets
MASTER_KEY=$(kubectl get secret litellm-master-salt -n litellm -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d)

# Make a request to the deepseek model through LiteLLM
curl -X POST "http://$LB_URL/v1/chat/completions" \
  -H "Authorization: Bearer $MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek",
    "messages": [{"role": "user", "content": "Hello, how are you?"}]
  }'
```

### Integration with OpenWebUI

To use LiteLLM as a proxy for OpenWebUI:

```bash
# Get the LiteLLM master key
MASTER_KEY=$(kubectl get secret litellm-master-salt -n litellm -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d)

# Get the OpenWebUI URL
OPENWEBUI_URL=$(kubectl get service open-webui-service -n vllm-inference -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "OpenWebUI settings is available at: http://$OPENWEBUI_URL/admin/settings"
```

Go to admin settings --> Go to connections --> Create a new OpenAI API Connection

Use the following values:
```bash
echo "URL: http://litellm-service.litellm.svc.cluster.local:4000/v1"
echo "API Key: $MASTER_KEY"
```

Now go create a new chat and you should have new model.
- deepseek is the deepseek model via litellm
- deepseek-ai/DeepSeek-R1-Distill-Qwen-32B is the mdoel directly served by vLLM

## Security Considerations

- All database credentials are stored in AWS Secrets Manager
- Pod Identity is used for secure access to AWS services
- Redis and PostgreSQL use encryption in transit and at rest
- API keys for external providers are managed through AWS Secrets Manager
- ClusterSecretStore is shared securely between OpenWebUI and LiteLLM

## Cost Optimization

- Redis cluster uses `cache.t3.micro` instances for cost efficiency
- PostgreSQL uses `db.t3.micro` instance class
- Consider adjusting instance sizes based on your usage patterns
- Monitor costs through LiteLLM's built-in usage tracking

## Cleanup

To remove LiteLLM resources:

```bash
# Delete Kubernetes resources
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f configmap.yaml
kubectl delete -f secret.yaml
kubectl delete -f serviceaccount.yaml
kubectl delete -f namespace.yaml

# Remove AWS infrastructure (from terraform directory)
cd ../terraform
terraform destroy -target=aws_elasticache_replication_group.litellm_redis
terraform destroy -target=aws_db_instance.litellm_postgres
terraform destroy -target=aws_secretsmanager_secret.litellm_master_salt
terraform destroy -target=aws_secretsmanager_secret.litellm_api_keys
```

## Completion

🎉 **Setup Complete!** You now have a fully functional EKS Auto Mode cluster with:

- **Infrastructure**: EKS cluster with Auto Mode features
- **OpenWebUI**: AI chat interface with S3 storage and PostgreSQL vector database
- **LiteLLM**: Multi-provider gateway with Redis caching and usage tracking

Your AI platform is ready for production workloads with enterprise-grade security, scalability, and cost optimization.

## Support

For issues and questions:
- Check the [LiteLLM documentation](https://docs.litellm.ai/)
- Review logs using the troubleshooting steps above
- Ensure all prerequisites are met
- Verify the sequential setup flow was followed
