# Multi-Tenant OpenWebUI Setup Guide

> **🏢 Enterprise Multi-Tenant Deployment**: Complete guide for deploying multiple OpenWebUI instances for different departments, teams, or use cases.

## Table of Contents
- [Overview](#overview)
- [Architecture Considerations](#architecture-considerations)
- [Prerequisites](#prerequisites)
- [Planning Your Multi-Tenant Setup](#planning-your-multi-tenant-setup)
- [Step-by-Step Implementation](#step-by-step-implementation)
- [Configuration Templates](#configuration-templates)
- [Terraform Infrastructure Updates](#terraform-infrastructure-updates)
- [Deployment Process](#deployment-process)
- [Management & Maintenance](#management--maintenance)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

This guide explains how to deploy multiple OpenWebUI instances using the base setup as a template. Each instance can serve different departments, teams, or use cases while sharing common infrastructure components.

### Common Use Cases

- **Department Isolation**: HR, Finance, Engineering, Marketing
- **Environment Separation**: Development, Staging, Production
- **Project-Based**: Different projects with isolated data
- **Client Separation**: Multi-client SaaS deployments
- **Compliance Requirements**: Data segregation for regulatory needs

### Benefits

✅ **Data Isolation**: Each tenant has separate data storage and processing
✅ **Access Control**: Independent authentication and authorization
✅ **Customization**: Different configurations, branding, and features per tenant
✅ **Scalability**: Easy to add new tenants without affecting existing ones
✅ **Cost Efficiency**: Shared infrastructure where appropriate
✅ **Maintenance**: Centralized management with tenant flexibility

## Architecture Considerations

### Resource Sharing Strategy

| Component | Shared | Isolated | Notes |
|-----------|--------|----------|-------|
| **EKS Cluster** | ✅ | | Single cluster for all tenants |
| **Namespace** | | ✅ | Each tenant gets own namespace |
| **Database** | | ✅ | Separate PostgreSQL database per tenant |
| **S3 Storage** | ✅ | | Shared bucket with tenant prefixes |
| **Load Balancer** | | ✅ | Separate NLB per tenant |
| **Apache Tika** | ✅ | | Shared document processing service |
| **Secrets Manager** | | ✅ | Separate secrets per tenant |
| **OAuth Config** | | ✅ | Independent SSO per tenant |

### Database Strategy Options

#### Option 1: Separate Databases (Recommended)
```
RDS Instance 1: vectordb_default
RDS Instance 2: vectordb_hr  
RDS Instance 3: vectordb_finance
```
**Pros**: Complete isolation, independent scaling, better security
**Cons**: Higher cost, more management overhead

#### Option 2: Shared Database with Schema Separation
```
Single RDS Instance: vectordb
Schemas: public, hr_schema, finance_schema
```
**Pros**: Lower cost, easier management
**Cons**: Less isolation, potential performance impact

### S3 Storage Organization

```
openwebui-documents-bucket/
├── default/
│   ├── uploads/
│   └── processed/
├── hr/
│   ├── uploads/
│   └── processed/
└── finance/
    ├── uploads/
    └── processed/
```

## Prerequisites

Before setting up multiple OpenWebUI instances:

1. ✅ **Base Infrastructure**: Main Terraform deployment completed
2. ✅ **Base OpenWebUI**: Default instance working correctly
3. ✅ **Custom Image**: GAR GPT branded image built and available
4. ✅ **Planning**: Tenant names and requirements defined
5. ✅ **Resources**: Sufficient cluster capacity for additional instances

## Planning Your Multi-Tenant Setup

### 1. Define Your Tenants

Create a planning document with your tenant requirements:

```yaml
tenants:
  hr:
    name: "Human Resources"
    namespace: "vllm-inference-hr"
    database: "vectordb_hr"
    s3_prefix: "hr/"
    oauth_provider: "Microsoft Azure AD"
    load_balancer: "hr-openwebui.company.com"
    
  finance:
    name: "Finance Department"
    namespace: "vllm-inference-finance"
    database: "vectordb_finance"
    s3_prefix: "finance/"
    oauth_provider: "Microsoft Azure AD"
    load_balancer: "finance-openwebui.company.com"
```

### 2. Resource Planning

Calculate resource requirements per tenant:

| Resource | Per Tenant | Notes |
|----------|------------|-------|
| **CPU** | 2-4 cores | OpenWebUI + overhead |
| **Memory** | 4-8 GB | Depends on usage patterns |
| **Storage** | 20-100 GB | EBS volumes for temp data |
| **Database** | 2-4 vCPU, 8-16 GB RAM | RDS instance sizing |
| **Network** | 1 NLB | External access |

### 3. Naming Conventions

Establish consistent naming patterns:

```bash
# Kubernetes Resources
Namespace: vllm-inference-{tenant}
Service: open-webui-{tenant}-service
Secret: openwebui-{tenant}-db-credentials
ConfigMap: openwebui-{tenant}-oauth-config

# AWS Resources
Database: vectordb_{tenant}
Secret: automode-cluster-{tenant}-postgres-credentials
Load Balancer: {tenant}-openwebui-nlb

# S3 Prefixes
Documents: {tenant}/uploads/
Processed: {tenant}/processed/
```

## Step-by-Step Implementation

### Step 1: Prepare Tenant Directory

Create a new directory for your tenant configuration:

```bash
# From the setup-openwebui directory
mkdir -p tenants/hr
cd tenants/hr
```

### Step 2: Copy Base Configuration Files

Copy the base configuration files to your tenant directory:

```bash
# Copy all necessary files from the base setup
cp ../../namespace.yaml ./namespace-hr.yaml
cp ../../templates/secret.yaml.tpl ./secret-hr.yaml.tpl
cp ../../oauth-config.yaml ./oauth-config-hr.yaml
cp ../../templates/oauth-secret.yaml.tpl ./oauth-secret-hr.yaml.tpl
cp ../../templates/pgvector-job.yaml.tpl ./pgvector-job-hr.yaml.tpl
cp ../../templates/values.yaml.tpl ./values-hr.yaml.tpl
cp ../../lb.yaml ./lb-hr.yaml
cp ../../tika-values.yaml ./tika-values-hr.yaml
```

### Step 3: Modify Configuration Files

#### 3.1 Update Namespace Configuration

Edit `namespace-hr.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: vllm-inference-hr
```

#### 3.2 Update Database Secret Configuration

Edit `secret-hr.yaml.tpl`:
```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: postgres-external-secret-hr
  namespace: vllm-inference-hr
spec:
  refreshInterval: "15m"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: openwebui-hr-db-credentials
    creationPolicy: Owner
  data:
  - secretKey: url
    remoteRef:
      key: "${secret_name_hr}"
      property: connectionString
```

#### 3.3 Update OAuth Configuration

Edit `oauth-config-hr.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: openwebui-hr-oauth-config
  namespace: vllm-inference-hr
data:
  ENABLE_OAUTH_SIGNUP: "true"
  OAUTH_PROVIDER_NAME: "HR Portal (SSO)"
  OAUTH_SCOPES: "openid email profile"
  OAUTH_CLIENT_ID: "hr-openwebui"
  MICROSOFT_CLIENT_ID: "your-hr-microsoft-client-id"
  MICROSOFT_CLIENT_TENANT_ID: "your-microsoft-tenant-id"
```

Edit `oauth-secret-hr.yaml.tpl`:
```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: oauth-external-secret-hr
  namespace: vllm-inference-hr
spec:
  refreshInterval: "15m"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: openwebui-hr-oauth-credentials
    creationPolicy: Owner
  data:
  - secretKey: MICROSOFT_CLIENT_SECRET
    remoteRef:
      key: "${oauth_secret_name_hr}"
      property: MICROSOFT_CLIENT_SECRET
  - secretKey: OAUTH_CLIENT_SECRET
    remoteRef:
      key: "${oauth_secret_name_hr}"
      property: OAUTH_CLIENT_SECRET
  - secretKey: OPENID_PROVIDER_URL
    remoteRef:
      key: "${oauth_secret_name_hr}"
      property: OPENID_PROVIDER_URL
```

#### 3.4 Update pgvector Job Configuration

Edit `pgvector-job-hr.yaml.tpl`:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pgvector-setup-hr
  namespace: vllm-inference-hr
spec:
  ttlSecondsAfterFinished: 100
  template:
    spec:
      containers:
      - name: pgvector-setup-hr
        image: postgres:15
        env:
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: openwebui-hr-db-credentials
              key: url
        command:
        - /bin/bash
        - -c
        - |
          # Same script as base, but with HR-specific logging
          set -e
          echo "=== [$(date)] STARTING PGVECTOR SETUP FOR HR ==="
          # ... rest of the script remains the same
      restartPolicy: Never
  backoffLimit: 4
```

#### 3.5 Update OpenWebUI Values Configuration

Edit `values-hr.yaml.tpl`:
```yaml
# Open WebUI Helm Chart Values - HR Department

image:
  repository: public.ecr.aws/v2f5y6u4/openwebui/custom-build
  tag: v0.1.0
  pullPolicy: IfNotPresent

# Configure persistence to use S3 with HR prefix
persistence:
  enabled: true
  provider: "s3"
  s3:
    bucket: "${s3_bucket_name}"
    region: "${region}"
    endpointUrl: "https://s3.${region}.amazonaws.com"
    prefix: "hr/"  # HR-specific prefix

# Configure service account for Pod Identity
serviceAccount:
  enable: true
  name: "open-webui-hr-pia"

# Configure environment variables
extraEnvVars:
  # Database configuration for PostgreSQL with pg_vector
  - name: "DATABASE_URL"
    valueFrom:
      secretKeyRef:
        name: "openwebui-hr-db-credentials"
        key: "url"
  - name: "VECTOR_DB"
    value: "pgvector"
  
  # OAuth configuration from ConfigMap (non-sensitive)
  - name: "ENABLE_OAUTH_SIGNUP"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-hr-oauth-config"
        key: "ENABLE_OAUTH_SIGNUP"
  - name: "OAUTH_PROVIDER_NAME"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-hr-oauth-config"
        key: "OAUTH_PROVIDER_NAME"
  - name: "OAUTH_SCOPES"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-hr-oauth-config"
        key: "OAUTH_SCOPES"
  - name: "OAUTH_CLIENT_ID"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-hr-oauth-config"
        key: "OAUTH_CLIENT_ID"
  - name: "MICROSOFT_CLIENT_ID"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-hr-oauth-config"
        key: "MICROSOFT_CLIENT_ID"
  - name: "MICROSOFT_CLIENT_TENANT_ID"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-hr-oauth-config"
        key: "MICROSOFT_CLIENT_TENANT_ID"
  
  # OAuth configuration from Secrets Manager (sensitive)
  - name: "MICROSOFT_CLIENT_SECRET"
    valueFrom:
      secretKeyRef:
        name: "openwebui-hr-oauth-credentials"
        key: "MICROSOFT_CLIENT_SECRET"
  - name: "OAUTH_CLIENT_SECRET"
    valueFrom:
      secretKeyRef:
        name: "openwebui-hr-oauth-credentials"
        key: "OAUTH_CLIENT_SECRET"
  - name: "OPENID_PROVIDER_URL"
    valueFrom:
      secretKeyRef:
        name: "openwebui-hr-oauth-credentials"
        key: "OPENID_PROVIDER_URL"
  
  # Apache Tika configuration (shared service)
  - name: "TIKA_SERVER_URL"
    value: "http://tika.vllm-inference.svc.cluster.local:9998"

# Use shared vLLM service if available
openaiBaseApiUrls: ["http://vllm-service.vllm-inference.svc.cluster.local/v1"]

# Disable the embedded Ollama chart
ollama:
  enabled: false
```

#### 3.6 Update Load Balancer Configuration

Edit `lb-hr.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: open-webui-hr-service
  namespace: vllm-inference-hr
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
spec:
  selector:
    app.kubernetes.io/component: open-webui
  type: LoadBalancer
  loadBalancerClass: eks.amazonaws.com/nlb
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

## Configuration Templates

### Template Generation Script

Create a script to generate tenant configurations automatically:

```bash
#!/bin/bash
# generate-tenant.sh

TENANT_NAME=$1
TENANT_DISPLAY_NAME=$2

if [ -z "$TENANT_NAME" ] || [ -z "$TENANT_DISPLAY_NAME" ]; then
    echo "Usage: $0 <tenant_name> <tenant_display_name>"
    echo "Example: $0 hr 'Human Resources'"
    exit 1
fi

echo "Generating configuration for tenant: $TENANT_NAME"

# Create tenant directory
mkdir -p "tenants/$TENANT_NAME"
cd "tenants/$TENANT_NAME"

# Generate namespace
cat > "namespace-$TENANT_NAME.yaml" << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: vllm-inference-$TENANT_NAME
EOF

# Generate secret template
cat > "secret-$TENANT_NAME.yaml.tpl" << EOF
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: postgres-external-secret-$TENANT_NAME
  namespace: vllm-inference-$TENANT_NAME
spec:
  refreshInterval: "15m"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: openwebui-$TENANT_NAME-db-credentials
    creationPolicy: Owner
  data:
  - secretKey: url
    remoteRef:
      key: "\${secret_name_$TENANT_NAME}"
      property: connectionString
EOF

# Generate OAuth config
cat > "oauth-config-$TENANT_NAME.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: openwebui-$TENANT_NAME-oauth-config
  namespace: vllm-inference-$TENANT_NAME
data:
  ENABLE_OAUTH_SIGNUP: "true"
  OAUTH_PROVIDER_NAME: "$TENANT_DISPLAY_NAME (SSO)"
  OAUTH_SCOPES: "openid email profile"
  OAUTH_CLIENT_ID: "$TENANT_NAME-openwebui"
  MICROSOFT_CLIENT_ID: "your-$TENANT_NAME-microsoft-client-id"
  MICROSOFT_CLIENT_TENANT_ID: "your-microsoft-tenant-id"
EOF

# Generate load balancer
cat > "lb-$TENANT_NAME.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: open-webui-$TENANT_NAME-service
  namespace: vllm-inference-$TENANT_NAME
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
spec:
  selector:
    app.kubernetes.io/component: open-webui
  type: LoadBalancer
  loadBalancerClass: eks.amazonaws.com/nlb
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
EOF

echo "✅ Configuration files generated for $TENANT_NAME in tenants/$TENANT_NAME/"
echo ""
echo "Next steps:"
echo "1. Review and customize the generated files"
echo "2. Update Terraform configuration for $TENANT_NAME"
echo "3. Apply Terraform changes"
echo "4. Deploy the tenant using the deployment script"
```

Make the script executable:
```bash
chmod +x generate-tenant.sh
```

Usage:
```bash
./generate-tenant.sh hr "Human Resources"
./generate-tenant.sh finance "Finance Department"
```

## Terraform Infrastructure Updates

### Database Resources

Add to your Terraform configuration:

```hcl
# Additional RDS instances for tenants
resource "aws_db_instance" "postgres_hr" {
  identifier = "automode-cluster-postgres-hr"
  
  engine         = "postgres"
  engine_version = "15.8"
  instance_class = "db.t3.medium"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "vectordb"
  username = "postgres"
  password = random_password.postgres_password_hr.result
  
  vpc_security_group_ids = [aws_security_group.postgres.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    Name        = "automode-cluster-postgres-hr"
    Environment = var.environment
    Tenant      = "hr"
  }
}

resource "random_password" "postgres_password_hr" {
  length  = 16
  special = true
}

# Secrets Manager for HR tenant
resource "aws_secretsmanager_secret" "postgres_credentials_hr" {
  name        = "automode-cluster-hr-postgres-credentials"
  description = "PostgreSQL credentials for HR OpenWebUI"
  
  tags = {
    Name        = "automode-cluster-hr-postgres-credentials"
    Environment = var.environment
    Tenant      = "hr"
  }
}

resource "aws_secretsmanager_secret_version" "postgres_credentials_hr" {
  secret_id = aws_secretsmanager_secret.postgres_credentials_hr.id
  secret_string = jsonencode({
    username         = aws_db_instance.postgres_hr.username
    password         = aws_db_instance.postgres_hr.password
    engine           = "postgres"
    host             = aws_db_instance.postgres_hr.address
    port             = aws_db_instance.postgres_hr.port
    dbname           = aws_db_instance.postgres_hr.db_name
    connectionString = "postgresql://${aws_db_instance.postgres_hr.username}:${aws_db_instance.postgres_hr.password}@${aws_db_instance.postgres_hr.address}:${aws_db_instance.postgres_hr.port}/${aws_db_instance.postgres_hr.db_name}?sslmode=require"
  })
}

# OAuth secrets for HR tenant
resource "aws_secretsmanager_secret" "oauth_credentials_hr" {
  name        = "automode-cluster-hr-oauth-credentials"
  description = "OAuth credentials for HR OpenWebUI"
  
  tags = {
    Name        = "automode-cluster-hr-oauth-credentials"
    Environment = var.environment
    Tenant      = "hr"
  }
}

resource "aws_secretsmanager_secret_version" "oauth_credentials_hr" {
  secret_id = aws_secretsmanager_secret.oauth_credentials_hr.id
  secret_string = jsonencode({
    MICROSOFT_CLIENT_SECRET = "placeholder-update-manually"
    OAUTH_CLIENT_SECRET     = "placeholder-update-manually"
    OPENID_PROVIDER_URL     = "placeholder-update-manually"
  })
}

# Pod Identity for HR tenant
resource "aws_eks_pod_identity_association" "openwebui_hr" {
  cluster_name    = aws_eks_cluster.automode_cluster.name
  namespace       = "vllm-inference-hr"
  service_account = "open-webui-hr-pia"
  role_arn        = aws_iam_role.openwebui_pod_identity.arn
  
  tags = {
    Name        = "openwebui-hr-pod-identity"
    Environment = var.environment
    Tenant      = "hr"
  }
}
```

### S3 Bucket Policy Updates

Update your S3 bucket policy to support tenant prefixes:

```hcl
data "aws_iam_policy_document" "openwebui_s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.openwebui_documents.arn,
      "${aws_s3_bucket.openwebui_documents.arn}/*"
    ]
    
    # Allow access to tenant-specific prefixes
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [
        "default/*",
        "hr/*",
        "finance/*"
      ]
    }
  }
}
```

### Terraform Outputs

Add outputs for tenant resources:

```hcl
# HR tenant outputs
output "postgres_hr_endpoint" {
  description = "HR PostgreSQL endpoint"
  value       = aws_db_instance.postgres_hr.endpoint
}

output "postgres_hr_secret_arn" {
  description = "HR PostgreSQL secret ARN"
  value       = aws_secretsmanager_secret.postgres_credentials_hr.arn
}

output "oauth_hr_secret_arn" {
  description = "HR OAuth secret ARN"
  value       = aws_secretsmanager_secret.oauth_credentials_hr.arn
}
```

## Deployment Process

### Automated Deployment Script

Create a deployment script for tenants:

```bash
#!/bin/bash
# deploy-tenant.sh

TENANT_NAME=$1

if [ -z "$TENANT_NAME" ]; then
    echo "Usage: $0 <tenant_name>"
    echo "Example: $0 hr"
    exit 1
fi

echo "🚀 Deploying OpenWebUI for tenant: $TENANT_NAME"
echo "=============================================="

# Check if tenant configuration exists
if [ ! -d "tenants/$TENANT_NAME" ]; then
    echo "❌ Error: Tenant configuration not found at tenants/$TENANT_NAME"
    echo "Please run ./generate-tenant.sh first"
    exit 1
fi

cd "tenants/$TENANT_NAME"

# Step 1: Apply namespace
echo "📁 Creating namespace..."
kubectl apply -f "namespace-$TENANT_NAME.yaml"

# Step 2: Apply cluster secret store (shared)
echo "🔐 Configuring secret store..."
kubectl apply -f "../../templates/cluster-secret-store.yaml"

# Step 3: Process and apply templates
echo "📝 Processing configuration templates..."

# Get Terraform outputs
cd ../../../terraform
S3_BUCKET=$(terraform output -raw openwebui_s3_bucket)
REGION=$(terraform output -raw region)
SECRET_NAME=$(terraform output -raw "postgres_${TENANT_NAME}_secret_arn" | awk -F: '{print $7}' | awk -F- '{for(i=1;i<=NF-1;i++) printf "%s%s", $i, (i<NF-1?"-":"")}')
OAUTH_SECRET_NAME=$(terraform output -raw "oauth_${TENANT_NAME}_secret_arn" | awk -F: '{print $7}' | awk -F- '{for(i=1;i<=NF-1;i++) printf "%s%s", $i, (i<NF-1?"-":"")}')
cd - > /dev/null

# Process templates
sed "s/\${secret_name_$TENANT_NAME}/$SECRET_NAME/g" "secret-$TENANT_NAME.yaml.tpl" > "secret-$TENANT_NAME.yaml"
sed "s/\${oauth_secret_name_$TENANT_NAME}/$OAUTH_SECRET_NAME/g" "oauth-secret-$TENANT_NAME.yaml.tpl" > "oauth-secret-$TENANT_NAME.yaml"
sed -e "s/\${s3_bucket_name}/$S3_BUCKET/g" -e "s/\${region}/$REGION/g" "values-$TENANT_NAME.yaml.tpl" > "values-$TENANT_NAME.yaml"
sed -e "s/\${secret_name_$TENANT_NAME}/$SECRET_NAME/g" "pgvector-job-$TENANT_NAME.yaml.tpl" > "pgvector-job-$TENANT_NAME.yaml"

# Step 4: Apply secrets and config
echo "🔑 Applying secrets and configuration..."
kubectl apply -f "secret-$TENANT_NAME.yaml"
kubectl apply -f "oauth-config-$TENANT_NAME.yaml"
kubectl apply -f "oauth-secret-$TENANT_NAME.yaml"

# Step 5: Wait for secrets to sync
echo "⏳ Waiting for secrets to sync..."
sleep 30

# Step 6: Create pgvector extension
echo "🗄️ Setting up database..."
kubectl apply -f "pgvector-job-$TENANT_NAME.yaml"

# Wait for job completion
echo "⏳ Waiting for pgvector setup to complete..."
kubectl wait --for=condition=complete job/pgvector-setup-$TENANT_NAME -n vllm-inference-$TENANT_NAME --timeout=300s

# Step 7: Deploy OpenWebUI
echo "🌐 Deploying OpenWebUI..."
helm repo add open-webui https://helm.openwebui.com/
helm repo update
helm upgrade --install "open-webui-$TENANT_NAME" open-webui/open-webui -f "values-$TENANT_NAME.yaml" -n "vllm-inference-$TENANT_NAME"

# Step 8: Apply load balancer
echo "🔗 Setting up load balancer..."
kubectl apply -f "lb-$TENANT_NAME.yaml"

# Step 9: Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available deployment/open-webui-$TENANT_NAME -n vllm-inference-$TENANT_NAME --timeout=300s

# Step 10: Get access URL
echo "🎉 Deployment completed!"
echo ""
echo "Getting access URL..."
sleep 30
LB_URL=$(kubectl get service "open-webui-$TENANT_NAME-service" -n "vllm-inference-$TENANT_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -n "$LB_URL" ]; then
    echo "✅ $TENANT_NAME OpenWebUI is available at: http://$LB_URL"
else
    echo "⏳ Load balancer is still provisioning. Check status with:"
    echo "kubectl get service open-webui-$TENANT_NAME-service -n vllm-inference-$TENANT_NAME"
fi

echo ""
echo "📋 Verification commands:"
echo "kubectl get pods -n vllm-inference-$TENANT_NAME"
echo "kubectl get services -n vllm-inference-$TENANT_NAME"
echo "kubectl logs deployment/open-webui-$TENANT_NAME -n vllm-inference-$TENANT_NAME"
```

Make the script executable:
```bash
chmod +x deploy-tenant.sh
```

### Manual Deployment Steps

If you prefer manual deployment:

1. **Apply Infrastructure Changes**:
   ```bash
   cd terraform
   terraform plan
   terraform apply
   ```

2. **Deploy Tenant Configuration**:
   ```bash
   cd setup-openwebui/tenants/hr
   
   # Apply namespace
   kubectl apply -f namespace-hr.yaml
   
   # Apply secrets and config
   kubectl apply -f secret-hr.yaml
   kubectl apply -f oauth-config-hr.yaml
   kubectl apply -f oauth-secret-hr.yaml
   
   # Setup database
   kubectl apply -f pgvector-job-hr.yaml
   kubectl wait --for=condition=complete job/pgvector-setup-hr -n vllm-inference-hr --timeout=300s
   
   # Deploy OpenWebUI
   helm upgrade --install open-webui-hr open-webui/open-webui -f values-hr.yaml -n vllm-inference-hr
   
   # Apply load balancer
   kubectl apply -f lb-hr.yaml
   ```

3. **Verify Deployment**:
   ```bash
   kubectl get pods -n vllm-inference-hr
   kubectl get services -n vllm-inference-hr
   ```

## Management & Maintenance

### Monitoring Multiple Tenants

Create a monitoring script:

```bash
#!/bin/bash
# monitor-tenants.sh

TENANTS=("default" "hr" "finance")

echo "🔍 OpenWebUI Multi-Tenant Status"
echo "================================="

for tenant in "${TENANTS[@]}"; do
    if [ "$tenant" = "default" ]; then
        namespace="vllm-inference"
        deployment="open-webui"
        service="open-webui-service"
    else
        namespace="vllm-inference-$tenant"
        deployment="open-webui-$tenant"
        service="open-webui-$tenant-service"
    fi
    
    echo ""
    echo "📊 Tenant: $tenant"
    echo "-------------------"
    
    # Check namespace
    if kubectl get namespace "$namespace" >/dev/null 2>&1; then
        echo "✅ Namespace: $namespace"
    else
        echo "❌ Namespace: $namespace (not found)"
        continue
    fi
    
    # Check deployment
    replicas=$(kubectl get deployment "$deployment" -n "$namespace" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    if [ -n "$replicas" ] && [ "$replicas" -gt 0 ]; then
        echo "✅ Deployment: $deployment ($replicas replicas ready)"
    else
        echo "❌ Deployment: $deployment (not ready)"
    fi
    
    # Check service
    if kubectl get service "$service" -n "$namespace" >/dev/null 2>&1; then
        lb_url=$(kubectl get service "$service" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        if [ -n "$lb_url" ]; then
            echo "✅ Service: $service (http://$lb_url)"
        else
            echo "⏳ Service: $service (load balancer provisioning)"
        fi
    else
        echo "❌ Service: $service (not found)"
    fi
done

echo ""
echo "📋 Quick Commands:"
echo "kubectl get pods --all-namespaces | grep vllm-inference"
echo "kubectl get services --all-namespaces | grep open-webui"
```

Make the script executable:
```bash
chmod +x monitor-tenants.sh
```

### Updating All Tenants

Create an update script for rolling out changes to all tenants:

```bash
#!/bin/bash
# update-all-tenants.sh

TENANTS=("default" "hr" "finance")
ACTION=$1

if [ -z "$ACTION" ]; then
    echo "Usage: $0 <action>"
    echo "Actions:"
    echo "  restart    - Restart all OpenWebUI deployments"
    echo "  upgrade    - Upgrade all OpenWebUI deployments"
    echo "  status     - Show status of all deployments"
    exit 1
fi

case $ACTION in
    "restart")
        echo "🔄 Restarting all OpenWebUI deployments..."
        for tenant in "${TENANTS[@]}"; do
            if [ "$tenant" = "default" ]; then
                namespace="vllm-inference"
                deployment="open-webui"
            else
                namespace="vllm-inference-$tenant"
                deployment="open-webui-$tenant"
            fi
            
            echo "Restarting $tenant..."
            kubectl rollout restart deployment/$deployment -n $namespace
        done
        ;;
    
    "upgrade")
        echo "⬆️ Upgrading all OpenWebUI deployments..."
        helm repo update
        for tenant in "${TENANTS[@]}"; do
            if [ "$tenant" = "default" ]; then
                namespace="vllm-inference"
                release="open-webui"
                values="values.yaml"
            else
                namespace="vllm-inference-$tenant"
                release="open-webui-$tenant"
                values="tenants/$tenant/values-$tenant.yaml"
            fi
            
            echo "Upgrading $tenant..."
            helm upgrade $release open-webui/open-webui -f $values -n $namespace
        done
        ;;
    
    "status")
        ./monitor-tenants.sh
        ;;
    
    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
```

### Backup Strategy

Create a backup script for tenant data:

```bash
#!/bin/bash
# backup-tenant-data.sh

TENANT_NAME=$1
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)

if [ -z "$TENANT_NAME" ]; then
    echo "Usage: $0 <tenant_name>"
    echo "Example: $0 hr"
    exit 1
fi

echo "📦 Backing up data for tenant: $TENANT_NAME"
echo "============================================"

# Get database connection details
if [ "$TENANT_NAME" = "default" ]; then
    namespace="vllm-inference"
    secret="openwebui-db-credentials"
else
    namespace="vllm-inference-$TENANT_NAME"
    secret="openwebui-$TENANT_NAME-db-credentials"
fi

# Create backup directory
mkdir -p "backups/$TENANT_NAME/$BACKUP_DATE"

# Backup database
echo "🗄️ Backing up database..."
DB_URL=$(kubectl get secret $secret -n $namespace -o jsonpath='{.data.url}' | base64 -d)
kubectl run pg-dump-$TENANT_NAME --rm -i --restart=Never --image=postgres:15 --env="DB_URL=$DB_URL" -- pg_dump "$DB_URL" > "backups/$TENANT_NAME/$BACKUP_DATE/database.sql"

# Backup S3 data
echo "📁 Backing up S3 documents..."
cd ../terraform
S3_BUCKET=$(terraform output -raw openwebui_s3_bucket)
cd - > /dev/null

if [ "$TENANT_NAME" = "default" ]; then
    aws s3 sync "s3://$S3_BUCKET/default/" "backups/$TENANT_NAME/$BACKUP_DATE/s3/"
else
    aws s3 sync "s3://$S3_BUCKET/$TENANT_NAME/" "backups/$TENANT_NAME/$BACKUP_DATE/s3/"
fi

# Backup Kubernetes configurations
echo "⚙️ Backing up Kubernetes configurations..."
kubectl get all -n $namespace -o yaml > "backups/$TENANT_NAME/$BACKUP_DATE/kubernetes.yaml"
kubectl get secrets -n $namespace -o yaml > "backups/$TENANT_NAME/$BACKUP_DATE/secrets.yaml"
kubectl get configmaps -n $namespace -o yaml > "backups/$TENANT_NAME/$BACKUP_DATE/configmaps.yaml"

echo "✅ Backup completed: backups/$TENANT_NAME/$BACKUP_DATE/"
echo "📋 Backup contents:"
ls -la "backups/$TENANT_NAME/$BACKUP_DATE/"
```

## Best Practices

### Security Considerations

1. **Network Isolation**:
   ```yaml
   # Enable network policies for tenant isolation
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: tenant-isolation
     namespace: vllm-inference-hr
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: vllm-inference-hr
   ```

2. **Resource Quotas**:
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: tenant-quota
     namespace: vllm-inference-hr
   spec:
     hard:
       requests.cpu: "4"
       requests.memory: 8Gi
       limits.cpu: "8"
       limits.memory: 16Gi
       persistentvolumeclaims: "5"
   ```

3. **Pod Security Standards**:
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: vllm-inference-hr
     labels:
       pod-security.kubernetes.io/enforce: restricted
       pod-security.kubernetes.io/audit: restricted
       pod-security.kubernetes.io/warn: restricted
   ```

### Cost Optimization

1. **Right-sizing Resources**:
   - Monitor actual resource usage
   - Adjust CPU/memory requests and limits
   - Use Horizontal Pod Autoscaler (HPA)

2. **Database Optimization**:
   - Use appropriate RDS instance sizes
   - Enable automated backups with retention policies
   - Consider Aurora Serverless for variable workloads

3. **Storage Optimization**:
   - Implement S3 lifecycle policies
   - Use S3 Intelligent Tiering
   - Regular cleanup of unused documents

### Monitoring and Observability

1. **Prometheus Metrics**:
   ```yaml
   # Add to values.yaml for each tenant
   serviceMonitor:
     enabled: true
     labels:
       tenant: hr
   ```

2. **Logging Strategy**:
   ```yaml
   # Structured logging with tenant labels
   extraEnvVars:
     - name: "LOG_LEVEL"
       value: "INFO"
     - name: "TENANT_NAME"
       value: "hr"
   ```

3. **Health Checks**:
   ```yaml
   # Enhanced health checks
   livenessProbe:
     httpGet:
       path: /health
       port: 8080
     initialDelaySeconds: 30
     periodSeconds: 10
   
   readinessProbe:
     httpGet:
       path: /health
       port: 8080
     initialDelaySeconds: 5
     periodSeconds: 5
   ```

## Troubleshooting

### Common Issues

#### 1. Database Connection Issues

**Symptoms**: OpenWebUI pods failing to start, database connection errors

**Diagnosis**:
```bash
# Check secret exists and is populated
kubectl get secret openwebui-hr-db-credentials -n vllm-inference-hr -o yaml

# Check External Secrets sync status
kubectl describe externalsecret postgres-external-secret-hr -n vllm-inference-hr

# Test database connectivity
kubectl run db-test --rm -i --restart=Never --image=postgres:15 --env="DB_URL=$(kubectl get secret openwebui-hr-db-credentials -n vllm-inference-hr -o jsonpath='{.data.url}' | base64 -d)" -- psql "$DB_URL" -c "SELECT 1"
```

**Solutions**:
- Verify RDS instance is running and accessible
- Check security group rules
- Verify External Secrets Operator is running
- Check AWS Secrets Manager permissions

#### 2. S3 Access Issues

**Symptoms**: Document upload failures, S3 permission errors

**Diagnosis**:
```bash
# Check Pod Identity association
aws eks describe-pod-identity-association --cluster-name automode-cluster --association-id <association-id>

# Check IAM role permissions
aws iam get-role-policy --role-name openwebui-pod-identity-role --policy-name S3Access

# Test S3 access from pod
kubectl exec -it deployment/open-webui-hr -n vllm-inference-hr -- aws s3 ls s3://your-bucket/hr/
```

**Solutions**:
- Verify Pod Identity association exists
- Check IAM role has correct S3 permissions
- Verify S3 bucket policy allows tenant access

#### 3. Load Balancer Issues

**Symptoms**: Cannot access OpenWebUI externally, load balancer not provisioning

**Diagnosis**:
```bash
# Check service status
kubectl describe service open-webui-hr-service -n vllm-inference-hr

# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*nlb*"
```

**Solutions**:
- Verify AWS Load Balancer Controller is installed
- Check subnet tags for load balancer discovery
- Verify security group rules allow traffic

#### 4. OAuth/SSO Issues

**Symptoms**: Authentication failures, OAuth redirect errors

**Diagnosis**:
```bash
# Check OAuth configuration
kubectl get configmap openwebui-hr-oauth-config -n vllm-inference-hr -o yaml

# Check OAuth secrets
kubectl get secret openwebui-hr-oauth-credentials -n vllm-inference-hr -o yaml

# Check OpenWebUI logs
kubectl logs deployment/open-webui-hr -n vllm-inference-hr | grep -i oauth
```

**Solutions**:
- Verify OAuth provider configuration
- Check redirect URLs in OAuth application
- Verify client secrets are correct
- Check network connectivity to OAuth provider

### Debugging Commands

```bash
# Get all resources for a tenant
kubectl get all -n vllm-inference-hr

# Check pod logs
kubectl logs deployment/open-webui-hr -n vllm-inference-hr --tail=100

# Get pod events
kubectl get events -n vllm-inference-hr --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n vllm-inference-hr

# Describe problematic resources
kubectl describe pod <pod-name> -n vllm-inference-hr

# Check External Secrets status
kubectl get externalsecrets -A

# Check Helm release status
helm list -n vllm-inference-hr
helm status open-webui-hr -n vllm-inference-hr
```

### Performance Tuning

1. **Database Performance**:
   ```sql
   -- Monitor database performance
   SELECT * FROM pg_stat_activity WHERE state = 'active';
   
   -- Check slow queries
   SELECT query, mean_exec_time, calls 
   FROM pg_stat_statements 
   ORDER BY mean_exec_time DESC 
   LIMIT 10;
   ```

2. **Application Performance**:
   ```yaml
   # Tune OpenWebUI resources
   resources:
     requests:
       cpu: "1"
       memory: "2Gi"
     limits:
       cpu: "2"
       memory: "4Gi"
   ```

3. **Storage Performance**:
   ```yaml
   # Use faster storage class
   storageClass: gp3
   ```

---

## Summary

This guide provides a comprehensive approach to deploying multiple OpenWebUI instances using a template-based methodology. Key benefits include:

✅ **Scalable Architecture**: Easy to add new tenants
✅ **Data Isolation**: Separate databases and S3 prefixes
✅ **Security**: Independent authentication and authorization
✅ **Automation**: Scripts for generation and deployment
✅ **Monitoring**: Comprehensive observability
✅ **Maintenance**: Centralized management capabilities

For additional support or questions about multi-tenant deployments, refer to the main OpenWebUI documentation or create an issue in the project repository.

**Next Steps**: After setting up multiple tenants, consider implementing centralized monitoring, automated backups, and disaster recovery procedures for a complete enterprise solution.
