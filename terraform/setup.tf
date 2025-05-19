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
  content = templatefile("${path.module}/../setup-openwebui/values.yaml.tpl", {
    s3_bucket_name = aws_s3_bucket.openwebui_docs.id
    region         = var.region
    rds_endpoint   = aws_db_instance.postgres.endpoint
  })
  filename = "${path.module}/../setup-openwebui/values.yaml"
}

resource "local_file" "setup_openwebui_secret" {
  content = templatefile("${path.module}/../setup-openwebui/secret.yaml.tpl", {
    rds_endpoint   = aws_db_instance.postgres.endpoint
  })
  filename = "${path.module}/../setup-openwebui/secret.yaml"
}
