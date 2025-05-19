# Open WebUI Helm Chart Values

# Configure persistence to use S3
persistence:
  enabled: true
  provider: "s3"
  s3:
    bucket: "${s3_bucket_name}"
    region: "${region}"

# Configure service account for Pod Identity
serviceAccount:
  enable: true
  name: "open-webui"  # Must match the service_account in the Pod Identity association

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
  
  # vLLM configuration
  - name: "OPENAI_API_BASE_URL"
    value: "http://vllm-service/v1"
  - name: "OPENAI_API_KEY"
    value: "not-needed"  # vLLM typically doesn't require an API key in internal deployments

# Disable the embedded Ollama chart
ollama:
  enabled: false
