apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets
  namespace: ${namespace}
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${aws_region} 