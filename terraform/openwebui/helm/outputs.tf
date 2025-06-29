output "load_balancer_hostname" {
  description = "The raw hostname of the AWS Network Load Balancer."
  value       = data.kubernetes_ingress_v1.openwebui_lb.status.0.load_balancer.0.ingress.0.hostname
}

output "openwebui_access_url" {
  description = "The full URL to access the OpenWebUI application."
  value       = "http://${data.kubernetes_ingress_v1.openwebui_lb.status.0.load_balancer.0.ingress.0.hostname}"
}