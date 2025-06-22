# Application Integration Module (IAM Policy Attachments)

resource "aws_iam_role_policy_attachment" "secrets_access_to_openwebui" {
  count = var.openwebui_pod_identity_role_name != "" ? 1 : 0

  role       = var.openwebui_pod_identity_role_name
  policy_arn = var.secrets_access_policy_arn
} 