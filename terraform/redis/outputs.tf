output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.litellm_redis.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.litellm_redis.port
}

output "redis_password" {
  description = "Redis password"
  value       = random_password.litellm_redis_password.result
  sensitive   = true
}

output "redis_replication_group_id" {
  description = "Redis replication group ID"
  value       = aws_elasticache_replication_group.litellm_redis.id
} 