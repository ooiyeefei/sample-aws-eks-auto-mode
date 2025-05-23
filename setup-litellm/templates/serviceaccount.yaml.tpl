apiVersion: v1
kind: ServiceAccount
metadata:
  name: litellm-sa
  namespace: litellm
  annotations:
    eks.amazonaws.com/role-arn: "${litellm_pod_identity_role_arn}"
