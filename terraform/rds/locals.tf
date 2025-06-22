locals {
  private_subnets = var.private_subnets_json != "" ? jsondecode(var.private_subnets_json) : []
} 