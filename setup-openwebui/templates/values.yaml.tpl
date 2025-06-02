# Open WebUI Helm Chart Values - GAR GPT Custom Image

# Use custom GAR GPT branded image
image:
  repository: public.ecr.aws/v2f5y6u4/openwebui/custom-build
  tag: v0.0.1
  pullPolicy: IfNotPresent

# Configure persistence to use S3
persistence:
  enabled: true
  provider: "s3"
  s3:
    bucket: "${s3_bucket_name}"
    region: "${region}"
    endpointUrl: "https://s3.${region}.amazonaws.com"

# Configure service account for Pod Identity
serviceAccount:
  enable: true
  name: "open-webui-pia"  # Must match the service_account in the Pod Identity association

# Configure environment variables
extraEnvVars:
  # Database configuration for PostgreSQL with pg_vector
  - name: "DATABASE_URL"
    valueFrom:
      secretKeyRef:
        name: "openwebui-db-credentials"
        key: "url"
  - name: "VECTOR_DB"
    value: "pgvector"
  

openaiBaseApiUrls: ["http://vllm-service/v1"]

# Disable the embedded Ollama chart
ollama:
  enabled: false
