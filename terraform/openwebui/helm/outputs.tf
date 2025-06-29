output "load_balancer_hostname" {
  description = "The raw hostname of the AWS Network Load Balancer."
  value       = data.external.load_balancer_info.result.hostname
}

output "openwebui_access_url" {
  description = "The full URL to access the OpenWebUI application."
  value       = "http://${data.external.load_balancer_info.result.hostname}"
}