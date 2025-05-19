

# Open WebUI Setup

## Prerequisites

Before deploying Open WebUI, ensure you have:
1. An EKS Auto Mode cluster running
2. The AWS CLI configured with appropriate credentials
3. kubectl configured to access your cluster

## Deployment Steps

### 1. Deploy Storage Class
```bash
kubectl apply -f sc.yaml
```

### 2. Apply Database Secret
```bash
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
```

### 3. Deploy Open WebUI with Helm

```bash
helm repo add open-webui https://helm.openwebui.com/
helm repo update
helm upgrade --install open-webui open-webui/open-webui -f values.yaml
```

### 4. OPTIONAL - Deploy LLM
```bash
kubectl apply -f ../nodepool/gpu-nodepool.yaml
kubectl apply -f llm.yaml
```

## Configuration

The deployment uses:
- S3 for document storage with Pod Identity
- PostgreSQL with pg_vector for vector embeddings storage
- vLLM service for LLM inference

## Accessing Open WebUI

After deployment, you can access Open WebUI at:
```bash
kubectl get svc open-webui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
