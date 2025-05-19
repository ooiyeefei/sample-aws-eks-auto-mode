apiVersion: v1
kind: Secret
metadata:
  name: openwebui-db-credentials
  namespace: vllm-inference
type: Opaque
stringData:
  url: "postgresql://postgres:YourStrongPasswordHere@${rds_endpoint}/vectordb"
