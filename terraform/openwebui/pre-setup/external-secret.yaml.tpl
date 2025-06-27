apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: openwebui-db-credentials
  namespace: ${namespace}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets
    kind: ClusterSecretStore
  target:
    name: openwebui-db-credentials
    creationPolicy: Owner
  data:
    - secretKey: url
      remoteRef:
        key: ${db_secret_name}
        property: connectionString
    - secretKey: dbname
      remoteRef:
        key: ${db_secret_name}
        property: dbname
    - secretKey: host
      remoteRef:
        key: ${db_secret_name}
        property: host
    - secretKey: password
      remoteRef:
        key: ${db_secret_name}
        property: password
    - secretKey: port
      remoteRef:
        key: ${db_secret_name}
        property: port
    - secretKey: username
      remoteRef:
        key: ${db_secret_name}
        property: username 