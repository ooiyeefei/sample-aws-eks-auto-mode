resource "null_resource" "create_nodepools_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/../nodepools"
  }
}

resource "local_file" "setup_graviton" {
  content = templatefile("${path.module}/../nodepool-templates/graviton-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../nodepools/graviton-nodepool.yaml"
}

resource "local_file" "setup_spot" {
  content = templatefile("${path.module}/../nodepool-templates/spot-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../nodepools/spot-nodepool.yaml"
}

resource "local_file" "setup_gpu" {
  content = templatefile("${path.module}/../nodepool-templates/gpu-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../nodepools/gpu-nodepool.yaml"
}

resource "local_file" "setup_neuron" {
  content = templatefile("${path.module}/../nodepool-templates/neuron-nodepool.yaml.tpl", {
    node_iam_role_name  = module.eks.node_iam_role_name
    cluster_name = module.eks.cluster_name
  })
  filename = "${path.module}/../nodepools/neuron-nodepool.yaml"
}

resource "local_file" "setup_openwebui_values" {
  content = templatefile("${path.module}/../setup-openwebui/templates/values.yaml.tpl", {
    s3_bucket_name = aws_s3_bucket.openwebui_docs.id
    region         = var.region
    rds_endpoint   = aws_db_instance.postgres.endpoint
  })
  filename = "${path.module}/../setup-openwebui/values.yaml"
}

resource "local_file" "setup_openwebui_secret" {
  content = templatefile("${path.module}/../setup-openwebui/templates/secret.yaml.tpl", {
    secret_name    = aws_secretsmanager_secret.db_connection_string.name
  })
  filename = "${path.module}/../setup-openwebui/secret.yaml"
}

resource "local_file" "setup_pgvector_job" {
  content = templatefile("${path.module}/../setup-openwebui/templates/pgvector-job.yaml.tpl", {})
  filename = "${path.module}/../setup-openwebui/pgvector-job.yaml"
}

resource "local_file" "setup_cluster_secret_store" {
  content = templatefile("${path.module}/../setup-openwebui/templates/cluster-secret-store.yaml.tpl", {
    region = var.region
  })
  filename = "${path.module}/../setup-openwebui/cluster-secret-store.yaml"
}

# LiteLLM template generation
resource "local_file" "setup_litellm_config" {
  content = templatefile("${path.module}/../setup-litellm/templates/config.yaml.tpl", {
    vllm_service_url = "http://vllm-service.vllm-inference.svc.cluster.local"
    redis_host = aws_elasticache_replication_group.litellm_redis.primary_endpoint_address
    redis_port = aws_elasticache_replication_group.litellm_redis.port
    redis_password = random_password.litellm_redis_password.result
    litellm_master_key = local.litellm_master_key
    database_url = "postgresql://llmproxy:${random_password.litellm_db_password.result}@${aws_db_instance.litellm_postgres.address}:${aws_db_instance.litellm_postgres.port}/litellm"
    litellm_salt_key = local.litellm_salt_key
  })
  filename = "${path.module}/../setup-litellm/config.yaml"
}

resource "local_file" "setup_litellm_configmap" {
  content = templatefile("${path.module}/../setup-litellm/templates/configmap.yaml.tpl", {
    vllm_service_url = "http://vllm-service.vllm-inference.svc.cluster.local"
    redis_host = aws_elasticache_replication_group.litellm_redis.primary_endpoint_address
    redis_port = aws_elasticache_replication_group.litellm_redis.port
    redis_password = random_password.litellm_redis_password.result
    litellm_master_key = local.litellm_master_key
    database_url = "postgresql://llmproxy:${random_password.litellm_db_password.result}@${aws_db_instance.litellm_postgres.address}:${aws_db_instance.litellm_postgres.port}/litellm"
    litellm_salt_key = local.litellm_salt_key
  })
  filename = "${path.module}/../setup-litellm/configmap.yaml"
}

resource "local_file" "setup_litellm_deployment" {
  content = templatefile("${path.module}/../setup-litellm/templates/deployment.yaml.tpl", {})
  filename = "${path.module}/../setup-litellm/deployment.yaml"
}

resource "local_file" "setup_litellm_secret" {
  content = templatefile("${path.module}/../setup-litellm/templates/secret.yaml.tpl", {
    litellm_master_salt_secret_name = aws_secretsmanager_secret.litellm_master_salt.name
    litellm_db_connection_secret_name = aws_secretsmanager_secret.litellm_db_connection_string.name
    litellm_api_keys_secret_name = aws_secretsmanager_secret.litellm_api_keys.name
  })
  filename = "${path.module}/../setup-litellm/secret.yaml"
}

resource "local_file" "setup_litellm_serviceaccount" {
  content = templatefile("${path.module}/../setup-litellm/templates/serviceaccount.yaml.tpl", {
    litellm_pod_identity_role_arn = module.litellm_pod_identity.iam_role_arn
  })
  filename = "${path.module}/../setup-litellm/serviceaccount.yaml"
}
