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
  
  # OAuth configuration from ConfigMap (non-sensitive)
  - name: "ENABLE_OAUTH_SIGNUP"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-oauth-config"
        key: "ENABLE_OAUTH_SIGNUP"
  - name: "OAUTH_PROVIDER_NAME"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-oauth-config"
        key: "OAUTH_PROVIDER_NAME"
  - name: "OAUTH_SCOPES"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-oauth-config"
        key: "OAUTH_SCOPES"
  - name: "OAUTH_CLIENT_ID"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-oauth-config"
        key: "OAUTH_CLIENT_ID"
  - name: "MICROSOFT_CLIENT_ID"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-oauth-config"
        key: "MICROSOFT_CLIENT_ID"
  - name: "MICROSOFT_CLIENT_TENANT_ID"
    valueFrom:
      configMapKeyRef:
        name: "openwebui-oauth-config"
        key: "MICROSOFT_CLIENT_TENANT_ID"
  
  # OAuth configuration from Secrets Manager (sensitive)
  - name: "MICROSOFT_CLIENT_SECRET"
    valueFrom:
      secretKeyRef:
        name: "openwebui-oauth-credentials"
        key: "MICROSOFT_CLIENT_SECRET"
  - name: "OAUTH_CLIENT_SECRET"
    valueFrom:
      secretKeyRef:
        name: "openwebui-oauth-credentials"
        key: "OAUTH_CLIENT_SECRET"
  - name: "OPENID_PROVIDER_URL"
    valueFrom:
      secretKeyRef:
        name: "openwebui-oauth-credentials"
        key: "OPENID_PROVIDER_URL"
  
  # Apache Tika configuration for document processing
  - name: "TIKA_SERVER_URL"
    value: "http://tika.vllm-inference.svc.cluster.local:9998"
  

openaiBaseApiUrls: ["http://vllm-service/v1"]

# Custom asset volume mounts (mirrors VM volume mount approach)
extraVolumes:
  - name: favicon-assets
    configMap:
      name: openwebui-favicon
  - name: splash-assets
    configMap:
      name: openwebui-splash

extraVolumeMounts:
  # Favicon mounts
  - name: favicon-assets
    mountPath: /app/build/static/favicon.png
    subPath: favicon.png
  - name: favicon-assets
    mountPath: /app/build/favicon.png
    subPath: favicon.png
  # Splash image mounts
  - name: splash-assets
    mountPath: /app/build/static/splash.png
    subPath: splash.png
  - name: splash-assets
    mountPath: /app/build/static/splash-dark.png
    subPath: splash-dark.png

# Disable the embedded Ollama chart
ollama:
  enabled: false
