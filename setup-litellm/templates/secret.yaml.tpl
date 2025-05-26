apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: litellm-db-credentials
  namespace: litellm
spec:
  refreshInterval: "15m"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: litellm-db-credentials
    creationPolicy: Owner
  data:
  - secretKey: url
    remoteRef:
      key: "${litellm_db_connection_secret_name}"
      property: connectionString

---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: litellm-master-salt
  namespace: litellm
spec:
  refreshInterval: "15m"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: litellm-master-salt
    creationPolicy: Owner
  data:
  - secretKey: LITELLM_MASTER_KEY
    remoteRef:
      key: "${litellm_master_salt_secret_name}"
      property: LITELLM_MASTER_KEY
  - secretKey: LITELLM_SALT_KEY
    remoteRef:
      key: "${litellm_master_salt_secret_name}"
      property: LITELLM_SALT_KEY

---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: litellm-api-keys
  namespace: litellm
spec:
  refreshInterval: "15m"
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: litellm-api-keys
    creationPolicy: Owner
  # Use dataFrom to pull all key-value pairs from the secret
  dataFrom:
  - extract:
      key: "${litellm_api_keys_secret_name}"
