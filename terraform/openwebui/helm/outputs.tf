output "load_balancer_hostname" {
  description = "The raw hostname of the AWS Network Load Balancer."
  value       = data.local_file.load_balancer_hostname.content
}

output "openwebui_access_url" {
  description = "The full URL to access the OpenWebUI application."
  value       = "http://${data.local_file.load_balancer_hostname.content}"
}