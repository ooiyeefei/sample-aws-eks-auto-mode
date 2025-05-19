

# Open WebUI Setup

## Prerequisites

Before deploying Open WebUI, ensure you have:
1. An EKS Auto Mode cluster running
2. The AWS CLI configured with appropriate credentials
3. kubectl configured to access your cluster

## Deployment Steps

### 1. Deploy Storage Class
If in terraform folder:
```bash
cd ../setup-openwebui
```

```bash
kubectl apply -f sc.yaml
```

### 2. Apply Database Secret
```bash
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
```

### 3. Create the pgvector Extension
```bash
# Apply the pgvector setup job
kubectl apply -f pgvector-job.yaml
```

Takes about a minute

```bash
# Check the job status
kubectl get jobs -n vllm-inference

# View the job logs to verify success
kubectl logs job/pgvector-setup -n vllm-inference
```

This job will:
- Connect to the PostgreSQL database from within the EKS cluster
- Create the pgvector extension if it doesn't exist
- Verify that the extension was created successfully

The logs will clearly indicate whether the operation succeeded or failed. If successful, you'll see a message like:
```
=== [date] PGVECTOR EXTENSION CREATED SUCCESSFULLY ===
=== [date] VERIFICATION SUCCESSFUL ===
=== [date] PGVECTOR SETUP COMPLETED SUCCESSFULLY ===
```

### 4. Deploy Open WebUI with Helm

```bash
helm repo add open-webui https://helm.openwebui.com/
helm repo update
helm upgrade --install open-webui open-webui/open-webui -f values.yaml -n vllm-inference
```

### 4. OPTIONAL - Deploy LLM

Need hugging face token for this.
```bash
kubectl create secret generic hf-secret --from-literal=hf_api_token=<hugging-face-token> -n vllm-inference
kubectl apply -f ../nodepools/gpu-nodepool.yaml
kubectl apply -f llm.yaml
```

## Configuration Details

The OpenWebUI deployment is configured to use AWS services for storage and vector embeddings:

### S3 Document Storage

OpenWebUI stores all uploaded documents in an S3 bucket that was provisioned by the Terraform deployment. This provides:

- Scalable and durable storage for documents
- Cost-effective storage with lifecycle policies
- Secure access through AWS Pod Identity

The S3 configuration is defined in `values.yaml.tpl`:
```yaml
persistence:
  enabled: true
  provider: "s3"
  s3:
    bucket: "${s3_bucket_name}"
    region: "${region}"
```

**Pod Identity for S3 Access**

Instead of using AWS access keys, this deployment uses EKS Pod Identity for secure access to S3. The Terraform deployment:

1. Creates an IAM role with permissions to access the S3 bucket
2. Associates this role with the OpenWebUI service account
3. Configures the service account in the Helm chart:
   ```yaml
   serviceAccount:
     enable: true
     name: "open-webui"
   ```

This approach eliminates the need for managing AWS credentials and follows security best practices.

### PostgreSQL Vector Database

OpenWebUI uses the RDS PostgreSQL instance with pg_vector extension for storing and querying vector embeddings:

- Document embeddings are stored as vector data types
- Similarity searches use PostgreSQL's vector operators
- The database connection is configured through a Kubernetes secret

The PostgreSQL configuration is defined in the environment variables:
```yaml
extraEnvVars:
  - name: "DATABASE_URL"
    valueFrom:
      secretKeyRef:
        name: "openwebui-db-credentials"
        key: "url"
  - name: "VECTOR_DB"
    value: "pgvector"
```

The database connection string is stored in a Kubernetes secret (`openwebui-db-credentials`) that points to the RDS instance created by Terraform.

## Accessing Open WebUI

After deployment, you can access Open WebUI at:
```bash
export LOCAL_PORT=8080
export POD_NAME=$(kubectl get pods -n vllm-inference -l "app.kubernetes.io/component=open-webui" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod -n vllm-inference $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
echo "Visit http://127.0.0.1:$LOCAL_PORT to use your application"
kubectl -n vllm-inference port-forward $POD_NAME $LOCAL_PORT:$CONTAINER_PORT
```

## Verification Steps

After deploying OpenWebUI, follow these steps to verify that the S3 and PostgreSQL integrations are working correctly:

### Verify S3 Document Storage

1. **Upload a document in OpenWebUI**:
   - Access the OpenWebUI interface
   - Navigate to the document upload section
   - Upload a PDF or text document

2. **Verify the document is stored in S3**:
   ```bash
   # Get the S3 bucket name
   cd ../terraform
   S3_BUCKET=$(terraform output -raw openwebui_s3_bucket)
   
   # List objects in the bucket
   aws s3 ls s3://$S3_BUCKET/
   
   # You should see your uploaded document or a folder structure containing it
   ```

### Verify PostgreSQL Vector Embeddings

1. **Generate embeddings in OpenWebUI**:
   - After uploading a document, ensure it's processed for embeddings
   - This typically happens automatically when you upload a document

2. Setup an EC2 Instance and SSH in:
```bash
RDS_ENDPOINT=<Endpoint-from-terraform-output>
sudo dnf install postgresql15
psql -h $(echo $RDS_ENDPOINT | cut -d':' -f1) -p $(echo $RDS_ENDPOINT | cut -d':' -f2) -U postgres -d vectordb
\dx
\d document_chunk
```
![alt text](image.png)

![alt text](image-1.png)



If both verifications are successful, your OpenWebUI deployment is correctly using S3 for document storage and PostgreSQL for vector embeddings.
