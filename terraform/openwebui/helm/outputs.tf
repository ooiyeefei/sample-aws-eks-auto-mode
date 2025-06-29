output "load_balancer_hostname" {
  value = data.external.load_balancer_info.result.hostname
}
output "openwebui_access_url" {
  value = "http://${data.external.load_balancer_info.result.hostname}"
}